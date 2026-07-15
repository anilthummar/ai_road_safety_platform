import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_deployment_repository.dart';
import 'package:equatable/equatable.dart';

class LoadDeploymentSnapshotUseCase
    extends UseCase<Result<DeploymentSnapshot>, NoParams> {
  final ModelDeploymentRepository _repository;
  LoadDeploymentSnapshotUseCase(this._repository);

  @override
  Future<Result<DeploymentSnapshot>> call(NoParams params) =>
      _repository.loadSnapshot();
}

class StageDeploymentParams extends Equatable {
  final String modelId;
  const StageDeploymentParams(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

class StageDeploymentUseCase
    extends UseCase<Result<DeploymentPackage>, StageDeploymentParams> {
  final ModelDeploymentRepository _repository;
  StageDeploymentUseCase(this._repository);

  @override
  Future<Result<DeploymentPackage>> call(StageDeploymentParams params) =>
      _repository.stageFromModel(params.modelId);
}

class DeploymentIdParams extends Equatable {
  final String deploymentId;
  const DeploymentIdParams(this.deploymentId);
  @override
  List<Object?> get props => [deploymentId];
}

class ActivateDeploymentUseCase
    extends UseCase<Result<DeploymentPackage>, DeploymentIdParams> {
  final ModelDeploymentRepository _repository;
  ActivateDeploymentUseCase(this._repository);

  @override
  Future<Result<DeploymentPackage>> call(DeploymentIdParams params) =>
      _repository.activateDeployment(params.deploymentId);
}

class RollbackDeploymentUseCase
    extends UseCase<Result<DeploymentPackage>, DeploymentIdParams> {
  final ModelDeploymentRepository _repository;
  RollbackDeploymentUseCase(this._repository);

  @override
  Future<Result<DeploymentPackage>> call(DeploymentIdParams params) =>
      _repository.rollbackDeployment(params.deploymentId);
}

class DeleteDeploymentUseCase
    extends UseCase<Result<void>, DeploymentIdParams> {
  final ModelDeploymentRepository _repository;
  DeleteDeploymentUseCase(this._repository);

  @override
  Future<Result<void>> call(DeploymentIdParams params) =>
      _repository.deletePackage(params.deploymentId);
}

class ResolveDeployedModelParams extends Equatable {
  final ModelTaskType taskType;
  final String? fallbackAssetPath;
  const ResolveDeployedModelParams(
    this.taskType, {
    this.fallbackAssetPath,
  });
  @override
  List<Object?> get props => [taskType, fallbackAssetPath];
}

class ResolveDeployedModelUseCase
    extends UseCase<Result<DeployedModelResolution>, ResolveDeployedModelParams> {
  final ModelDeploymentRepository _repository;
  ResolveDeployedModelUseCase(this._repository);

  @override
  Future<Result<DeployedModelResolution>> call(
    ResolveDeployedModelParams params,
  ) =>
      _repository.resolveActiveModel(
        params.taskType,
        fallbackAssetPath: params.fallbackAssetPath,
      );
}

class CreateDemoDeploymentUseCase
    extends UseCase<Result<DeploymentPackage>, NoParams> {
  final ModelDeploymentRepository _repository;
  CreateDemoDeploymentUseCase(this._repository);

  @override
  Future<Result<DeploymentPackage>> call(NoParams params) =>
      _repository.createDemoPackage();
}
