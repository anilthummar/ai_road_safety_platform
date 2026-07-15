import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';

/// Local experiment tracking: runs, params, metrics (Phase 13.3).
abstract class ExperimentTrackingRepository {
  Future<Result<ExperimentTrackerSnapshot>> loadTracker();

  Future<Result<ExperimentRun>> getRun(String runId);

  Future<Result<ExperimentRun>> createRun({
    required String name,
    String experimentName,
    String? modelId,
    String? modelVersion,
    List<String> datasetSessionIds,
    Map<String, String> params,
    Map<String, String> tags,
    String notes,
    ExperimentRunSource source,
  });

  Future<Result<ExperimentRun>> startRun(String runId);

  Future<Result<ExperimentRun>> logParams({
    required String runId,
    required Map<String, String> params,
  });

  Future<Result<ExperimentRun>> logMetric({
    required String runId,
    required String key,
    required double value,
    int step,
  });

  Future<Result<ExperimentRun>> completeRun(String runId);

  Future<Result<ExperimentRun>> failRun(String runId, {String? notes});

  Future<Result<ExperimentRun>> cancelRun(String runId);

  Future<Result<void>> deleteRun(String runId);

  /// Seeds a finished demo run with sample params/metrics for UI / tests.
  Future<Result<ExperimentRun>> createDemoRun({
    String? modelId,
    String? modelVersion,
  });
}
