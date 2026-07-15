import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_explorer_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';

/// Aggregates collection + storage repos for the explorer (no new Hive box).
class DatasetExplorerRepositoryImpl implements DatasetExplorerRepository {
  final DatasetCollectionRepository _collection;
  final DatasetStorageRepository _storage;
  final DatasetFileManager _files;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;

  /// Creates [DatasetExplorerRepositoryImpl].
  DatasetExplorerRepositoryImpl({
    required DatasetCollectionRepository collectionRepository,
    required DatasetStorageRepository storageRepository,
    required DatasetFileManager fileManager,
    required ErrorHandler errorHandler,
    required AppLogger logger,
  })  : _collection = collectionRepository,
        _storage = storageRepository,
        _files = fileManager,
        _errorHandler = errorHandler,
        _logger = logger;

  @override
  Future<Result<DatasetDashboardData>> loadDashboard({
    int recentLimit = 8,
  }) {
    return _guard(() async {
      final sessions = await _unwrap(_collection.getSessions());
      final stats = await _unwrap(_collection.getStatistics());
      final storage = await _unwrap(_collection.getStorageInformation());
      final disk = await _unwrap(_storage.calculateStorage());
      final active = await _unwrap(_collection.getActiveSession());

      final totalDuration = sessions.fold<Duration>(
        Duration.zero,
        (sum, s) => sum + s.duration,
      );
      final totalMinutes = totalDuration.inSeconds / 60.0;
      final fpm = totalMinutes <= 0
          ? 0.0
          : stats.totalFrames / totalMinutes;
      final avgFlood = sessions.isEmpty
          ? 0.0
          : sessions.fold<double>(0, (a, s) => a + s.averageFloodCoverage) /
              sessions.length;

      final recent = sessions.take(recentLimit).toList();
      _logger.info(
        'Dashboard Loaded sessions=${sessions.length}',
        tag: 'DatasetExplorer',
      );
      return DatasetDashboardData(
        statistics: stats,
        collectionStorage: storage,
        diskUsage: disk,
        recentSessions: recent,
        activeSession: active,
        totalRecordingTime: totalDuration,
        framesPerMinute: fpm,
        averageFloodCoverage: avgFlood,
      );
    });
  }

  @override
  Future<Result<List<DatasetSession>>> loadSessions() {
    return _guard(() async {
      final sessions = await _unwrap(_collection.getSessions());
      return sessions;
    });
  }

  @override
  Future<Result<SessionPage>> searchSessions(SessionQuery query) {
    return _guard(() async {
      final all = await _unwrap(_collection.getSessions());
      final filtered = _applyQuery(all, query);
      _logger.info(
        'Search q="${query.searchQuery}" matches=${filtered.length}',
        tag: 'DatasetExplorer',
      );
      return _paginate(filtered, query);
    });
  }

  @override
  Future<Result<SessionPage>> filterSessions(SessionQuery query) {
    _logger.info('Filter date=${query.dateFilter} status=${query.status}',
        tag: 'DatasetExplorer');
    return searchSessions(query);
  }

  @override
  Future<Result<SessionPage>> sortSessions(SessionQuery query) {
    _logger.info('Sort ${query.sort}', tag: 'DatasetExplorer');
    return searchSessions(query);
  }

  @override
  Future<Result<SessionDetails>> loadSessionDetails(String sessionId) {
    return _guard(() async {
      final session = await _unwrap(_collection.getSession(sessionId));
      _logger.info('Session Opened $sessionId', tag: 'DatasetExplorer');

      await _files.ensureRootLayout();
      final sessionPath = _files.paths.session(sessionId);
      var diskBytes = 0;
      var incomplete = false;
      if (await Directory(sessionPath).exists()) {
        diskBytes = await _files.directoryByteSize(sessionPath);
        final recovered = await _unwrap(
          _storage.recoverSession(sessionId: sessionId),
        );
        incomplete = recovered.any((r) => r.isIncomplete);
      }

      final previews = await _loadPreviewsInternal(sessionId, limit: 24);
      String? metaSummary;
      if (previews.isNotEmpty) {
        final last = previews.first.frameNumber;
        final metaResult = await _storage.loadMetadata(
          sessionId: sessionId,
          frameNumber: last,
        );
        metaResult.fold(
          onOk: (m) {
            metaSummary =
                'Frame #$last · ${m.inference.prediction} · '
                'conf=${m.inference.confidence.toStringAsFixed(2)} · '
                'GPS ${m.location.isAvailable ? 'ok' : 'missing'}';
          },
          onErr: (_) {},
        );
      }

      final minutes = session.duration.inSeconds / 60.0;
      final rate = minutes <= 0 ? 0.0 : session.frameCount / minutes;

      return SessionDetails(
        session: session,
        diskBytes: diskBytes,
        previews: previews,
        metadataSummary: metaSummary,
        captureRateFpm: rate,
        isIncompleteOnDisk: incomplete,
      );
    });
  }

  @override
  Future<Result<List<SessionPreviewImage>>> loadPreviewImages(
    String sessionId, {
    int limit = 24,
  }) {
    return _guard(() => _loadPreviewsInternal(sessionId, limit: limit));
  }

