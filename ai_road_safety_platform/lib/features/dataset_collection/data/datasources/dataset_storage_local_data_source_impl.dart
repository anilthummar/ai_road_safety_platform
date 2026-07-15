import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_storage_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/models/frame_metadata_json_codec.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/dataset_storage_cache.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:image/image.dart' as img;

/// Disk-backed [DatasetStorageLocalDataSource].
class DatasetStorageLocalDataSourceImpl
    implements DatasetStorageLocalDataSource {
  final DatasetFileManager _files;
  final StorageManager _storage;
  final StorageBackgroundProcessor _background;
  final DatasetStorageCache _cache;
  final AppLogger _logger;

  /// Creates [DatasetStorageLocalDataSourceImpl].
  DatasetStorageLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required StorageManager storageManager,
    required StorageBackgroundProcessor backgroundProcessor,
    required DatasetStorageCache cache,
    required AppLogger logger,
  })  : _files = fileManager,
        _storage = storageManager,
        _background = backgroundProcessor,
        _cache = cache,
        _logger = logger;

  @override
  Future<SavedImagePaths> saveImage(SaveImageParams params) {
    return _background.runAsync(() async {
      final sessionId = params.sessionId.trim();
      if (sessionId.isEmpty) {
        throw const CacheException(message: 'Session id required to save image.');
      }
      if (params.frameNumber <= 0) {
        throw const CacheException(message: 'Frame number must be > 0.');
      }
      if (params.bytes.isEmpty) {
        throw const CacheException(message: 'Image bytes are empty.');
      }
      if (await _storage.isStorageCriticallyLow()) {
        throw const CacheException(
          message: 'Not enough disk space to save images.',
        );
      }

      await _files.ensureSessionLayout(sessionId);
      final p = _files.paths;
      final name = DatasetPaths.originalFileName(params.frameNumber);
      final originalPath = '${p.imagesOriginal(sessionId)}/$name';
      final compressedPath = '${p.imagesCompressed(sessionId)}/$name';
      final thumbPath = '${p.imagesThumbnails(sessionId)}/$name';

      if (await _files.exists(originalPath)) {
        throw CacheException(
          message: 'Duplicate file name: $name for session $sessionId',
        );
      }

      final jpeg = await _ensureJpeg(params.bytes);
      final compressed = await _files.compressImage(jpeg, quality: 70);
      final thumb = await _files.generateThumbnail(jpeg);

      await _files.writeBytes(originalPath, jpeg);
      await _files.writeBytes(compressedPath, compressed);
      await _files.writeBytes(thumbPath, thumb);

      _cache.putThumbnail(sessionId, params.frameNumber, thumb);
      _cache.rememberSession(sessionId);

      _logger.info(
        'Image Saved session=$sessionId frame=${params.frameNumber}',
        tag: 'DatasetStorage',
      );

      return SavedImagePaths(
        sessionId: sessionId,
        frameNumber: params.frameNumber,
        originalPath: originalPath,
        compressedPath: compressedPath,
        thumbnailPath: thumbPath,
        originalBytes: jpeg.length,
      );
    });
  }

  @override
  Future<String> saveMetadata(FrameMetadata metadata) {
    return _background.runAsync(() async {
      final sessionId = metadata.session.sessionId.trim();
      final frameNumber = metadata.session.frameNumber;
      if (sessionId.isEmpty) {
        throw const CacheException(message: 'Missing Session in metadata.');
      }
      if (frameNumber <= 0) {
        throw const CacheException(message: 'Invalid frame number in metadata.');
      }
      if (await _storage.isStorageCriticallyLow()) {
        throw const CacheException(
          message: 'Not enough disk space to save metadata.',
        );
      }

      await _files.ensureSessionLayout(sessionId);
      final fileName = DatasetPaths.frameMetadataFileName(frameNumber);
      final path =
          '${_files.paths.frameMetadataDir(sessionId)}/$fileName';

      if (await _files.exists(path)) {
        // Idempotent overwrite for crash recovery retries.
        _logger.debug('Overwriting metadata $path', tag: 'DatasetStorage');
      }

      final json = jsonEncode(FrameMetadataJsonCodec.toJson(metadata));
      try {
        FrameMetadataJsonCodec.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
      } catch (e) {
        throw CacheException(message: 'Corrupted metadata payload: $e');
      }

      await _files.writeText(path, json);
      _cache.putMetadata(sessionId, frameNumber, metadata);

      // Append lightweight session stats snapshot.
      final statsPath =
          '${_files.paths.sessionMetadataDir(sessionId)}/stats.json';
      final stats = <String, dynamic>{
        'sessionId': sessionId,
        'lastFrameNumber': frameNumber,
        'updatedAt': DateTime.now().toIso8601String(),
        'lastFrameId': metadata.session.frameId,
      };
      await _files.writeText(statsPath, jsonEncode(stats));

      _logger.info(
        'Metadata Saved session=$sessionId frame=$frameNumber',
        tag: 'DatasetStorage',
      );
      return path;
    });
  }

  @override
  Future<Uint8List> loadImage({
    required String sessionId,
    required int frameNumber,
  }) {
    return _background.runAsync(() async {
      final path =
          '${_files.paths.imagesOriginal(sessionId)}/${DatasetPaths.originalFileName(frameNumber)}';
      if (!await _files.exists(path)) {
        throw CacheException(message: 'Image does not exist: $path');
      }
      return _files.readBytes(path);
    });
  }

  @override
  Future<FrameMetadata> loadMetadata({
    required String sessionId,
    required int frameNumber,
  }) {
    return _background.runAsync(() async {
      final cached = _cache.getMetadata(sessionId, frameNumber);
      if (cached != null) return cached;

      final path =
          '${_files.paths.frameMetadataDir(sessionId)}/${DatasetPaths.frameMetadataFileName(frameNumber)}';
      if (!await _files.exists(path)) {
        throw CacheException(message: 'Metadata does not exist: $path');
      }
      try {
        final text = await _files.readText(path);
        final map = jsonDecode(text) as Map<String, dynamic>;
        final meta = FrameMetadataJsonCodec.fromJson(map);
        _cache.putMetadata(sessionId, frameNumber, meta);
        return meta;
      } catch (e) {
        throw CacheException(message: 'Corrupted metadata file: $path ($e)');
      }
    });
  }

  @override
  Future<void> deleteImage({
    required String sessionId,
    required int frameNumber,
  }) {
    return _background.runAsync(() async {
      final p = _files.paths;
      final name = DatasetPaths.originalFileName(frameNumber);
      final metaName = DatasetPaths.frameMetadataFileName(frameNumber);
      for (final path in [
        '${p.imagesOriginal(sessionId)}/$name',
        '${p.imagesCompressed(sessionId)}/$name',
        '${p.imagesThumbnails(sessionId)}/$name',
        '${p.frameMetadataDir(sessionId)}/$metaName',
      ]) {
        if (await _files.exists(path)) {
          await _files.deletePath(path);
        }
      }
    });
  }

  @override
  Future<void> deleteSession(String sessionId) {
    return _background.runAsync(() async {
      final path = _files.paths.session(sessionId);
      if (!await _files.exists(path)) {
        throw CacheException(message: 'Session folder not found: $sessionId');
      }
      await _files.deletePath(path);
      _logger.info('Folder Deleted: session $sessionId', tag: 'DatasetStorage');
    });
  }

  @override
  Future<StorageUsage> calculateStorage() => _storage.calculateUsage();

  @override
  Future<void> clearCache() {
    return _background.runAsync(() async {
      await _files.ensureRootLayout();
      await _files.deletePath(_files.paths.cache);
      await _files.ensureRootLayout();
      _cache.clear();
    });
  }

  @override
  Future<int> cleanupTemporaryFiles() {
    return _background.runAsync(_files.cleanTemporaryFiles);
  }

  @override
  Future<List<SessionRecoveryInfo>> recoverSessions({String? sessionId}) {
    return _background.runAsync(() async {
      await _files.ensureRootLayout();
      final ids = sessionId == null
          ? await _files.listSessionIds()
          : [sessionId];
      final results = <SessionRecoveryInfo>[];

      for (final id in ids) {
        final sessionPath = _files.paths.session(id);
        if (!await _files.exists(sessionPath)) {
          results.add(
            SessionRecoveryInfo(
              sessionId: id,
              sessionPath: sessionPath,
              imageCount: 0,
              metadataCount: 0,
              isIncomplete: true,
              notes: const ['Session folder missing'],
            ),
          );
          _logger.warning(
            'Recovery Failure: missing session $id',
            tag: 'DatasetStorage',
          );
          continue;
        }

        // Ensure layout for incomplete trees.
        await _files.ensureSessionLayout(id);

        final imageCount =
            await _files.fileCount(_files.paths.imagesOriginal(id));
        final metadataCount =
            await _files.fileCount(_files.paths.frameMetadataDir(id));
        final tempCount = await _files.fileCount(_files.paths.temp(id));
        final notes = <String>[];
        var incomplete = false;
        if (imageCount != metadataCount) {
          incomplete = true;
          notes.add(
            'Image/metadata mismatch ($imageCount vs $metadataCount)',
          );
        }
        if (tempCount > 0) {
          incomplete = true;
          notes.add('Temp files present ($tempCount)');
        }

        // Detect corrupted metadata files.
        final metaDir = Directory(_files.paths.frameMetadataDir(id));
        if (await metaDir.exists()) {
          await for (final entity
              in metaDir.list(followLinks: false)) {
            if (entity is! File || !entity.path.endsWith('.json')) continue;
            try {
              final text = await entity.readAsString();
              FrameMetadataJsonCodec.fromJson(
                jsonDecode(text) as Map<String, dynamic>,
              );
            } catch (_) {
              incomplete = true;
              notes.add('Corrupted file: ${entity.uri.pathSegments.last}');
            }
          }
        }

        results.add(
          SessionRecoveryInfo(
            sessionId: id,
            sessionPath: sessionPath,
            imageCount: imageCount,
            metadataCount: metadataCount,
            isIncomplete: incomplete,
            notes: notes,
          ),
        );
        _logger.info(
          incomplete
              ? 'Recovery Success (incomplete notes) session=$id'
              : 'Recovery Success session=$id',
          tag: 'DatasetStorage',
        );
      }

      return results;
    });
  }

  @override
  Future<List<FolderInfo>> listFolderInfo() {
    return _background.runAsync(() async {
      await _files.ensureRootLayout();
      final p = _files.paths;
      Future<FolderInfo> one(String label, String path) async {
        return FolderInfo(
          label: label,
          path: path,
          sizeBytes: await _files.directoryByteSize(path),
          fileCount: await _files.fileCount(path),
        );
      }

      return [
        await one('Root', p.root),
        await one('Sessions', p.sessions),
        await one('Exports', p.exports),
        await one('Cache', p.cache),
        await one('Backups', p.backups),
      ];
    });
  }

  @override
  Future<List<RecentStorageFile>> listRecentFiles({int limit = 20}) {
    return _background.runAsync(() => _files.listRecentFiles(limit: limit));
  }

  Future<Uint8List> _ensureJpeg(Uint8List bytes) async {
    // Already JPEG?
    if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return bytes;
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const CacheException(
        message: 'Corrupted image — cannot encode JPEG.',
      );
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
  }
}
