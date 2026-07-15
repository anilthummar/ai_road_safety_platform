import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/pipeline_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_task_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_worker.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_orchestrator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PipelineRepositoryImpl repo;
  late PipelineOrchestrator orch;

  setUp(() {
    final logger = AppLogger();
    orch = PipelineOrchestrator(
      taskManager: BackgroundTaskManager(
        dispatcher: TaskDispatcher(
          pool: WorkerPool(size: 1, logger: logger),
        ),
        logger: logger,
      ),
      logger: logger,
    );
    orch.registerAll(PipelineStageFactory(logger: logger).createDefaultChain());
    repo = PipelineRepositoryImpl(
      orchestrator: orch,
      errorHandler: ErrorHandler(logger: logger),
      logger: logger,
    );
  });

  tearDown(() => orch.dispose());

  test('start/stop/pause/resume via repository', () async {
    expect((await repo.startPipeline()).isOk, isTrue);
    expect((await repo.pausePipeline()).isOk, isTrue);
    expect((await repo.resumePipeline()).isOk, isTrue);
    expect((await repo.stopPipeline()).isOk, isTrue);
  });

  test('execute and history', () async {
    await repo.startPipeline();
    final result = await repo.executeTask(
      PipelineTask(
        id: 's1',
        stage: PipelineStageKind.storage,
        name: 'Store',
        createdAt: DateTime.now().toUtc(),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      ),
    );
    expect(result.isOk, isTrue);
    final history = await repo.getTaskHistory();
    expect(
      history.fold(onOk: (v) => v.isNotEmpty, onErr: (_) => false),
      isTrue,
    );
  });

  test('cancel unknown task fails', () async {
    final result = await repo.cancelTask('missing');
    expect(result.isErr, isTrue);
  });
}
