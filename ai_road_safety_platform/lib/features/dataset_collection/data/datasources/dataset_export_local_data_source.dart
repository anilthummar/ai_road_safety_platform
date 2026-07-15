import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_strategy.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Local filesystem operations for research exports (Phase 12.8).
abstract class DatasetExportLocalDataSource {
  /// Creates a dated export folder under `dataset/exports/`.
  Future<String> createExportFolder(String datasetName);

  /// File writer bound to [exportRoot].
  ExportFileWriter writerFor(String exportRoot);

  /// Writes [manifest] as manifest.json.
  Future<void> writeManifest(String exportRoot, ExportManifest manifest);

  /// Writes README.md.
  Future<void> writeReadme(String exportRoot, String markdown);

  /// Creates a ZIP beside the folder (store+deflate via archive package).
  /// Streaming ZIP is a future enhancement — this buffers file entries.
  Future<String> compressFolder(String exportRoot);

  /// Validates folder + optional ZIP.
  Future<ExportValidation> validateExport(String exportRoot);

  /// Appends a history entry.
  Future<void> appendHistory(ExportHistoryEntry entry);

  /// Loads export history (newest first).
  Future<List<ExportHistoryEntry>> loadHistory();

  /// Directory byte size.
  Future<int> directorySize(String path);

  /// Absolute path to dataset exports root.
  Future<String> exportsRoot();
}

/// Concrete [DatasetExportLocalDataSource] using [DatasetFileManager] + IO.
class DatasetExportLocalDataSourceImpl implements DatasetExportLocalDataSource {
  final DatasetFileManager _files;
  final StorageBackgroundProcessor _background;
  final AppLogger _logger;

  /// Creates [DatasetExportLocalDataSourceImpl].
  DatasetExportLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required StorageBackgroundProcessor backgroundProcessor,
    required AppLogger logger,
  })  : _files = fileManager,
        _background = backgroundProcessor,
        _logger = logger;

  @override
  Future<String> exportsRoot() async {
    await _files.ensureRootLayout();
    return _files.paths.exports;
  }

  @override
  Future<String> createExportFolder(String datasetName) async {
    await _files.ensureRootLayout();
    final safe = datasetName
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final folderName = '${safe.isEmpty ? 'Dataset' : safe}_$stamp';
    final path = p.join(_files.paths.exports, folderName);
    await Directory(path).create(recursive: true);
    _logger.info('Export folder created: $path', tag: 'DatasetExport');
    return path;
  }

  @override
  ExportFileWriter writerFor(String exportRoot) =>
      _IoExportFileWriter(exportRoot: exportRoot, logger: _logger);

  @override
  Future<void> writeManifest(
    String exportRoot,
    ExportManifest manifest,
  ) async {
    final file = File(p.join(exportRoot, 'manifest.json'));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    _logger.info('Manifest Generated', tag: 'DatasetExport');
  }

  @override
  Future<void> writeReadme(String exportRoot, String markdown) async {
    final file = File(p.join(exportRoot, 'README.md'));
    await file.writeAsString(markdown);
    _logger.info('README Generated', tag: 'DatasetExport');
  }

  @override
  Future<String> compressFolder(String exportRoot) async {
    return _background.runAsync(() async {
      final dir = Directory(exportRoot);
      if (!await dir.exists()) {
        throw const CacheException(message: 'Export folder missing for ZIP.');
      }
      final archive = Archive();
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final relative = p.relative(entity.path, from: exportRoot);
        final bytes = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile(relative, bytes.length, bytes),
        );
      }
      final encoded = ZipEncoder().encode(archive);
      final zipPath = '$exportRoot.zip';
      await File(zipPath).writeAsBytes(Uint8List.fromList(encoded), flush: true);
      _logger.info('ZIP Created: $zipPath', tag: 'DatasetExport');
      return zipPath;
    });
  }

  @override
  Future<ExportValidation> validateExport(String exportRoot) async {
    final errors = <String>[];
    final warnings = <String>[];
    final root = Directory(exportRoot);
    if (!await root.exists()) {
      return const ExportValidation(
        isValid: false,
        errors: ['Export folder does not exist'],
        warnings: [],
        imagesPresent: false,
        metadataPresent: false,
        sessionsPresent: false,
        manifestPresent: false,
        readmePresent: false,
        zipPresent: false,
        zipIntegrityOk: false,
      );
    }

    final imagesPresent = await Directory(p.join(exportRoot, 'images')).exists();
    final metadataPresent =
        await Directory(p.join(exportRoot, 'metadata')).exists();
    final sessionsPresent =
        await File(p.join(exportRoot, 'sessions', 'sessions.json')).exists() ||
            await Directory(p.join(exportRoot, 'sessions')).exists();
    final manifestPresent =
        await File(p.join(exportRoot, 'manifest.json')).exists();
    final readmePresent = await File(p.join(exportRoot, 'README.md')).exists();
    final zipPath = '$exportRoot.zip';
    final zipPresent = await File(zipPath).exists();

    if (!sessionsPresent) errors.add('sessions/ missing');
    if (!manifestPresent) warnings.add('manifest.json missing');
    if (!readmePresent) warnings.add('README.md missing');
    if (!imagesPresent) warnings.add('images/ missing (may be intentional)');
    if (!metadataPresent) {
      warnings.add('metadata/ missing (may be intentional)');
    }

    var zipOk = false;
    if (zipPresent) {
      try {
        final bytes = await File(zipPath).readAsBytes();
        final decoded = ZipDecoder().decodeBytes(bytes);
        zipOk = decoded.isNotEmpty;
        if (!zipOk) errors.add('ZIP is empty / corrupt');
      } catch (e) {
        errors.add('ZIP integrity check failed: $e');
      }
    }

    return ExportValidation(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      imagesPresent: imagesPresent,
      metadataPresent: metadataPresent,
      sessionsPresent: sessionsPresent,
      manifestPresent: manifestPresent,
      readmePresent: readmePresent,
      zipPresent: zipPresent,
      zipIntegrityOk: zipOk,
    );
  }

  @override
  Future<void> appendHistory(ExportHistoryEntry entry) async {
    final history = await loadHistory();
    final next = [entry, ...history].take(50).toList();
    final root = await exportsRoot();
    final file = File(p.join(root, 'history.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final e in next) e.toJson(),
      ]),
    );
  }

  @override
  Future<List<ExportHistoryEntry>> loadHistory() async {
    final root = await exportsRoot();
    final file = File(p.join(root, 'history.json'));
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map<String, dynamic>)
            ExportHistoryEntry.fromJson(item)
          else if (item is Map)
            ExportHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<int> directorySize(String path) => _files.directoryByteSize(path);
}

