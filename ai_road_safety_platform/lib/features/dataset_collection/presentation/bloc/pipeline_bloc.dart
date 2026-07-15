import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/pipeline_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/pipeline_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/pipeline_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/pipeline_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

export 'pipeline_event.dart';
export 'pipeline_state.dart';

/// UI orchestration for the edge processing pipeline (Phase 12.10).
class PipelineBloc extends Bloc<PipelineEvent, PipelineState> {
  final StartPipelineUseCase _start;
  final PausePipelineUseCase _pause;
  final ResumePipelineUseCase _resume;
  final StopPipelineUseCase _stop;
  final ExecutePipelineTaskUseCase _execute;
  final RetryTaskUseCase _retry;
  final CancelTaskUseCase _cancel;
  final GetPipelineMonitorUseCase _monitor;
  final PipelineRepository _repository;
  final AppLogger _logger;
  final Uuid _uuid;

  PipelineBloc({
    required StartPipelineUseCase startPipeline,
    required PausePipelineUseCase pausePipeline,
    required ResumePipelineUseCase resumePipeline,
    required StopPipelineUseCase stopPipeline,
    required ExecutePipelineTaskUseCase executePipelineTask,
    required RetryTaskUseCase retryTask,
    required CancelTaskUseCase cancelTask,
    required GetPipelineMonitorUseCase getPipelineMonitor,
    required PipelineRepository repository,
    required AppLogger logger,
    Uuid? uuid,
  })  : _start = startPipeline,
        _pause = pausePipeline,
        _resume = resumePipeline,
        _stop = stopPipeline,
        _execute = executePipelineTask,
        _retry = retryTask,
        _cancel = cancelTask,
        _monitor = getPipelineMonitor,
        _repository = repository,
        _logger = logger,
        _uuid = uuid ?? const Uuid(),
        super(const PipelineInitial()) {
    on<PipelineStarted>(_onStart);
    on<PipelinePaused>(_onPause);
    on<PipelineResumed>(_onResume);
    on<PipelineStopped>(_onStop);
    on<PipelineRestarted>(_onRestart);
    on<PipelineRefreshMonitor>(_onRefresh);
    on<PipelineEnqueueDemoTask>(_onEnqueue);
    on<PipelineTaskRetryRequested>(_onRetry);
    on<PipelineTaskCancelRequested>(_onCancel);
    on<PipelineRecoverFailed>(_onRecover);
  }

