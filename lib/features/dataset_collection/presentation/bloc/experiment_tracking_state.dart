import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ExperimentTrackingState extends Equatable {
  const ExperimentTrackingState();
  @override
  List<Object?> get props => [];
}

class ExperimentTrackingInitial extends ExperimentTrackingState {
  const ExperimentTrackingInitial();
}

class ExperimentTrackingLoading extends ExperimentTrackingState {
  final String? message;
  const ExperimentTrackingLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class ExperimentTrackingLoaded extends ExperimentTrackingState {
  final ExperimentTrackerSnapshot snapshot;
  final String? statusMessage;

  const ExperimentTrackingLoaded({
    required this.snapshot,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [snapshot, statusMessage];
}

class ExperimentTrackingError extends ExperimentTrackingState {
  final Failure failure;
  final ExperimentTrackerSnapshot? snapshot;

  const ExperimentTrackingError({required this.failure, this.snapshot});

  @override
  List<Object?> get props => [failure, snapshot];
}