class _IoExportFileWriter implements ExportFileWriter {
  @override
  final String exportRoot;
  final AppLogger _logger;

  _IoExportFileWriter({required this.exportRoot, required AppLogger logger})
      : _logger = logger;

  String _abs(String relativePath) => p.join(exportRoot, relativePath);

  @override
  Future<String> ensureDir(String relativePath) async {
    final dir = Directory(_abs(relativePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<void> writeText(String relativePath, String contents) async {
    final file = File(_abs(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async {
    final file = File(_abs(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> copyFile(String sourcePath, String relativeDest) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      _logger.debug('Skip missing file $sourcePath', tag: 'DatasetExport');
      return;
    }
    final dest = File(_abs(relativeDest));
    await dest.parent.create(recursive: true);
    await src.copy(dest.path);
  }

  @override
  Future<int> copyDirectory(String sourceDir, String relativeDest) async {
    final src = Directory(sourceDir);
    if (!await src.exists()) return 0;
    var count = 0;
    await for (final entity in src.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: sourceDir);
      await copyFile(entity.path, p.join(relativeDest, rel));
      count++;
    }
    return count;
  }

  @override
  Future<bool> existsAbsolute(String path) async {
    if (await File(path).exists()) return true;
    return Directory(path).exists();
  }

  @override
  Future<List<String>> listFiles(String absoluteDir) async {
    final dir = Directory(absoluteDir);
    if (!await dir.exists()) return const [];
    final names = <String>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is File) names.add(p.basename(e.path));
    }
    return names;
  }

  @override
  Future<String> readAbsoluteText(String path) => File(path).readAsString();

  @override
  Future<List<int>> readAbsoluteBytes(String path) => File(path).readAsBytes();
}
