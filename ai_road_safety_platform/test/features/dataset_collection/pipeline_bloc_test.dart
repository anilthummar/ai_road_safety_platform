import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/pipeline_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/pipeline_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/pipeline_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStart extends Mock implements StartPipelineUseCase {}

class _MockPause extends Mock implements PausePipelineUseCase {}

class _MockResume extends Mock implements ResumePipelineUseCase {}

class _MockStop extends Mock implements StopPipelineUseCase {}

class _MockExecute extends Mock implements ExecutePipelineTaskUseCase {}

class _MockRetry extends Mock implements RetryTaskUseCase {}

class _MockCancel extends Mock implements CancelTaskUseCase {}

class _MockMonitor extends Mock implements GetPipelineMonitorUseCase {}

class _MockRepo extends Mock implements PipelineRepository {}

void main() {
  late _MockStart start;
  late _MockPause pause;
  late _MockResume resume;
  late _MockStop stop;
  late _MockExecute execute;
  late _MockRetry retry;
  late _MockCancel cancel;
  late _MockMonitor monitor;
  late _MockRepo repo;

  final snap = PipelineMonitorSnapshot(
    status: PipelineStatus.running,
    updatedAt: DateTime.utc(2026, 7, 14),
    completedTasks: 1,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      PipelineTask(
        id: 'x',
        stage: PipelineStageKind.metadata,
        name: 'x',
        createdAt: DateTime.utc(2026, 7, 14),
      ),
    );
    registerFallbackValue(const RetryTaskParams('x'));
    registerFallbackValue(const CancelTaskParams('x'));
  });

  setUp(() {
    start = _MockStart();
    pause = _MockPause();
    resume = _MockResume();
    stop = _MockStop();
    execute = _MockExecute();
    retry = _MockRetry();
    cancel = _MockCancel();
    monitor = _MockMonitor();
    repo = _MockRepo();

    when(() => start(any())).thenAnswer((_) async => Ok(snap));
    when(() => pause(any())).thenAnswer(
      (_) async => Ok(snap.copyWithStatus(PipelineStatus.paused)),
    );
    when(() => resume(any())).thenAnswer((_) async => Ok(snap));
    when(() => stop(any())).thenAnswer(
      (_) async => Ok(snap.copyWithStatus(PipelineStatus.stopped)),
    );
    when(() => monitor(any())).thenAnswer((_) async => Ok(snap));
    when(() => repo.getTaskHistory())
        .thenAnswer((_) async => const Ok(<PipelineTask>[]));
    when(() => repo.restartPipeline()).thenAnswer((_) async => Ok(snap));
  });

  PipelineBloc build() => PipelineBloc(
        startPipeline: start,
        pausePipeline: pause,
        resumePipeline: resume,
        stopPipeline: stop,
        executePipelineTask: execute,
        retryTask: retry,
        cancelTask: cancel,
        getPipelineMonitor: monitor,
        repository: repo,
        logger: AppLogger(),
      );

  blocTest<PipelineBloc, PipelineState>(
    'start emits running',
    build: build,
    act: (b) => b.add(const PipelineStarted()),
    expect: () => [
      isA<PipelineRunning>()
          .having((s) => s.monitor.status, 'status', PipelineStatus.running),
    ],
  );

  blocTest<PipelineBloc, PipelineState>(
    'pause emits paused',
    build: build,
    act: (b) => b.add(const PipelinePaused()),
    expect: () => [isA<PipelinePausedState>()],
  );

  blocTest<PipelineBloc, PipelineState>(
    'enqueue demo task completes',
    build: build,
    setUp: () {
      final done = PipelineTask(
        id: 'd1',
        stage: PipelineStageKind.metadata,
        name: 'Meta',
        status: TaskStatus.completed,
        createdAt: DateTime.utc(2026, 7, 14),
        progress: 1,
      );
      when(() => execute(any())).thenAnswer((_) async => Ok(done));
      when(() => repo.getTaskHistory())
          .thenAnswer((_) async => Ok([done]));
    },
    act: (b) => b.add(const PipelineEnqueueDemoTask()),
    expect: () => [
      isA<PipelineTaskExecuting>(),
      isA<PipelineTaskCompletedState>(),
      isA<PipelineRunning>(),
    ],
  );
}

extension on PipelineMonitorSnapshot {
  PipelineMonitorSnapshot copyWithStatus(PipelineStatus status) {
    return PipelineMonitorSnapshot(
      status: status,
      updatedAt: updatedAt,
      currentStage: currentStage,
      queueLength: queueLength,
      completedTasks: completedTasks,
      failedTasks: failedTasks,
      retryCount: retryCount,
      processingSpeedPerSec: processingSpeedPerSec,
      averageTaskTime: averageTaskTime,
      queues: queues,
      activeWorkers: activeWorkers,
      retryQueueLength: retryQueueLength,
    );
  }
}
