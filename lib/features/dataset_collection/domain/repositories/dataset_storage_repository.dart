import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// Local dataset storage contract (offline — Phase 12.5).
abstract class DatasetStorageRepository {
  /// Persists original + compressed + thumbnail JPEGs for a frame.
  Future<Result<SavedImagePaths>> saveImage(SaveImageParams params);

  /// Persists frame metadata JSON (and appends session stats snapshot).
  Future<Result<String>> saveMetadata(SaveMetadataParams params);

  /// Loads original image bytes for [sessionId] / [frameNumber].
  Future<Result<Uint8List>> loadImage({
    required String sessionId,
    required int frameNumber,
  });

  /// Loads frame metadata JSON as [FrameMetadata].
  Future<Result<FrameMetadata>> loadMetadata({
    required String sessionId,
    required int frameNumber,
  });

  /// Deletes one image triad + metadata for a frame.
  Future<Result<void>> deleteImage({
    required String sessionId,
    required int frameNumber,
  });

  /// Deletes an entire session folder tree.
  Future<Result<void>> deleteSession(String sessionId);

  /// Calculates [StorageUsage].
  Future<Result<StorageUsage>> calculateStorage();

  /// Alias of [calculateStorage].
  Future<Result<StorageUsage>> getStorageUsage();

  /// Clears `dataset/cache` (+ in-memory caches).
  Future<Result<void>> clearCache();

  /// Clears session temp folders + cache.
  Future<Result<int>> cleanupTemporaryFiles();

  /// Scans and recovers incomplete sessions; prefers [sessionId] when set.
  Future<Result<List<SessionRecoveryInfo>>> recoverSession({String? sessionId});

  /// Folder cards for developer UI.
  Future<Result<List<FolderInfo>>> listFolderInfo();

  /// Recent files for developer UI.
  Future<Result<List<RecentStorageFile>>> listRecentFiles({int limit = 20});
}
