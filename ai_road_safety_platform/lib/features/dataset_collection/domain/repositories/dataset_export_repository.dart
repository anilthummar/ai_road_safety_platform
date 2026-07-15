import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';

/// Research dataset export façade (Phase 12.8).
abstract class DatasetExportRepository {
  /// Exports the filtered session set using [settings].
  Future<Result<ExportResult>> exportDataset(
    ExportSettings settings, {
    ExportProgressCallback? onProgress,
  });

  /// Exports a single session (others filtered out).
  Future<Result<ExportResult>> exportSession(
    String sessionId,
    ExportSettings settings, {
    ExportProgressCallback? onProgress,
  });

  /// Writes statistics JSON into an existing export folder.
  Future<Result<String>> exportStatistics(String exportFolderPath);

  /// Generates / refreshes manifest.json for [exportFolderPath].
  Future<Result<ExportManifest>> generateManifest(String exportFolderPath);

  /// Generates / refreshes README.md for [exportFolderPath].
  Future<Result<String>> generateReadme(String exportFolderPath);

  /// Compresses [exportFolderPath] into a sibling ZIP.
  Future<Result<String>> compressDataset(String exportFolderPath);

  /// Validates an export folder (and ZIP when present).
  Future<Result<ExportValidation>> validateExport(String exportFolderPath);

  /// Recent successful / failed exports.
  Future<Result<List<ExportHistoryEntry>>> loadExportHistory();
}
