import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';

/// Strategy contract for format-specific export writers (Phase 12.8).
///
/// New formats implement this interface and register in
/// [DatasetExportFactory] — Open/Closed.
abstract class ExportStrategy {
  /// Format this strategy handles.
  ExportFormat get format;

  /// Writes format artefacts under [context.exportRoot].
  ///
  /// Implementations must not own Hive / camera I/O; they receive a
  /// prepared [ExportContext] and a [ExportFileWriter] for disk access.
  Future<ExportStrategyResult> export(
    ExportContext context,
    ExportFileWriter writer, {
    ExportProgressCallback? onProgress,
  });
}

/// Narrow file API for strategies (keeps domain free of `dart:io`).
abstract class ExportFileWriter {
  /// Absolute export root for this run.
  String get exportRoot;

  /// Ensures a subdirectory under the export root.
  Future<String> ensureDir(String relativePath);

  /// Writes UTF-8 text to a relative path under the export root.
  Future<void> writeText(String relativePath, String contents);

  /// Writes bytes to a relative path.
  Future<void> writeBytes(String relativePath, List<int> bytes);

  /// Copies an absolute [sourcePath] into [relativeDest].
  Future<void> copyFile(String sourcePath, String relativeDest);

  /// Copies a directory tree from absolute [sourceDir] into [relativeDest].
  Future<int> copyDirectory(String sourceDir, String relativeDest);

  /// Whether absolute [path] exists.
  Future<bool> existsAbsolute(String path);

  /// Lists file names under absolute [dir] (non-recursive).
  Future<List<String>> listFiles(String absoluteDir);

  /// Reads UTF-8 from absolute [path].
  Future<String> readAbsoluteText(String path);

  /// Reads bytes from absolute [path].
  Future<List<int>> readAbsoluteBytes(String path);
}
