import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_task_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_worker.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_orchestrator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PipelineOrchestrator orch;

  setUp(() {
    final logger = AppLogger();
    final manager = BackgroundTaskManager(
      dispatcher: TaskDispatcher(
        pool: WorkerPool(size: 1, logger: logger),
        logger: logger,
      ),
      logger: logger,
      defaultTimeout: const Duration(seconds: 5),
    );
    orch = PipelineOrchestrator(taskManager: manager, logger: logger);
    orch.registerAll(PipelineStageFactory(logger: logger).createDefaultChain());
  });

  tearDown(() => orch.dispose());

  test('start pause resume stop', () async {
    await orch.start();
    expect(orch.status, PipelineStatus.running);
    await orch.pause();
    expect(orch.status, PipelineStatus.paused);
    await orch.resume();
    expect(orch.status, PipelineStatus.running);
    await orch.stop();
    expect(orch.status, PipelineStatus.stopped);
  });

  test('execute metadata task completes', () async {
    await orch.start();
    final task = PipelineTask(
      id: 'm1',
      stage: PipelineStageKind.metadata,
      name: 'Meta',
      createdAt: DateTime.now().toUtc(),
      retryPolicy: const RetryPolicy(maxRetries: 0),
    );
    final done = await orch.executeTask(task);
    expect(done.status, TaskStatus.completed);
    expect(orch.monitor().completedTasks, greaterThan(0));
  });

  test('validation failure retries then fails', () async {
    await orch.start();
    final task = PipelineTask(
      id: 'bad',
      stage: PipelineStageKind.datasetValidation,
      name: 'Bad',
      createdAt: DateTime.now().toUtc(),
      payload: const {'corrupt': true},
      retryPolicy: const RetryPolicy(
        maxRetries: 1,
        initialDelay: Duration(milliseconds: 10),
      ),
    );
    final done = await orch.executeTask(task);
    expect(done.status, TaskStatus.failed);
    expect(orch.monitor().retryCount, greaterThan(0));
  });

  test('duplicate pending task rejected', () async {
    await orch.start();
    final task = PipelineTask(
      id: 'dup',
      stage: PipelineStageKind.analytics,
      name: 'Analytics',
      createdAt: DateTime.now().toUtc(),
      retryPolicy: const RetryPolicy(maxRetries: 0),
    );
    expect(
      orch.taskManager.schedule(task),
      TaskEnqueueResult.enqueued,
    );
    await expectLater(
      () => orch.executeTask(task),
      throwsA(isA<StateError>()),
    );
  });

  test('monitor exposes queues', () async {
    await orch.start();
    final snap = orch.monitor();
    expect(snap.queues.length, 2);
    expect(snap.status, PipelineStatus.running);
  });
}
