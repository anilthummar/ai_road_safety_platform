import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ModelDeploymentState extends Equatable {
  const ModelDeploymentState();
  @override
  List<Object?> get props => [];
}

class ModelDeploymentInitial extends ModelDeploymentState {
  const ModelDeploymentInitial();
}

class ModelDeploymentLoading extends ModelDeploymentState {
  final String? message;
  const ModelDeploymentLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class ModelDeploymentLoaded extends ModelDeploymentState {
  final DeploymentSnapshot snapshot;
  final String? statusMessage;

  const ModelDeploymentLoaded({
    required this.snapshot,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [snapshot, statusMessage];
}

class ModelDeploymentError extends ModelDeploymentState {
  final Failure failure;
  final DeploymentSnapshot? snapshot;

  const ModelDeploymentError({required this.failure, this.snapshot});

  @override
  List<Object?> get props => [failure, snapshot];
}
