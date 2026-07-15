import 'package:equatable/equatable.dart';

sealed class ModelDeploymentEvent extends Equatable {
  const ModelDeploymentEvent();
  @override
  List<Object?> get props => [];
}

class ModelDeploymentLoad extends ModelDeploymentEvent {
  const ModelDeploymentLoad();
}

class ModelDeploymentRefresh extends ModelDeploymentEvent {
  const ModelDeploymentRefresh();
}

class ModelDeploymentStage extends ModelDeploymentEvent {
  final String modelId;
  const ModelDeploymentStage(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

class ModelDeploymentActivate extends ModelDeploymentEvent {
  final String deploymentId;
  const ModelDeploymentActivate(this.deploymentId);
  @override
  List<Object?> get props => [deploymentId];
}

class ModelDeploymentRollback extends ModelDeploymentEvent {
  final String deploymentId;
  const ModelDeploymentRollback(this.deploymentId);
  @override
  List<Object?> get props => [deploymentId];
}

class ModelDeploymentDelete extends ModelDeploymentEvent {
  final String deploymentId;
  const ModelDeploymentDelete(this.deploymentId);
  @override
  List<Object?> get props => [deploymentId];
}

class ModelDeploymentCreateDemo extends ModelDeploymentEvent {
  const ModelDeploymentCreateDemo();
}

class ModelDeploymentStageActiveDetection extends ModelDeploymentEvent {
  const ModelDeploymentStageActiveDetection();
}
