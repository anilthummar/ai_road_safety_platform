import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_registry_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ModelRegistryValidator();

  test('bundled catalog has detection and segmentation', () {
    final models = BundledModelCatalog.defaults(
      now: DateTime.utc(2026, 7, 14),
    );
    expect(models.length, 2);
    expect(models.any((m) => m.taskType == ModelTaskType.objectDetection), isTrue);
    expect(
      models.any((m) => m.taskType == ModelTaskType.semanticSegmentation),
      isTrue,
    );
  });

  test('RegisteredModel json round-trip', () {
    final now = DateTime.utc(2026, 7, 14);
    final model = RegisteredModel(
      id: 'm1',
      name: 'Test',
      version: '1.2.3',
      taskType: ModelTaskType.classification,
      status: ModelStatus.registered,
      artifacts: const [
        ModelArtifact(
          id: 'a1',
          fileName: 'm.tflite',
          assetPath: 'assets/models/x.tflite',
          source: ModelArtifactSource.bundledAsset,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      tags: const {'k': 'v'},
    );
    expect(RegisteredModel.fromJson(model.toJson()), model);
  });

  test('validator catches missing artifact path', () {
    final now = DateTime.utc(2026, 7, 14);
    final issues = validator.validate(
      RegisteredModel(
        id: 'm',
        name: 'N',
        version: '1',
        taskType: ModelTaskType.unknown,
        status: ModelStatus.draft,
        artifacts: const [
          ModelArtifact(
            id: 'a',
            fileName: 'x.tflite',
            source: ModelArtifactSource.localFile,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(issues.any((i) => i.code == 'artifact_path'), isTrue);
  });

  test('ActiveModelPointers json round-trip', () {
    final p = ActiveModelPointers(
      detectionModelId: 'd1',
      segmentationModelId: 's1',
      updatedAt: DateTime.utc(2026, 7, 14),
    );
    expect(ActiveModelPointers.fromJson(p.toJson()), p);
  });
}
