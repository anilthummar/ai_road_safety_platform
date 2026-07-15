import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_benchmark_repository.dart';
import 'package:equatable/equatable.dart';

class LoadBenchmarkSnapshotUseCase
    extends UseCase<Result<BenchmarkSnapshot>, NoParams> {
  final ModelBenchmarkRepository _repository;
  LoadBenchmarkSnapshotUseCase(this._repository);

  @override
  Future<Result<BenchmarkSnapshot>> call(NoParams params) =>
      _repository.loadSnapshot();
}

class RunBenchmarkParams extends Equatable {
  final String modelId;
  final List<String> sessionIds;
  final String? experimentRunId;
  final double iouThreshold;
  final String? modelVersion;

  const RunBenchmarkParams({
    required this.modelId,
    this.sessionIds = const [],
    this.experimentRunId,
    this.iouThreshold = 0.5,
    this.modelVersion,
  });

  @override
  List<Object?> get props =>
      [modelId, sessionIds, experimentRunId, iouThreshold, modelVersion];
}

class RunBenchmarkUseCase
    extends UseCase<Result<BenchmarkReport>, RunBenchmarkParams> {
  final ModelBenchmarkRepository _repository;
  RunBenchmarkUseCase(this._repository);

  @override
  Future<Result<BenchmarkReport>> call(RunBenchmarkParams params) =>
      _repository.runBenchmark(
        modelId: params.modelId,
        sessionIds: params.sessionIds,
        experimentRunId: params.experimentRunId,
        iouThreshold: params.iouThreshold,
        modelVersion: params.modelVersion,
      );
}

class DeleteBenchmarkReportParams extends Equatable {
  final String reportId;
  const DeleteBenchmarkReportParams(this.reportId);
  @override
  List<Object?> get props => [reportId];
}

class DeleteBenchmarkReportUseCase
    extends UseCase<Result<void>, DeleteBenchmarkReportParams> {
  final ModelBenchmarkRepository _repository;
  DeleteBenchmarkReportUseCase(this._repository);

  @override
  Future<Result<void>> call(DeleteBenchmarkReportParams params) =>
      _repository.deleteReport(params.reportId);
}

class CreateDemoBenchmarkParams extends Equatable {
  final String modelId;
  final String? modelVersion;
  final String? experimentRunId;

  const CreateDemoBenchmarkParams({
    this.modelId = 'bundled-yolov8n',
    this.modelVersion,
    this.experimentRunId,
  });

  @override
  List<Object?> get props => [modelId, modelVersion, experimentRunId];
}

class CreateDemoBenchmarkUseCase
    extends UseCase<Result<BenchmarkReport>, CreateDemoBenchmarkParams> {
  final ModelBenchmarkRepository _repository;
  CreateDemoBenchmarkUseCase(this._repository);

  @override
  Future<Result<BenchmarkReport>> call(CreateDemoBenchmarkParams params) =>
      _repository.createDemoReport(
        modelId: params.modelId,
        modelVersion: params.modelVersion,
        experimentRunId: params.experimentRunId,
      );
}
