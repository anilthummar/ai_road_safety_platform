import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_analytics_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_analytics_calculator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';

/// Aggregates collection + storage I/O into research analytics reports.
class DatasetAnalyticsRepositoryImpl implements DatasetAnalyticsRepository {
  final DatasetCollectionRepository _collection;
  final DatasetStorageRepository _storage;
  final DatasetFileManager _files;
  final DatasetAnalyticsCalculator _calculator;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;

  /// Max sessions to sample metadata from (performance).
  static const int _maxSampleSessions = 40;

  /// Frames sampled per session (newest indices when recoverable).
  static const int _samplesPerSession = 2;

  /// Creates [DatasetAnalyticsRepositoryImpl].
  DatasetAnalyticsRepositoryImpl({
    required DatasetCollectionRepository collectionRepository,
    required DatasetStorageRepository storageRepository,
    required DatasetFileManager fileManager,
    required DatasetAnalyticsCalculator calculator,
    required ErrorHandler errorHandler,
    required AppLogger logger,
  })  : _collection = collectionRepository,
        _storage = storageRepository,
        _files = fileManager,
        _calculator = calculator,
        _errorHandler = errorHandler,
        _logger = logger;

  @override
  Future<Result<DatasetAnalyticsReport>> loadAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  }) {
    return _guard(() async {
      final report = await _buildReport(filter);
      _logger.info(
        'Analytics Loaded matched=${report.matchedSessionCount}',
        tag: 'DatasetAnalytics',
      );
      _logger.info(
        'Insights Generated count=${report.insights.insights.length}',
        tag: 'DatasetAnalytics',
      );
      return report;
    });
  }

  @override
  Future<Result<ResearchInsights>> loadResearchInsights({
    AnalyticsFilter filter = const AnalyticsFilter(),
  }) {
    return _guard(() async {
      final report = await _buildReport(filter);
      return report.insights;
    });
  }

  @override
  Future<Result<StorageAnalytics>> loadStorageAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  }) {
    return _guard(() async {
      final report = await _buildReport(filter);
      return report.storage;
    });
  }

  @override
  Future<Result<SessionAnalytics>> loadSessionAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  }) {
    return _guard(() async {
      final report = await _buildReport(filter);
      return report.sessions;
    });
  }

  @override
  Future<Result<LocationAnalytics>> loadLocationAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  }) {
    return _guard(() async {
      final report = await _buildReport(filter);
      return report.location;
    });
  }

  @override
  Future<Result<InferenceAnalytics>> loadInferenceAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  }) {
    return _guard(() async {
      final report = await _buildReport(filter);
      return report.inference;
    });
  }

  Future<DatasetAnalyticsReport> _buildReport(AnalyticsFilter filter) async {
    final sessions = await _unwrap(_collection.getSessions());
    final usage = await _unwrap(_storage.calculateStorage());
    final folders = await _safeFolders();
    final filtered = _calculator.applyFilter(sessions, filter);

    final recovery = await _loadRecovery(filtered);
    final samples = await _sampleFrames(filtered, recovery);

    return _calculator.build(
      sessions: sessions,
      usage: usage,
      folders: folders,
      filter: filter,
      recovery: recovery,
      samples: samples,
    );
  }

  Future<List<FolderInfo>> _safeFolders() async {
    final result = await _storage.listFolderInfo();
    return result.fold(onOk: (v) => v, onErr: (_) => const <FolderInfo>[]);
  }

  Future<List<AnalyticsRecoverySnapshot>> _loadRecovery(
    List<DatasetSession> sessions,
  ) async {
    final result = await _storage.recoverSession();
    return result.fold(
      onOk: (list) {
        final wanted = {for (final s in sessions) s.id};
        return [
          for (final r in list)
            if (wanted.isEmpty || wanted.contains(r.sessionId))
              AnalyticsRecoverySnapshot(
                sessionId: r.sessionId,
                imageCount: r.imageCount,
                metadataCount: r.metadataCount,
                isIncomplete: r.isIncomplete,
              ),
        ];
      },
      onErr: (_) => const <AnalyticsRecoverySnapshot>[],
    );
  }

  Future<List<AnalyticsFrameSample>> _sampleFrames(
    List<DatasetSession> sessions,
    List<AnalyticsRecoverySnapshot> recovery,
  ) async {
    final byId = {for (final r in recovery) r.sessionId: r};
    final samples = <AnalyticsFrameSample>[];
    final limited = sessions.take(_maxSampleSessions);

    for (final session in limited) {
      final snap = byId[session.id];
      final maxFrame = snap == null
          ? session.frameCount
          : (snap.imageCount > snap.metadataCount
              ? snap.imageCount
              : snap.metadataCount);
      if (maxFrame <= 0) continue;

      final indices = <int>{
        maxFrame,
        if (maxFrame > 1) (maxFrame / 2).ceil(),
      }.take(_samplesPerSession);

      for (final frame in indices) {
        final metaResult = await _storage.loadMetadata(
          sessionId: session.id,
          frameNumber: frame,
        );
        metaResult.fold(
          onOk: (m) {
            samples.add(
              AnalyticsFrameSample(
                sessionId: session.id,
                hasGps: m.location.isAvailable,
                accuracyMeters: m.location.accuracy,
                inferenceTimeMs: m.inference.inferenceTimeMs,
                confidence: m.inference.confidence,
                waterCoverage: m.inference.waterCoverage,
                riskLevel: m.inference.riskLevel,
                inferenceAvailable: m.inference.isAvailable,
              ),
            );
          },
          onErr: (_) {},
        );
      }
    }

    // Placeholder for future isolate / background calculator.
    await _files.ensureRootLayout();
    return samples;
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
