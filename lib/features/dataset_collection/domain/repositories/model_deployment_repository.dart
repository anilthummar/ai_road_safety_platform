import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';

/// Edge deployment packaging, activate, and rollback (Phase 13.6).
abstract class ModelDeploymentRepository {
  Future<Result<DeploymentSnapshot>> loadSnapshot();

  Future<Result<DeploymentPackage>> getPackage(String deploymentId);

  /// Stage a package from a registry model (copies artifacts when on disk).
  Future<Result<DeploymentPackage>> stageFromModel(String modelId);

  Future<Result<DeploymentPackage>> activateDeployment(String deploymentId);

  /// Roll back the task family of [deploymentId] to its previous package.
  Future<Result<DeploymentPackage>> rollbackDeployment(String deploymentId);

  Future<Result<void>> deletePackage(String deploymentId);

  Future<Result<ActiveDeploymentPointers>> getActivePointers();

  Future<Result<DeployedModelResolution>> resolveActiveModel(
    ModelTaskType taskType, {
    String? fallbackAssetPath,
  });

  Future<Result<DeploymentPackage>> createDemoPackage();
}
