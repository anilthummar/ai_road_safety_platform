import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exponential backoff increases then caps', () {
    const policy = RetryPolicy(
      maxRetries: 5,
      initialDelay: Duration(milliseconds: 100),
      backoffMultiplier: 2,
      maxDelay: Duration(milliseconds: 350),
    );
    expect(policy.delayForAttempt(1), const Duration(milliseconds: 100));
    expect(policy.delayForAttempt(2), const Duration(milliseconds: 200));
    expect(policy.delayForAttempt(3).inMilliseconds, lessThanOrEqualTo(350));
    expect(policy.delayForAttempt(4).inMilliseconds, 350);
  });

  test('disabled policy has zero retries', () {
    expect(RetryPolicy.disabled.maxRetries, 0);
  });

  test('PipelineTask json round-trip', () {
    final task = PipelineTask(
      id: 't1',
      stage: PipelineStageKind.storage,
      name: 'Store',
      priority: TaskPriority.high,
      status: TaskStatus.completed,
      createdAt: DateTime.utc(2026, 7, 14),
      attempt: 2,
      progress: 1,
      duration: const Duration(milliseconds: 12),
    );
    expect(PipelineTask.fromJson(task.toJson()), task);
  });
}
