import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_task_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_worker.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task manager schedules and executes', () async {
    final logger = AppLogger();
    final manager = BackgroundTaskManager(
      dispatcher: TaskDispatcher(pool: WorkerPool(size: 1, logger: logger)),
      logger: logger,
    );
    final task = manager.createTask(
      stage: PipelineStageKind.analytics,
      name: 'Analytics',
      retryPolicy: const RetryPolicy(maxRetries: 0),
    );
    expect(manager.schedule(task), TaskEnqueueResult.enqueued);
    final dequeued = await manager.dequeueReady();
    expect(dequeued?.id, task.id);
    final stage = AnalyticsStage(logger: logger);
    final done = await manager.execute(dequeued!, stage);
    expect(done.status, TaskStatus.completed);
    expect(manager.averageTaskTime.inMilliseconds, greaterThanOrEqualTo(0));
    manager.dispose();
  });

  test('worker pool dispatches work', () async {
    final pool = WorkerPool(size: 2);
    final dispatcher = TaskDispatcher(pool: pool);
    final result = await dispatcher.dispatch(() async => 42);
    expect(result, 42);
    dispatcher.dispose();
  });
}
