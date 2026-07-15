import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';

/// Dataset quality assessment & training gate repository.
abstract class DatasetQualityRepository {
  /// Runs a full corpus quality assessment.
  Future<Result<DatasetQualityAssessmentReport>> assessDataset({
    QualityGateThresholds thresholds = QualityGateThresholds.defaults,
    String? sessionId,
  });

  /// Evaluates gate decision for an existing / last report.
  Future<Result<QualityGateDecision>> evaluateGate({
    required DatasetQualityAssessmentReport report,
    QualityGateThresholds? thresholds,
  });

  /// Loads last persisted assessment (if any).
  Future<Result<DatasetQualityAssessmentReport?>> loadLastReport();

  /// Persists [report] as the latest assessment snapshot.
  Future<Result<void>> saveReport(DatasetQualityAssessmentReport report);

  /// Returns / updates gate thresholds.
  Future<Result<QualityGateThresholds>> getThresholds();

  Future<Result<QualityGateThresholds>> updateThresholds(
    QualityGateThresholds thresholds,
  );
}