  Future<void> _onStart(
    PipelineStarted event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _start(const NoParams());
    await result.fold(
      onOk: (m) async {
        final history = await _history();
        emit(PipelineRunning(monitor: m, history: history, message: 'Running'));
      },
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onPause(
    PipelinePaused event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _pause(const NoParams());
    await result.fold(
      onOk: (m) async => emit(
        PipelinePausedState(monitor: m, history: await _history()),
      ),
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onResume(
    PipelineResumed event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _resume(const NoParams());
    await result.fold(
      onOk: (m) async => emit(
        PipelineRunning(
          monitor: m,
          history: await _history(),
          message: 'Resumed',
        ),
      ),
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onStop(
    PipelineStopped event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _stop(const NoParams());
    await result.fold(
      onOk: (m) async => emit(
        PipelineStoppedState(monitor: m, history: await _history()),
      ),
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onRestart(
    PipelineRestarted event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _repository.restartPipeline();
    await result.fold(
      onOk: (m) async => emit(
        PipelineRunning(
          monitor: m,
          history: await _history(),
          message: 'Restarted',
        ),
      ),
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onRefresh(
    PipelineRefreshMonitor event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _monitor(const NoParams());
    await result.fold(
      onOk: (m) async {
        final history = await _history();
        emit(_mapStatus(m, history));
      },
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onEnqueue(
    PipelineEnqueueDemoTask event,
    Emitter<PipelineState> emit,
  ) async {
    final task = PipelineTask(
      id: _uuid.v4(),
      stage: event.stage,
      name: '${event.stage.label} task',
      priority: event.priority,
      createdAt: DateTime.now().toUtc(),
      payload: {
        if (event.forceFail) 'corrupt': true,
        'demo': true,
      },
      retryPolicy: event.forceFail
          ? const RetryPolicy(maxRetries: 1, initialDelay: Duration(milliseconds: 50))
          : const RetryPolicy(maxRetries: 2),
    );

    final monitorBefore = await _monitor(const NoParams());
    final snap = monitorBefore.fold(
      onOk: (v) => v,
      onErr: (_) => PipelineMonitorSnapshot.idle(),
    );
    emit(
      PipelineTaskExecuting(
        monitor: snap,
        history: await _history(),
        task: task,
      ),
    );

    final result = await _execute(task);
    await result.fold(
      onOk: (done) async {
        _logger.info('Task Completed ${done.id}', tag: 'PipelineBloc');
        final m = await _monitor(const NoParams());
        final monitor = m.fold(
          onOk: (v) => v,
          onErr: (_) => snap,
        );
        final history = await _history();
        emit(
          PipelineTaskCompletedState(
            monitor: monitor,
            history: history,
            task: done,
          ),
        );
        emit(
          PipelineRunning(
            monitor: monitor,
            history: history,
            lastTask: done,
            message: done.status == TaskStatus.completed
                ? 'Task completed'
                : done.status.label,
          ),
        );
      },
      onErr: (f) async => emit(
        PipelineFailure(
          failure: f,
          monitor: snap,
          history: await _history(),
        ),
      ),
    );
  }

  Future<void> _onRetry(
    PipelineTaskRetryRequested event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _retry(RetryTaskParams(event.taskId));
    await result.fold(
      onOk: (task) async {
        final m = (await _monitor(const NoParams())).fold(
          onOk: (v) => v,
          onErr: (_) => PipelineMonitorSnapshot.idle(),
        );
        emit(
          PipelineRunning(
            monitor: m,
            history: await _history(),
            lastTask: task,
            message: 'Retry finished',
          ),
        );
      },
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onCancel(
    PipelineTaskCancelRequested event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _cancel(CancelTaskParams(event.taskId));
    await result.fold(
      onOk: (_) async {
        final m = (await _monitor(const NoParams())).fold(
          onOk: (v) => v,
          onErr: (_) => PipelineMonitorSnapshot.idle(),
        );
        emit(
          PipelineRunning(
            monitor: m,
            history: await _history(),
            message: 'Cancelled',
          ),
        );
      },
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<void> _onRecover(
    PipelineRecoverFailed event,
    Emitter<PipelineState> emit,
  ) async {
    final result = await _repository.recoverFailed();
    await result.fold(
      onOk: (n) async {
        final m = (await _monitor(const NoParams())).fold(
          onOk: (v) => v,
          onErr: (_) => PipelineMonitorSnapshot.idle(),
        );
        emit(
          PipelineRunning(
            monitor: m,
            history: await _history(),
            message: 'Recovered $n tasks',
          ),
        );
      },
      onErr: (f) async => emit(PipelineFailure(failure: f)),
    );
  }

  Future<List<PipelineTask>> _history() async {
    final result = await _repository.getTaskHistory();
    return result.fold(onOk: (v) => v, onErr: (_) => const []);
  }

  PipelineState _mapStatus(
    PipelineMonitorSnapshot m,
    List<PipelineTask> history,
  ) {
    return switch (m.status) {
      PipelineStatus.paused =>
        PipelinePausedState(monitor: m, history: history),
      PipelineStatus.stopped || PipelineStatus.idle =>
        PipelineStoppedState(monitor: m, history: history),
      PipelineStatus.failure => PipelineFailure(
          failure: const CacheFailure(message: 'Pipeline failure'),
          monitor: m,
          history: history,
        ),
      _ => PipelineRunning(monitor: m, history: history),
    };
  }
}
