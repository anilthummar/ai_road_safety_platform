import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ModelRegistryEvent extends Equatable {
  const ModelRegistryEvent();
  @override
  List<Object?> get props => [];
}

final class ModelRegistryLoad extends ModelRegistryEvent {
  const ModelRegistryLoad();
}

final class ModelRegistryRefresh extends ModelRegistryEvent {
  const ModelRegistryRefresh();
}

final class ModelRegistryActivate extends ModelRegistryEvent {
  final String modelId;
  const ModelRegistryActivate(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

final class ModelRegistryArchive extends ModelRegistryEvent {
  final String modelId;
  const ModelRegistryArchive(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

final class ModelRegistryDelete extends ModelRegistryEvent {
  final String modelId;
  const ModelRegistryDelete(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

final class ModelRegistryRegisterDemo extends ModelRegistryEvent {
  final ModelTaskType taskType;
  const ModelRegistryRegisterDemo({
    this.taskType = ModelTaskType.classification,
  });
  @override
  List<Object?> get props => [taskType];
}

final class ModelRegistrySeedBundled extends ModelRegistryEvent {
  const ModelRegistrySeedBundled();
}
