import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/pipeline_repository.dart';
import 'package:equatable/equatable.dart';

class StartPipelineUseCase
    extends UseCase<Result<PipelineMonitorSnapshot>, NoParams> {
  final PipelineRepository _repository;
  StartPipelineUseCase(this._repository);

  @override
  Future<Result<PipelineMonitorSnapshot>> call(NoParams params) =>
      _repository.startPipeline();
}

class PausePipelineUseCase
    extends UseCase<Result<PipelineMonitorSnapshot>, NoParams> {
  final PipelineRepository _repository;
  PausePipelineUseCase(this._repository);

  @override
  Future<Result<PipelineMonitorSnapshot>> call(NoParams params) =>
      _repository.pausePipeline();
}

class ResumePipelineUseCase
    extends UseCase<Result<PipelineMonitorSnapshot>, NoParams> {
  final PipelineRepository _repository;
  ResumePipelineUseCase(this._repository);

  @override
  Future<Result<PipelineMonitorSnapshot>> call(NoParams params) =>
      _repository.resumePipeline();
}

class StopPipelineUseCase
    extends UseCase<Result<PipelineMonitorSnapshot>, NoParams> {
  final PipelineRepository _repository;
  StopPipelineUseCase(this._repository);

  @override
  Future<Result<PipelineMonitorSnapshot>> call(NoParams params) =>
      _repository.stopPipeline();
}

class ExecutePipelineTaskUseCase
    extends UseCase<Result<PipelineTask>, PipelineTask> {
  final PipelineRepository _repository;
  ExecutePipelineTaskUseCase(this._repository);

  @override
  Future<Result<PipelineTask>> call(PipelineTask params) =>
      _repository.executeTask(params);
}

class RetryTaskParams extends Equatable {
  final String taskId;
  const RetryTaskParams(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class RetryTaskUseCase
    extends UseCase<Result<PipelineTask>, RetryTaskParams> {
  final PipelineRepository _repository;
  RetryTaskUseCase(this._repository);

  @override
  Future<Result<PipelineTask>> call(RetryTaskParams params) =>
      _repository.retryTask(params.taskId);
}

class CancelTaskParams extends Equatable {
  final String taskId;
  const CancelTaskParams(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class CancelTaskUseCase
    extends UseCase<Result<void>, CancelTaskParams> {
  final PipelineRepository _repository;
  CancelTaskUseCase(this._repository);

  @override
  Future<Result<void>> call(CancelTaskParams params) =>
      _repository.cancelTask(params.taskId);
}

class GetPipelineMonitorUseCase
    extends UseCase<Result<PipelineMonitorSnapshot>, NoParams> {
  final PipelineRepository _repository;
  GetPipelineMonitorUseCase(this._repository);

  @override
  Future<Result<PipelineMonitorSnapshot>> call(NoParams params) =>
      _repository.getMonitor();
}
