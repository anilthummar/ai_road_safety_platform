import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_deployment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ModelDeploymentEngine();

  test('validateForStage requires artifact path', () {
    final now = DateTime.utc(2026, 7, 14);
    final issues = engine.validateForStage(
      RegisteredModel(
        id: 'm',
        name: 'M',
        version: '1',
        taskType: ModelTaskType.objectDetection,
        status: ModelStatus.registered,
        createdAt: now,
        updatedAt: now,
        artifacts: const [
          ModelArtifact(
            id: 'a',
            fileName: 'x.tflite',
            source: ModelArtifactSource.localFile,
          ),
        ],
      ),
    );
    expect(issues, isNotEmpty);
  });

  test('setActivePointer updates detection id', () {
    final now = DateTime.utc(2026, 7, 14);
    final next = engine.setActivePointer(
      current: ActiveDeploymentPointers(updatedAt: now),
      taskType: ModelTaskType.objectDetection,
      deploymentId: 'd1',
      now: now,
    );
    expect(next.detectionDeploymentId, 'd1');
  });

  test('resolve prefers filesystem package over asset', () {
    final now = DateTime.utc(2026, 7, 14);
    final pkg = DeploymentPackage(
      id: 'd1',
      modelId: 'bundled-yolov8n',
      modelVersion: '1.0.0',
      displayName: 'YOLO',
      taskType: ModelTaskType.objectDetection,
      status: DeploymentStatus.active,
      createdAt: now,
      artifacts: const [
        DeploymentArtifact(
          fileName: 'yolov8n.tflite',
          absolutePath: '/tmp/yolov8n.tflite',
          sourceAssetPath: 'assets/models/yolov8n.tflite',
        ),
      ],
    );
    final snap = DeploymentSnapshot(
      packages: [pkg],
      active: ActiveDeploymentPointers(
        detectionDeploymentId: 'd1',
        updatedAt: now,
      ),
      generatedAt: now,
    );
    final res = engine.resolve(
      taskType: ModelTaskType.objectDetection,
      snapshot: snap,
      fallbackAssetPath: 'assets/models/yolov8n.tflite',
    );
    expect(res.filesystemPath, '/tmp/yolov8n.tflite');
    expect(res.usesBundledAsset, isFalse);
  });

  test('DeploymentPackage json round-trip', () {
    final pkg = DeploymentPackage(
      id: 'd1',
      modelId: 'm1',
      modelVersion: '1.0.0',
      displayName: 'M',
      taskType: ModelTaskType.semanticSegmentation,
      status: DeploymentStatus.staged,
      createdAt: DateTime.utc(2026, 7, 14),
      artifacts: const [
        DeploymentArtifact(
          fileName: 'flood.tflite',
          sourceAssetPath: 'assets/models/flood_seg.tflite',
        ),
      ],
    );
    expect(DeploymentPackage.fromJson(pkg.toJson()), pkg);
  });
}
