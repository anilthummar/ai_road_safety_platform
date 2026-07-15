import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:equatable/equatable.dart';

sealed class PipelineState extends Equatable {
  const PipelineState();
  @override
  List<Object?> get props => [];
}

final class PipelineInitial extends PipelineState {
  const PipelineInitial();
}

final class PipelineRunning extends PipelineState {
  final PipelineMonitorSnapshot monitor;
  final List<PipelineTask> history;
  final PipelineTask? lastTask;
  final String? message;

  const PipelineRunning({
    required this.monitor,
    required this.history,
    this.lastTask,
    this.message,
  });

  @override
  List<Object?> get props => [monitor, history, lastTask, message];
}

final class PipelinePausedState extends PipelineState {
  final PipelineMonitorSnapshot monitor;
  final List<PipelineTask> history;

  const PipelinePausedState({
    required this.monitor,
    required this.history,
  });

  @override
  List<Object?> get props => [monitor, history];
}

final class PipelineStoppedState extends PipelineState {
  final PipelineMonitorSnapshot monitor;
  final List<PipelineTask> history;

  const PipelineStoppedState({
    required this.monitor,
    required this.history,
  });

  @override
  List<Object?> get props => [monitor, history];
}

final class PipelineTaskExecuting extends PipelineState {
  final PipelineMonitorSnapshot monitor;
  final List<PipelineTask> history;
  final PipelineTask task;

  const PipelineTaskExecuting({
    required this.monitor,
    required this.history,
    required this.task,
  });

  @override
  List<Object?> get props => [monitor, history, task];
}

final class PipelineTaskCompletedState extends PipelineState {
  final PipelineMonitorSnapshot monitor;
  final List<PipelineTask> history;
  final PipelineTask task;

  const PipelineTaskCompletedState({
    required this.monitor,
    required this.history,
    required this.task,
  });

  @override
  List<Object?> get props => [monitor, history, task];
}

final class PipelineFailure extends PipelineState {
  final Failure failure;
  final PipelineMonitorSnapshot? monitor;
  final List<PipelineTask> history;

  const PipelineFailure({
    required this.failure,
    this.monitor,
    this.history = const [],
  });

  @override
  List<Object?> get props => [failure, monitor, history];
}
