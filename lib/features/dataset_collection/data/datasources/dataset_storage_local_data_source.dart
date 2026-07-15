import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// File IO + recovery for dataset storage (Phase 12.5).
abstract class DatasetStorageLocalDataSource {
  /// Save image triad.
  Future<SavedImagePaths> saveImage(SaveImageParams params);

  /// Save frame metadata JSON.
  Future<String> saveMetadata(FrameMetadata metadata);

  /// Load original image bytes.
  Future<Uint8List> loadImage({
    required String sessionId,
    required int frameNumber,
  });

  /// Load frame metadata.
  Future<FrameMetadata> loadMetadata({
    required String sessionId,
    required int frameNumber,
  });

  /// Delete one frame's files.
  Future<void> deleteImage({
    required String sessionId,
    required int frameNumber,
  });

  /// Delete session directory.
  Future<void> deleteSession(String sessionId);

  /// Storage usage.
  Future<StorageUsage> calculateStorage();

  /// Clear cache dir + memory cache.
  Future<void> clearCache();

  /// Cleanup temps.
  Future<int> cleanupTemporaryFiles();

  /// Recover sessions.
  Future<List<SessionRecoveryInfo>> recoverSessions({String? sessionId});

  /// Folder info cards.
  Future<List<FolderInfo>> listFolderInfo();

  /// Recent files.
  Future<List<RecentStorageFile>> listRecentFiles({int limit = 20});
}
