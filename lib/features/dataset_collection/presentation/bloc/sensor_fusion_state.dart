import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:equatable/equatable.dart';

sealed class SensorFusionState extends Equatable {
  const SensorFusionState();
  @override
  List<Object?> get props => [];
}

class SensorFusionInitial extends SensorFusionState {
  const SensorFusionInitial();
}

class SensorFusionLoading extends SensorFusionState {
  final String? message;
  const SensorFusionLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class SensorFusionLoaded extends SensorFusionState {
  final SensorFusionSnapshot snapshot;
  final String? statusMessage;

  const SensorFusionLoaded({
    required this.snapshot,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [snapshot, statusMessage];
}

class SensorFusionError extends SensorFusionState {
  final Failure failure;
  final SensorFusionSnapshot? snapshot;

  const SensorFusionError({required this.failure, this.snapshot});

  @override
  List<Object?> get props => [failure, snapshot];
}
