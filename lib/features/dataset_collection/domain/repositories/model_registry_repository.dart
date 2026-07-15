import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';

/// Local AI model version / artifact / metadata registry.
abstract class ModelRegistryRepository {
  Future<Result<ModelRegistrySnapshot>> loadRegistry();

  Future<Result<RegisteredModel>> getModel(String modelId);

  Future<Result<RegisteredModel>> registerModel(RegisteredModel model);

  Future<Result<RegisteredModel>> updateModel(RegisteredModel model);

  Future<Result<void>> deleteModel(String modelId);

  Future<Result<RegisteredModel>> activateModel(String modelId);

  Future<Result<RegisteredModel>> archiveModel(String modelId);

  Future<Result<ActiveModelPointers>> getActivePointers();

  /// Registers a local `.tflite` (+ optional labels) as a new version.
  Future<Result<RegisteredModel>> importLocalArtifact({
    required String name,
    required String version,
    required ModelTaskType taskType,
    required String tfliteSourcePath,
    String? labelsSourcePath,
    String? description,
  });

  /// Ensures bundled catalog models exist in the registry.
  Future<Result<ModelRegistrySnapshot>> seedBundledModels();
}
