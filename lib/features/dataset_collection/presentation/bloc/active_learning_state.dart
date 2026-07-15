import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ActiveLearningState extends Equatable {
  const ActiveLearningState();
  @override
  List<Object?> get props => [];
}

class ActiveLearningInitial extends ActiveLearningState {
  const ActiveLearningInitial();
}

class ActiveLearningLoading extends ActiveLearningState {
  final String? message;
  const ActiveLearningLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class ActiveLearningLoaded extends ActiveLearningState {
  final ActiveLearningSnapshot snapshot;
  final String? statusMessage;

  const ActiveLearningLoaded({
    required this.snapshot,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [snapshot, statusMessage];
}

class ActiveLearningError extends ActiveLearningState {
  final Failure failure;
  final ActiveLearningSnapshot? snapshot;

  const ActiveLearningError({required this.failure, this.snapshot});

  @override
  List<Object?> get props => [failure, snapshot];
}
