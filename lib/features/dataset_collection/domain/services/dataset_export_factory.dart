import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_strategies.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_strategy.dart';

/// Factory for [ExportStrategy] instances (Open/Closed).
///
/// Register new formats here without changing callers.
class DatasetExportFactory {
  final DatasetPaths Function() _paths;
  final Map<ExportFormat, ExportStrategy> _cache = {};

  /// Creates [DatasetExportFactory].
  DatasetExportFactory({required DatasetPaths Function() paths})
      : _paths = paths;

  /// Returns the strategy for [format], creating it once.
  ExportStrategy create(ExportFormat format) {
    return _cache.putIfAbsent(format, () => _build(format));
  }

  /// All supported formats.
  List<ExportFormat> get supportedFormats => ExportFormat.values;

  ExportStrategy _build(ExportFormat format) {
    final json = JsonExportStrategy(paths: _paths);
    return switch (format) {
      ExportFormat.json => json,
      ExportFormat.csv => CsvExportStrategy(paths: _paths),
      ExportFormat.zip => ZipExportStrategy(jsonStrategy: json),
      ExportFormat.yolo => YoloExportStrategy(),
      ExportFormat.coco => CocoExportStrategy(),
      ExportFormat.voc => VocExportStrategy(),
      ExportFormat.labelStudio => LabelStudioExportStrategy(),
      ExportFormat.cvat => CvatExportStrategy(),
      ExportFormat.roboflow => RoboflowExportStrategy(),
    };
  }
}
