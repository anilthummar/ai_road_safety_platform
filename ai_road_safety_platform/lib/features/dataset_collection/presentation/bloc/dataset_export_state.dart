import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset export presentation states (Phase 12.8).
sealed class DatasetExportState extends Equatable {
  const DatasetExportState();

  @override
  List<Object?> get props => [];
}

/// Idle with draft settings.
final class DatasetExportInitial extends DatasetExportState {
  final ExportSettings settings;
  final List<ExportHistoryEntry> history;

  /// Creates [DatasetExportInitial].
  const DatasetExportInitial({
    this.settings = const ExportSettings(),
    this.history = const [],
  });

  @override
  List<Object?> get props => [settings, history];
}

/// Preparing folders / validation.
final class DatasetExportPreparing extends DatasetExportState {
  final ExportSettings settings;
  final ExportProgress progress;

  /// Creates [DatasetExportPreparing].
  const DatasetExportPreparing({
    required this.settings,
    required this.progress,
  });

  @override
  List<Object?> get props => [settings, progress];
}

/// Actively exporting.
final class DatasetExportExporting extends DatasetExportState {
  final ExportSettings settings;
  final ExportProgress progress;

  /// Creates [DatasetExportExporting].
  const DatasetExportExporting({
    required this.settings,
    required this.progress,
  });

  @override
  List<Object?> get props => [settings, progress];
}

/// Compressing ZIP.
final class DatasetExportCompressing extends DatasetExportState {
  final ExportSettings settings;
  final ExportProgress progress;

  /// Creates [DatasetExportCompressing].
  const DatasetExportCompressing({
    required this.settings,
    required this.progress,
  });

  @override
  List<Object?> get props => [settings, progress];
}

/// Success.
final class DatasetExportCompleted extends DatasetExportState {
  final ExportResult result;
  final List<ExportHistoryEntry> history;
  final ExportValidation? validation;

  /// Creates [DatasetExportCompleted].
  const DatasetExportCompleted({
    required this.result,
    this.history = const [],
    this.validation,
  });

  @override
  List<Object?> get props => [result, history, validation];
}

/// Failure.
final class DatasetExportFailed extends DatasetExportState {
  final Failure failure;
  final ExportSettings settings;
  final ExportProgress? progress;

  /// Creates [DatasetExportFailed].
  const DatasetExportFailed({
    required this.failure,
    required this.settings,
    this.progress,
  });

  @override
  List<Object?> get props => [failure, settings, progress];
}
