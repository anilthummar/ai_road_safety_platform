import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:equatable/equatable.dart';

sealed class PipelineEvent extends Equatable {
  const PipelineEvent();
  @override
  List<Object?> get props => [];
}

final class PipelineStarted extends PipelineEvent {
  const PipelineStarted();
}

final class PipelinePaused extends PipelineEvent {
  const PipelinePaused();
}

final class PipelineResumed extends PipelineEvent {
  const PipelineResumed();
}

final class PipelineStopped extends PipelineEvent {
  const PipelineStopped();
}

final class PipelineRestarted extends PipelineEvent {
  const PipelineRestarted();
}

final class PipelineRefreshMonitor extends PipelineEvent {
  const PipelineRefreshMonitor();
}

final class PipelineEnqueueDemoTask extends PipelineEvent {
  final PipelineStageKind stage;
  final TaskPriority priority;
  final bool forceFail;

  const PipelineEnqueueDemoTask({
    this.stage = PipelineStageKind.metadata,
    this.priority = TaskPriority.normal,
    this.forceFail = false,
  });

  @override
  List<Object?> get props => [stage, priority, forceFail];
}

final class PipelineTaskRetryRequested extends PipelineEvent {
  final String taskId;
  const PipelineTaskRetryRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

final class PipelineTaskCancelRequested extends PipelineEvent {
  final String taskId;
  const PipelineTaskCancelRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

final class PipelineRecoverFailed extends PipelineEvent {
  const PipelineRecoverFailed();
}
