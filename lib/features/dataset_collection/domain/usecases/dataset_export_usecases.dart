import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_export_repository.dart';
import 'package:equatable/equatable.dart';

/// Params for full dataset export.
class ExportDatasetParams extends Equatable {
  final ExportSettings settings;
  final ExportProgressCallback? onProgress;

  /// Creates [ExportDatasetParams].
  const ExportDatasetParams({
    required this.settings,
    this.onProgress,
  });

  @override
  List<Object?> get props => [settings];
}

/// Export entire filtered dataset.
class ExportDatasetUseCase
    extends UseCase<Result<ExportResult>, ExportDatasetParams> {
  final DatasetExportRepository _repository;

  /// Creates [ExportDatasetUseCase].
  ExportDatasetUseCase(this._repository);

  @override
  Future<Result<ExportResult>> call(ExportDatasetParams params) {
    return _repository.exportDataset(
      params.settings,
      onProgress: params.onProgress,
    );
  }
}

/// Params for single-session export.
class ExportSessionParams extends Equatable {
  final String sessionId;
  final ExportSettings settings;
  final ExportProgressCallback? onProgress;

  /// Creates [ExportSessionParams].
  const ExportSessionParams({
    required this.sessionId,
    required this.settings,
    this.onProgress,
  });

  @override
  List<Object?> get props => [sessionId, settings];
}

/// Export one session.
class ExportSessionUseCase
    extends UseCase<Result<ExportResult>, ExportSessionParams> {
  final DatasetExportRepository _repository;

  /// Creates [ExportSessionUseCase].
  ExportSessionUseCase(this._repository);

  @override
  Future<Result<ExportResult>> call(ExportSessionParams params) {
    return _repository.exportSession(
      params.sessionId,
      params.settings,
      onProgress: params.onProgress,
    );
  }
}

/// Generate manifest for a folder.
class GenerateManifestUseCase
    extends UseCase<Result<ExportManifest>, String> {
  final DatasetExportRepository _repository;

  /// Creates [GenerateManifestUseCase].
  GenerateManifestUseCase(this._repository);

  @override
  Future<Result<ExportManifest>> call(String params) {
    return _repository.generateManifest(params);
  }
}

/// Generate README for a folder.
class GenerateReadmeUseCase extends UseCase<Result<String>, String> {
  final DatasetExportRepository _repository;

  /// Creates [GenerateReadmeUseCase].
  GenerateReadmeUseCase(this._repository);

  @override
  Future<Result<String>> call(String params) {
    return _repository.generateReadme(params);
  }
}

/// Compress export folder to ZIP.
class CompressDatasetUseCase extends UseCase<Result<String>, String> {
  final DatasetExportRepository _repository;

  /// Creates [CompressDatasetUseCase].
  CompressDatasetUseCase(this._repository);

  @override
  Future<Result<String>> call(String params) {
    return _repository.compressDataset(params);
  }
}

/// Validate export package.
class ValidateExportUseCase
    extends UseCase<Result<ExportValidation>, String> {
  final DatasetExportRepository _repository;

  /// Creates [ValidateExportUseCase].
  ValidateExportUseCase(this._repository);

  @override
  Future<Result<ExportValidation>> call(String params) {
    return _repository.validateExport(params);
  }
}
