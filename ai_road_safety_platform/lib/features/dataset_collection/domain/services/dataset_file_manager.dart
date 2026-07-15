import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';

/// Low-level dataset filesystem operations (Phase 12.5).
abstract class DatasetFileManager {
  /// Absolute dataset root path.
  DatasetPaths get paths;

  /// Ensures root + sessions/exports/cache/backups exist.
  Future<void> ensureRootLayout();

  /// Creates full session folder tree.
  Future<void> ensureSessionLayout(String sessionId);

  /// Whether [path] exists.
  Future<bool> exists(String path);

  /// Deletes a file or directory recursively.
  Future<void> deletePath(String path);

  /// Moves [from] → [to].
  Future<void> move(String from, String to);

  /// Copies [from] → [to].
  Future<void> copy(String from, String to);

  /// Renames / moves within same parent semantics.
  Future<void> rename(String from, String to);

  /// Writes [bytes] to [path], creating parents.
  Future<void> writeBytes(String path, Uint8List bytes);

  /// Reads file bytes.
  Future<Uint8List> readBytes(String path);

  /// Writes UTF-8 text.
  Future<void> writeText(String path, String contents);

  /// Reads UTF-8 text.
  Future<String> readText(String path);

  /// Recursive folder size in bytes.
  Future<int> directoryByteSize(String path);

  /// Counts files under [path] (recursive).
  Future<int> fileCount(String path);

  /// Lists session ids under `sessions/`.
  Future<List<String>> listSessionIds();

  /// Generates JPEG thumbnail bytes from [sourceJpeg].
  Future<Uint8List> generateThumbnail(
    Uint8List sourceJpeg, {
    int maxSide = 256,
  });

  /// Compresses JPEG/PNG [source] to a smaller JPEG.
  Future<Uint8List> compressImage(
    Uint8List source, {
    int quality = 70,
  });

  /// Deletes files under all session `temp/` folders and root `cache/`.
  Future<int> cleanTemporaryFiles();

  /// Lists recently modified files under the dataset root.
  Future<List<RecentStorageFile>> listRecentFiles({int limit = 20});
}

/// Disk budget / usage calculations.
abstract class StorageManager {
  /// Soft dataset budget before warning (bytes).
  int get softLimitBytes;

  /// Computes [StorageUsage] for the dataset tree.
  Future<StorageUsage> calculateUsage();

  /// True when writes should be refused.
  Future<bool> isStorageCriticallyLow();
}

/// Isolates / async compute placeholder for heavy encode work.
abstract class StorageBackgroundProcessor {
  /// Runs [work] off the UI critical path (await chain / future isolate).
  Future<T> runAsync<T>(Future<T> Function() work);

  /// Releases resources.
  void dispose();
}
