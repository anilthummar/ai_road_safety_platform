import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset export Bloc events (Phase 12.8).
sealed class DatasetExportEvent extends Equatable {
  const DatasetExportEvent();

  @override
  List<Object?> get props => [];
}

/// Full dataset export.
final class DatasetExportRequested extends DatasetExportEvent {
  final ExportSettings settings;

  /// Creates [DatasetExportRequested].
  const DatasetExportRequested(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// Single session export.
final class DatasetExportSessionRequested extends DatasetExportEvent {
  final String sessionId;
  final ExportSettings settings;

  /// Creates [DatasetExportSessionRequested].
  const DatasetExportSessionRequested({
    required this.sessionId,
    required this.settings,
  });

  @override
  List<Object?> get props => [sessionId, settings];
}

/// Regenerate manifest for a folder.
final class DatasetExportGenerateManifest extends DatasetExportEvent {
  final String exportFolderPath;

  /// Creates [DatasetExportGenerateManifest].
  const DatasetExportGenerateManifest(this.exportFolderPath);

  @override
  List<Object?> get props => [exportFolderPath];
}

/// Regenerate README for a folder.
final class DatasetExportGenerateReadme extends DatasetExportEvent {
  final String exportFolderPath;

  /// Creates [DatasetExportGenerateReadme].
  const DatasetExportGenerateReadme(this.exportFolderPath);

  @override
  List<Object?> get props => [exportFolderPath];
}

/// Compress existing folder.
final class DatasetExportCompress extends DatasetExportEvent {
  final String exportFolderPath;

  /// Creates [DatasetExportCompress].
  const DatasetExportCompress(this.exportFolderPath);

  @override
  List<Object?> get props => [exportFolderPath];
}

/// Validate package.
final class DatasetExportValidate extends DatasetExportEvent {
  final String exportFolderPath;

  /// Creates [DatasetExportValidate].
  const DatasetExportValidate(this.exportFolderPath);

  @override
  List<Object?> get props => [exportFolderPath];
}

/// Load history list.
final class DatasetExportLoadHistory extends DatasetExportEvent {
  const DatasetExportLoadHistory();
}

/// Update draft settings in UI without exporting.
final class DatasetExportUpdateSettings extends DatasetExportEvent {
  final ExportSettings settings;

  /// Creates [DatasetExportUpdateSettings].
  const DatasetExportUpdateSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}
