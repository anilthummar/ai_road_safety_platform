import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';

/// Validation / packaging helpers for edge deployments (Phase 13.6).
class ModelDeploymentEngine {
  const ModelDeploymentEngine();

  List<String> validateForStage(RegisteredModel model) {
    final issues = <String>[];
    if (model.id.trim().isEmpty) issues.add('Model id is required');
    if (model.artifacts.isEmpty) {
      issues.add('Model has no artifacts');
      return issues;
    }
    ModelArtifact? primary;
    for (final a in model.artifacts) {
      if (a.fileName.endsWith('.tflite') || a.mimeHint.contains('tflite')) {
        primary = a;
        break;
      }
    }
    primary ??= model.artifacts.first;
    if ((primary.absolutePath == null || primary.absolutePath!.isEmpty) &&
        (primary.assetPath == null || primary.assetPath!.isEmpty)) {
      issues.add('Artifact has no path to package');
    }
    return issues;
  }

  List<String> validatePackage(DeploymentPackage package) {
    final issues = <String>[];
    if (package.id.trim().isEmpty) issues.add('Deployment id is required');
    if (package.modelId.trim().isEmpty) issues.add('Model id is required');
    if (package.artifacts.isEmpty) issues.add('Package has no artifacts');
    return issues;
  }

  ActiveDeploymentPointers setActivePointer({
    required ActiveDeploymentPointers current,
    required ModelTaskType taskType,
    required String deploymentId,
    required DateTime now,
  }) {
    return switch (taskType) {
      ModelTaskType.objectDetection => current.copyWith(
          detectionDeploymentId: deploymentId,
          updatedAt: now,
        ),
      ModelTaskType.semanticSegmentation => current.copyWith(
          segmentationDeploymentId: deploymentId,
          updatedAt: now,
        ),
      ModelTaskType.classification => current.copyWith(
          classificationDeploymentId: deploymentId,
          updatedAt: now,
        ),
      ModelTaskType.unknown => current.copyWith(updatedAt: now),
    };
  }

  DeployedModelResolution resolve({
    required ModelTaskType taskType,
    required DeploymentSnapshot snapshot,
    String? fallbackAssetPath,
  }) {
    final activeId = snapshot.active.idForTask(taskType);
    if (activeId != null) {
      final pkg = snapshot.packageById(activeId);
      if (pkg != null && pkg.status == DeploymentStatus.active) {
        final art = pkg.primaryModelArtifact;
        final fs = art?.absolutePath;
        final asset = art?.sourceAssetPath ?? fallbackAssetPath;
        final hasFs = fs != null && fs.isNotEmpty;
        return DeployedModelResolution(
          taskType: taskType,
          deploymentId: pkg.id,
          modelId: pkg.modelId,
          filesystemPath: hasFs ? fs : null,
          assetPath: asset,
          usesBundledAsset: !hasFs,
        );
      }
    }
    return DeployedModelResolution(
      taskType: taskType,
      usesBundledAsset: true,
      assetPath: fallbackAssetPath,
    );
  }
}
