import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/experiment_tracking_repository.dart';
import 'package:equatable/equatable.dart';

class LoadExperimentTrackerUseCase
    extends UseCase<Result<ExperimentTrackerSnapshot>, NoParams> {
  final ExperimentTrackingRepository _repository;
  LoadExperimentTrackerUseCase(this._repository);

  @override
  Future<Result<ExperimentTrackerSnapshot>> call(NoParams params) =>
      _repository.loadTracker();
}

class CreateExperimentRunParams extends Equatable {
  final String name;
  final String experimentName;
  final String? modelId;
  final String? modelVersion;
  final List<String> datasetSessionIds;
  final Map<String, String> params;
  final Map<String, String> tags;
  final String notes;

  const CreateExperimentRunParams({
    required this.name,
    this.experimentName = 'default',
    this.modelId,
    this.modelVersion,
    this.datasetSessionIds = const [],
    this.params = const {},
    this.tags = const {},
    this.notes = '',
  });

  @override
  List<Object?> get props => [
        name,
        experimentName,
        modelId,
        modelVersion,
        datasetSessionIds,
        params,
        tags,
        notes,
      ];
}

class CreateExperimentRunUseCase
    extends UseCase<Result<ExperimentRun>, CreateExperimentRunParams> {
  final ExperimentTrackingRepository _repository;
  CreateExperimentRunUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(CreateExperimentRunParams params) =>
      _repository.createRun(
        name: params.name,
        experimentName: params.experimentName,
        modelId: params.modelId,
        modelVersion: params.modelVersion,
        datasetSessionIds: params.datasetSessionIds,
        params: params.params,
        tags: params.tags,
        notes: params.notes,
      );
}

class ExperimentRunIdParams extends Equatable {
  final String runId;
  const ExperimentRunIdParams(this.runId);
  @override
  List<Object?> get props => [runId];
}

class StartExperimentRunUseCase
    extends UseCase<Result<ExperimentRun>, ExperimentRunIdParams> {
  final ExperimentTrackingRepository _repository;
  StartExperimentRunUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(ExperimentRunIdParams params) =>
      _repository.startRun(params.runId);
}

class LogExperimentParamsParams extends Equatable {
  final String runId;
  final Map<String, String> params;
  const LogExperimentParamsParams({
    required this.runId,
    required this.params,
  });
  @override
  List<Object?> get props => [runId, params];
}

class LogExperimentParamsUseCase
    extends UseCase<Result<ExperimentRun>, LogExperimentParamsParams> {
  final ExperimentTrackingRepository _repository;
  LogExperimentParamsUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(LogExperimentParamsParams params) =>
      _repository.logParams(runId: params.runId, params: params.params);
}

class LogExperimentMetricParams extends Equatable {
  final String runId;
  final String key;
  final double value;
  final int step;

  const LogExperimentMetricParams({
    required this.runId,
    required this.key,
    required this.value,
    this.step = 0,
  });

  @override
  List<Object?> get props => [runId, key, value, step];
}

class LogExperimentMetricUseCase
    extends UseCase<Result<ExperimentRun>, LogExperimentMetricParams> {
  final ExperimentTrackingRepository _repository;
  LogExperimentMetricUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(LogExperimentMetricParams params) =>
      _repository.logMetric(
        runId: params.runId,
        key: params.key,
        value: params.value,
        step: params.step,
      );
}

class CompleteExperimentRunUseCase
    extends UseCase<Result<ExperimentRun>, ExperimentRunIdParams> {
  final ExperimentTrackingRepository _repository;
  CompleteExperimentRunUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(ExperimentRunIdParams params) =>
      _repository.completeRun(params.runId);
}

class FailExperimentRunParams extends Equatable {
  final String runId;
  final String? notes;
  const FailExperimentRunParams(this.runId, {this.notes});
  @override
  List<Object?> get props => [runId, notes];
}

class FailExperimentRunUseCase
    extends UseCase<Result<ExperimentRun>, FailExperimentRunParams> {
  final ExperimentTrackingRepository _repository;
  FailExperimentRunUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(FailExperimentRunParams params) =>
      _repository.failRun(params.runId, notes: params.notes);
}

class CancelExperimentRunUseCase
    extends UseCase<Result<ExperimentRun>, ExperimentRunIdParams> {
  final ExperimentTrackingRepository _repository;
  CancelExperimentRunUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(ExperimentRunIdParams params) =>
      _repository.cancelRun(params.runId);
}

class DeleteExperimentRunUseCase
    extends UseCase<Result<void>, ExperimentRunIdParams> {
  final ExperimentTrackingRepository _repository;
  DeleteExperimentRunUseCase(this._repository);

  @override
  Future<Result<void>> call(ExperimentRunIdParams params) =>
      _repository.deleteRun(params.runId);
}

class CreateDemoExperimentRunUseCase
    extends UseCase<Result<ExperimentRun>, NoParams> {
  final ExperimentTrackingRepository _repository;
  CreateDemoExperimentRunUseCase(this._repository);

  @override
  Future<Result<ExperimentRun>> call(NoParams params) =>
      _repository.createDemoRun();
}
