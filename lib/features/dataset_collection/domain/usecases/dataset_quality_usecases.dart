import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_quality_repository.dart';
import 'package:equatable/equatable.dart';

class AssessDatasetParams extends Equatable {
  final QualityGateThresholds thresholds;
  final String? sessionId;

  const AssessDatasetParams({
    this.thresholds = QualityGateThresholds.defaults,
    this.sessionId,
  });

  @override
  List<Object?> get props => [thresholds, sessionId];
}

class AssessDatasetQualityUseCase
    extends UseCase<Result<DatasetQualityAssessmentReport>, AssessDatasetParams> {
  final DatasetQualityRepository _repository;
  AssessDatasetQualityUseCase(this._repository);

  @override
  Future<Result<DatasetQualityAssessmentReport>> call(
    AssessDatasetParams params,
  ) =>
      _repository.assessDataset(
        thresholds: params.thresholds,
        sessionId: params.sessionId,
      );
}

class EvaluateQualityGateParams extends Equatable {
  final DatasetQualityAssessmentReport report;
  final QualityGateThresholds? thresholds;

  const EvaluateQualityGateParams({
    required this.report,
    this.thresholds,
  });

  @override
  List<Object?> get props => [report, thresholds];
}

class EvaluateQualityGateUseCase
    extends UseCase<Result<QualityGateDecision>, EvaluateQualityGateParams> {
  final DatasetQualityRepository _repository;
  EvaluateQualityGateUseCase(this._repository);

  @override
  Future<Result<QualityGateDecision>> call(
    EvaluateQualityGateParams params,
  ) =>
      _repository.evaluateGate(
        report: params.report,
        thresholds: params.thresholds,
      );
}

class LoadLastQualityReportUseCase
    extends UseCase<Result<DatasetQualityAssessmentReport?>, NoParams> {
  final DatasetQualityRepository _repository;
  LoadLastQualityReportUseCase(this._repository);

  @override
  Future<Result<DatasetQualityAssessmentReport?>> call(NoParams params) =>
      _repository.loadLastReport();
}

class UpdateQualityThresholdsUseCase
    extends UseCase<Result<QualityGateThresholds>, QualityGateThresholds> {
  final DatasetQualityRepository _repository;
  UpdateQualityThresholdsUseCase(this._repository);

  @override
  Future<Result<QualityGateThresholds>> call(
    QualityGateThresholds params,
  ) =>
      _repository.updateThresholds(params);
}

class GetQualityThresholdsUseCase
    extends UseCase<Result<QualityGateThresholds>, NoParams> {
  final DatasetQualityRepository _repository;
  GetQualityThresholdsUseCase(this._repository);

  @override
  Future<Result<QualityGateThresholds>> call(NoParams params) =>
      _repository.getThresholds();
}
