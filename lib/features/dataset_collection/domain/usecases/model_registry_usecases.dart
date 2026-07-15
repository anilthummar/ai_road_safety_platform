import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:equatable/equatable.dart';

class LoadModelRegistryUseCase
    extends UseCase<Result<ModelRegistrySnapshot>, NoParams> {
  final ModelRegistryRepository _repository;
  LoadModelRegistryUseCase(this._repository);

  @override
  Future<Result<ModelRegistrySnapshot>> call(NoParams params) =>
      _repository.loadRegistry();
}

class RegisterModelUseCase
    extends UseCase<Result<RegisteredModel>, RegisteredModel> {
  final ModelRegistryRepository _repository;
  RegisterModelUseCase(this._repository);

  @override
  Future<Result<RegisteredModel>> call(RegisteredModel params) =>
      _repository.registerModel(params);
}

class UpdateModelUseCase
    extends UseCase<Result<RegisteredModel>, RegisteredModel> {
  final ModelRegistryRepository _repository;
  UpdateModelUseCase(this._repository);

  @override
  Future<Result<RegisteredModel>> call(RegisteredModel params) =>
      _repository.updateModel(params);
}

class DeleteModelParams extends Equatable {
  final String modelId;
  const DeleteModelParams(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

class DeleteModelUseCase
    extends UseCase<Result<void>, DeleteModelParams> {
  final ModelRegistryRepository _repository;
  DeleteModelUseCase(this._repository);

  @override
  Future<Result<void>> call(DeleteModelParams params) =>
      _repository.deleteModel(params.modelId);
}

class ActivateModelParams extends Equatable {
  final String modelId;
  const ActivateModelParams(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

class ActivateModelUseCase
    extends UseCase<Result<RegisteredModel>, ActivateModelParams> {
  final ModelRegistryRepository _repository;
  ActivateModelUseCase(this._repository);

  @override
  Future<Result<RegisteredModel>> call(ActivateModelParams params) =>
      _repository.activateModel(params.modelId);
}

class ArchiveModelUseCase
    extends UseCase<Result<RegisteredModel>, ActivateModelParams> {
  final ModelRegistryRepository _repository;
  ArchiveModelUseCase(this._repository);

  @override
  Future<Result<RegisteredModel>> call(ActivateModelParams params) =>
      _repository.archiveModel(params.modelId);
}

class ImportLocalModelParams extends Equatable {
  final String name;
  final String version;
  final ModelTaskType taskType;
  final String tfliteSourcePath;
  final String? labelsSourcePath;
  final String? description;

  const ImportLocalModelParams({
    required this.name,
    required this.version,
    required this.taskType,
    required this.tfliteSourcePath,
    this.labelsSourcePath,
    this.description,
  });

  @override
  List<Object?> get props =>
      [name, version, taskType, tfliteSourcePath, labelsSourcePath, description];
}

class ImportLocalModelUseCase
    extends UseCase<Result<RegisteredModel>, ImportLocalModelParams> {
  final ModelRegistryRepository _repository;
  ImportLocalModelUseCase(this._repository);

  @override
  Future<Result<RegisteredModel>> call(ImportLocalModelParams params) =>
      _repository.importLocalArtifact(
        name: params.name,
        version: params.version,
        taskType: params.taskType,
        tfliteSourcePath: params.tfliteSourcePath,
        labelsSourcePath: params.labelsSourcePath,
        description: params.description,
      );
}

class SeedBundledModelsUseCase
    extends UseCase<Result<ModelRegistrySnapshot>, NoParams> {
  final ModelRegistryRepository _repository;
  SeedBundledModelsUseCase(this._repository);

  @override
  Future<Result<ModelRegistrySnapshot>> call(NoParams params) =>
      _repository.seedBundledModels();
}
