import 'dart:io';
import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Filesystem [DatasetFileManager] under `{docs}/dataset`.
class DatasetFileManagerImpl implements DatasetFileManager {
  final AppLogger _logger;
  DatasetPaths? _paths;

  /// Creates [DatasetFileManagerImpl].
  DatasetFileManagerImpl({required AppLogger logger}) : _logger = logger;

  @override
  DatasetPaths get paths {
    final p = _paths;
    if (p == null) {
      throw const CacheException(
        message: 'Dataset root not initialized — call ensureRootLayout first.',
      );
    }
    return p;
  }

  /// Resolves and caches the dataset root (idempotent).
  Future<DatasetPaths> resolvePaths() async {
    if (_paths != null) return _paths!;
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/dataset');
    if (!await root.exists()) {
      await root.create(recursive: true);
      _logger.info('Folder Created: ${root.path}', tag: 'DatasetFileManager');
    }
    _paths = DatasetPaths(root: root.path);
    return _paths!;
  }

  @override
  Future<void> ensureRootLayout() async {
    final p = await resolvePaths();
    for (final dir in [
      p.sessions,
      p.exports,
      p.cache,
      p.backups,
      p.models,
      p.modelVersions,
      p.modelImported,
      p.experiments,
      p.benchmarks,
      p.activeLearning,
      p.deployments,
      p.deploymentPackages,
      p.sensorFusion,
    ]) {
      await _ensureDir(dir);
    }
  }

  @override
  Future<void> ensureSessionLayout(String sessionId) async {
    await ensureRootLayout();
    final id = sessionId.trim();
    if (id.isEmpty) {
      throw const CacheException(message: 'Session id required for folders.');
    }
    final p = paths;
    for (final dir in [
      p.imagesOriginal(id),
      p.imagesCompressed(id),
      p.imagesThumbnails(id),
      p.frameMetadataDir(id),
      p.sessionMetadataDir(id),
      p.previews(id),
      p.temp(id),
      p.logs(id),
    ]) {
      await _ensureDir(dir);
    }
  }

  @override
  Future<bool> exists(String path) async {
    if (await File(path).exists()) return true;
    return Directory(path).exists();
  }

  @override
  Future<void> deletePath(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _logger.info('Folder Deleted (file): $path', tag: 'DatasetFileManager');
      return;
    }
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _logger.info('Folder Deleted: $path', tag: 'DatasetFileManager');
    }
  }

  @override
  Future<void> move(String from, String to) async {
    await _ensureParent(to);
    final file = File(from);
    if (await file.exists()) {
      await file.rename(to);
      return;
    }
    final dir = Directory(from);
    if (await dir.exists()) {
      await dir.rename(to);
      return;
    }
    throw CacheException(message: 'Move failed — missing path: $from');
  }

  @override
  Future<void> copy(String from, String to) async {
    await _ensureParent(to);
    final file = File(from);
    if (!await file.exists()) {
      throw CacheException(message: 'Copy failed — missing file: $from');
    }
    await file.copy(to);
  }

  @override
  Future<void> rename(String from, String to) => move(from, to);

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    await _ensureParent(path);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw CacheException(message: 'File not found: $path');
    }
    return file.readAsBytes();
  }

  @override
  Future<void> writeText(String path, String contents) async {
    await _ensureParent(path);
    await File(path).writeAsString(contents, flush: true);
  }

  @override
  Future<String> readText(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw CacheException(message: 'File not found: $path');
    }
    return file.readAsString();
  }

  @override
  Future<int> directoryByteSize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  @override
  Future<int> fileCount(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) count++;
    }
    return count;
  }

  @override
  Future<List<String>> listSessionIds() async {
    await ensureRootLayout();
    final dir = Directory(paths.sessions);
    if (!await dir.exists()) return [];
    final ids = <String>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) {
        ids.add(entity.uri.pathSegments.where((s) => s.isNotEmpty).last);
      }
    }
    ids.sort();
    return ids;
  }

  @override
  Future<Uint8List> generateThumbnail(
    Uint8List sourceJpeg, {
    int maxSide = 256,
  }) async {
    final decoded = img.decodeImage(sourceJpeg);
    if (decoded == null) {
      throw const CacheException(message: 'Corrupted image — cannot thumbnail.');
    }
    final thumb = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
    );
    return Uint8List.fromList(img.encodeJpg(thumb, quality: 75));
  }

  @override
  Future<Uint8List> compressImage(
    Uint8List source, {
    int quality = 70,
  }) async {
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      // Assume already JPEG — pass through.
      return source;
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }

  @override
  Future<int> cleanTemporaryFiles() async {
    await ensureRootLayout();
    var removed = 0;
    removed += await _clearDirContents(paths.cache);
    final sessions = await listSessionIds();
    for (final id in sessions) {
      removed += await _clearDirContents(paths.temp(id));
    }
    return removed;
  }

  @override
  Future<List<RecentStorageFile>> listRecentFiles({int limit = 20}) async {
    await ensureRootLayout();
    final files = <RecentStorageFile>[];
    final root = Directory(paths.root);
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      files.add(
        RecentStorageFile(
          path: entity.path,
          name: entity.uri.pathSegments.last,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    if (files.length <= limit) return files;
    return files.sublist(0, limit);
  }

  Future<void> _ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      _logger.info('Folder Created: $path', tag: 'DatasetFileManager');
    }
  }

  Future<void> _ensureParent(String path) async {
    final parent = File(path).parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
  }

  Future<int> _clearDirContents(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    var n = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        await entity.delete();
        n++;
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
        n++;
      }
    }
    return n;
  }
}