  @override
  Future<Result<DatasetSession>> renameSession(
    RenameDatasetSessionParams params,
  ) {
    return _guard(() async {
      final result = await _unwrap(_collection.renameSession(params));
      _logger.info('Rename ${params.id} → ${params.sessionName}',
          tag: 'DatasetExplorer');
      return result;
    });
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) {
    return _guard(() async {
      // Disk first (ok if missing), then Hive.
      final disk = await _storage.deleteSession(sessionId);
      disk.fold(onOk: (_) {}, onErr: (f) {
        _logger.debug('Disk delete: ${f.message}', tag: 'DatasetExplorer');
      });
      await _unwrap(_collection.deleteSession(sessionId));
      _logger.info('Delete $sessionId', tag: 'DatasetExplorer');
    });
  }

  @override
  Future<Result<DatasetSession>> duplicateSession(String sessionId) {
    return _guard(() async {
      final source = await _unwrap(_collection.getSession(sessionId));
      final copy = await _unwrap(
        _collection.createSession(
          CreateDatasetSessionParams(
            sessionName: '${source.sessionName} (Copy)',
            description: source.description,
          ),
        ),
      );
      _logger.info('Duplicate $sessionId → ${copy.id}', tag: 'DatasetExplorer');
      return copy;
    });
  }

  Future<List<SessionPreviewImage>> _loadPreviewsInternal(
    String sessionId, {
    required int limit,
  }) async {
    await _files.ensureRootLayout();
    final thumbDir = Directory(_files.paths.imagesThumbnails(sessionId));
    final originalDir = Directory(_files.paths.imagesOriginal(sessionId));
    final frames = <int>{};

    Future<void> scan(Directory dir) async {
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final match = RegExp(r'frame_(\d+)\.jpg').firstMatch(name);
        if (match != null) {
          frames.add(int.parse(match.group(1)!));
        }
      }
    }

    await scan(thumbDir);
    await scan(originalDir);
    final sorted = frames.toList()..sort((a, b) => b.compareTo(a));
    final limited = sorted.take(limit).toList();

    return [
      for (final n in limited)
        SessionPreviewImage(
          frameNumber: n,
          thumbnailPath:
              '${_files.paths.imagesThumbnails(sessionId)}/${DatasetPaths.thumbnailFileName(n)}',
          originalPath:
              '${_files.paths.imagesOriginal(sessionId)}/${DatasetPaths.originalFileName(n)}',
        ),
    ];
  }

  List<DatasetSession> _applyQuery(
    List<DatasetSession> source,
    SessionQuery query,
  ) {
    var list = List<DatasetSession>.from(source);
    final q = query.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.sessionName.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.status.label.toLowerCase().contains(q) ||
            s.createdAt.toIso8601String().contains(q);
      }).toList();
    }

    final now = DateTime.now();
    list = list.where((s) {
      final d = s.createdAt;
      return switch (query.dateFilter) {
        SessionDateFilter.all => true,
        SessionDateFilter.today =>
          d.year == now.year && d.month == now.month && d.day == now.day,
        SessionDateFilter.yesterday => () {
            final y = now.subtract(const Duration(days: 1));
            return d.year == y.year && d.month == y.month && d.day == y.day;
          }(),
        SessionDateFilter.last7Days =>
          d.isAfter(now.subtract(const Duration(days: 7))),
        SessionDateFilter.lastMonth =>
          d.isAfter(now.subtract(const Duration(days: 30))),
      };
    }).toList();

    if (query.status != null) {
      list = list.where((s) => s.status == query.status).toList();
    }
    if (query.minStorageBytes != null) {
      list = list
          .where((s) => s.totalStorage >= query.minStorageBytes!)
          .toList();
    }
    if (query.minFloodEvents != null) {
      list = list
          .where((s) => s.floodEventCount >= query.minFloodEvents!)
          .toList();
    }

    list.sort((a, b) {
      return switch (query.sort) {
        SessionSortOption.newest => b.createdAt.compareTo(a.createdAt),
        SessionSortOption.oldest => a.createdAt.compareTo(b.createdAt),
        SessionSortOption.largestDataset =>
          b.totalStorage.compareTo(a.totalStorage),
        SessionSortOption.mostFrames => b.frameCount.compareTo(a.frameCount),
        SessionSortOption.longestDuration =>
          b.duration.compareTo(a.duration),
        SessionSortOption.highestFloodEvents =>
          b.floodEventCount.compareTo(a.floodEventCount),
      };
    });

    return list;
  }

  SessionPage _paginate(List<DatasetSession> filtered, SessionQuery query) {
    final start = query.page * query.pageSize;
    if (start >= filtered.length) {
      return SessionPage(
        sessions: const [],
        totalCount: filtered.length,
        query: query,
      );
    }
    final end = (start + query.pageSize).clamp(0, filtered.length);
    return SessionPage(
      sessions: filtered.sublist(start, end),
      totalCount: filtered.length,
      query: query,
    );
  }

  Future<T> _unwrap<T>(Future<Result<T>> future) async {
    final result = await future;
    return result.fold(
      onOk: (v) => v,
      onErr: (f) => throw CacheException(message: f.message),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
