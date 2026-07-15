import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ModelRegistryState extends Equatable {
  const ModelRegistryState();
  @override
  List<Object?> get props => [];
}

final class ModelRegistryInitial extends ModelRegistryState {
  const ModelRegistryInitial();
}

final class ModelRegistryLoading extends ModelRegistryState {
  final String message;
  const ModelRegistryLoading({this.message = 'Loading model registry…'});
  @override
  List<Object?> get props => [message];
}

final class ModelRegistryLoaded extends ModelRegistryState {
  final ModelRegistrySnapshot snapshot;
  final String? statusMessage;

  const ModelRegistryLoaded({
    required this.snapshot,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [snapshot, statusMessage];
}

final class ModelRegistryError extends ModelRegistryState {
  final Failure failure;
  final ModelRegistrySnapshot? snapshot;

  const ModelRegistryError({required this.failure, this.snapshot});

  @override
  List<Object?> get props => [failure, snapshot];
}
