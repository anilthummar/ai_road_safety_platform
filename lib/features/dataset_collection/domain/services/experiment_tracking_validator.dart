import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';

/// Validation issues for experiment runs / params / metrics.
class ExperimentValidationIssue {
  final String code;
  final String message;

  const ExperimentValidationIssue({required this.code, required this.message});
}

/// Validates run metadata and log payloads before persist.
class ExperimentTrackingValidator {
  const ExperimentTrackingValidator();

  List<ExperimentValidationIssue> validateRun(ExperimentRun run) {
    final issues = <ExperimentValidationIssue>[];
    if (run.id.trim().isEmpty) {
      issues.add(
        const ExperimentValidationIssue(
          code: 'missing_id',
          message: 'Run id is required',
        ),
      );
    }
    if (run.name.trim().isEmpty) {
      issues.add(
        const ExperimentValidationIssue(
          code: 'missing_name',
          message: 'Run name is required',
        ),
      );
    }
    if (run.experimentName.trim().isEmpty) {
      issues.add(
        const ExperimentValidationIssue(
          code: 'missing_experiment',
          message: 'Experiment name is required',
        ),
      );
    }
    for (final key in run.params.keys) {
      if (key.trim().isEmpty) {
        issues.add(
          const ExperimentValidationIssue(
            code: 'empty_param_key',
            message: 'Param keys must be non-empty',
          ),
        );
        break;
      }
    }
    for (final key in run.metrics.keys) {
      if (key.trim().isEmpty) {
        issues.add(
          const ExperimentValidationIssue(
            code: 'empty_metric_key',
            message: 'Metric keys must be non-empty',
          ),
        );
        break;
      }
    }
    return issues;
  }

  List<ExperimentValidationIssue> validateParams(Map<String, String> params) {
    final issues = <ExperimentValidationIssue>[];
    if (params.isEmpty) {
      issues.add(
        const ExperimentValidationIssue(
          code: 'empty_params',
          message: 'At least one param is required',
        ),
      );
    }
    for (final e in params.entries) {
      if (e.key.trim().isEmpty) {
        issues.add(
          const ExperimentValidationIssue(
            code: 'empty_param_key',
            message: 'Param keys must be non-empty',
          ),
        );
      }
    }
    return issues;
  }

  List<ExperimentValidationIssue> validateMetric({
    required String key,
    required double value,
  }) {
    final issues = <ExperimentValidationIssue>[];
    if (key.trim().isEmpty) {
      issues.add(
        const ExperimentValidationIssue(
          code: 'empty_metric_key',
          message: 'Metric key is required',
        ),
      );
    }
    if (value.isNaN || value.isInfinite) {
      issues.add(
        const ExperimentValidationIssue(
          code: 'invalid_metric_value',
          message: 'Metric value must be finite',
        ),
      );
    }
    return issues;
  }
}
