import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/experiment_tracking_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ExperimentTrackingValidator();

  test('ExperimentRun json round-trip', () {
    final now = DateTime.utc(2026, 7, 14);
    final run = ExperimentRun(
      id: 'r1',
      name: 'Train A',
      experimentName: 'road-detection',
      status: ExperimentRunStatus.running,
      modelId: 'bundled-yolov8n',
      params: const {'epochs': '10', 'lr': '0.001'},
      metrics: const {'mAP50': 0.5},
      metricHistory: [
        ExperimentMetricPoint(
          key: 'mAP50',
          value: 0.5,
          step: 1,
          recordedAt: now,
        ),
      ],
      tags: const {'k': 'v'},
      createdAt: now,
      updatedAt: now,
      startedAt: now,
    );
    expect(ExperimentRun.fromJson(run.toJson()), run);
  });

  test('validator catches missing name', () {
    final issues = validator.validateRun(
      ExperimentRun(
        id: 'r',
        name: '  ',
        createdAt: DateTime.utc(2026, 7, 14),
        updatedAt: DateTime.utc(2026, 7, 14),
      ),
    );
    expect(issues.any((i) => i.code == 'missing_name'), isTrue);
  });

  test('validator rejects non-finite metric', () {
    final issues = validator.validateMetric(key: 'loss', value: double.nan);
    expect(issues.any((i) => i.code == 'invalid_metric_value'), isTrue);
  });

  test('snapshot counts by status', () {
    final now = DateTime.utc(2026, 7, 14);
    final snap = ExperimentTrackerSnapshot(
      runs: [
        ExperimentRun(
          id: '1',
          name: 'a',
          status: ExperimentRunStatus.running,
          createdAt: now,
          updatedAt: now,
        ),
        ExperimentRun(
          id: '2',
          name: 'b',
          status: ExperimentRunStatus.completed,
          createdAt: now,
          updatedAt: now,
        ),
        ExperimentRun(
          id: '3',
          name: 'c',
          status: ExperimentRunStatus.failed,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      generatedAt: now,
    );
    expect(snap.runningCount, 1);
    expect(snap.completedCount, 1);
    expect(snap.failedCount, 1);
  });
}
