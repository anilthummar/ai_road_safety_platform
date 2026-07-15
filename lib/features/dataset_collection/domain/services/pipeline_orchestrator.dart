import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_task_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';

/// Coordinates registered stages and the background task manager.
class PipelineOrchestrator {
  final BackgroundTaskManager taskManager;
  final AppLogger logger;
  final Map<PipelineStageKind, PipelineStage> _stages = {};

  PipelineStatus _status = PipelineStatus.idle;
  PipelineStageKind? _currentStage;
  DateTime? _startedAt;
  bool _loopActive = false;
  Completer<void>? _pauseGate;

  PipelineOrchestrator({
    required this.taskManager,
    required this.logger,
  });

  PipelineStatus get status => _status;
  PipelineStageKind? get currentStage => _currentStage;
  DateTime? get startedAt => _startedAt;
  List<PipelineStage> get stages => _stages.values.toList(growable: false);

  void registerStage(PipelineStage stage) {
    _stages[stage.kind] = stage;
    logger.debug('Stage registered ${stage.kind.name}', tag: 'Pipeline');
  }

  void registerAll(Iterable<PipelineStage> stages) {
    for (final s in stages) {
      registerStage(s);
    }
  }

  PipelineStage? stageFor(PipelineStageKind kind) => _stages[kind];

  Future<void> start() async {
    if (_status == PipelineStatus.running) return;
    if (_stages.isEmpty) {
      throw StateError('No pipeline stages registered');
    }
    _status = PipelineStatus.running;
    _startedAt = DateTime.now().toUtc();
    _pauseGate = null;
    logger.info('Pipeline Started', tag: 'Pipeline');
    _ensureLoop();
  }

  Future<void> pause() async {
    if (_status != PipelineStatus.running) return;
    _status = PipelineStatus.paused;
    _pauseGate = Completer<void>();
    logger.info('Pipeline Paused', tag: 'Pipeline');
  }

  Future<void> resume() async {
    if (_status != PipelineStatus.paused) return;
    _status = PipelineStatus.running;
    _pauseGate?.complete();
    _pauseGate = null;
    logger.info('Pipeline Resumed', tag: 'Pipeline');
    _ensureLoop();
  }

  Future<void> stop() async {
    _status = PipelineStatus.stopped;
    _currentStage = null;
    _pauseGate?.complete();
    _pauseGate = null;
    logger.info('Pipeline Stopped', tag: 'Pipeline');
  }

  Future<void> restart() async {
    await stop();
    taskManager.readyQueue.clear();
    taskManager.retryQueue.clear();
    await start();
  }

  /// Recovers by re-queueing failed tasks that still have retries left.
  Future<int> recoverFailedStages() async {
    _status = PipelineStatus.recovering;
    var recovered = 0;
    final failed = taskManager.tasks.values
        .where((t) => t.status == TaskStatus.failed)
        .toList();
    for (final t in failed) {
      if (t.attempt <= t.retryPolicy.maxRetries) {
        final result = taskManager.schedule(
          t.copyWith(
            status: TaskStatus.pending,
            clearError: true,
            clearStarted: true,
            clearCompleted: true,
          ),
        );
        if (result == TaskEnqueueResult.enqueued ||
            result == TaskEnqueueResult.overflowDroppedOldest) {
          recovered++;
        }
      }
    }
    _status = PipelineStatus.running;
    _ensureLoop();
    logger.info('Recovered $recovered failed tasks', tag: 'Pipeline');
    return recovered;
  }

  Future<PipelineTask> executeTask(PipelineTask task) async {
    if (_status == PipelineStatus.stopped || _status == PipelineStatus.idle) {
      await start();
    }
    final stage = _stages[task.stage];
    if (stage == null) {
      throw StateError('Stage ${task.stage.name} not registered');
    }
    // Prevent dependency conflicts: same id already running.
    final existing = taskManager.tasks[task.id];
    if (existing?.status == TaskStatus.running) {
      throw StateError('Task dependency conflict: ${task.id} already running');
    }
    final enqueue = taskManager.schedule(task);
    if (enqueue == TaskEnqueueResult.duplicate) {
      throw StateError('Duplicate task ${task.id}');
    }
    if (enqueue == TaskEnqueueResult.overflowRejected) {
      throw StateError('Queue overflow');
    }
    _ensureLoop();
    // Wait until task leaves running/pending/retrying.
    for (var i = 0; i < 500; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final t = taskManager.tasks[task.id];
      if (t == null) continue;
      if (t.status == TaskStatus.completed ||
          t.status == TaskStatus.failed ||
          t.status == TaskStatus.cancelled) {
        return t;
      }
    }
    return taskManager.tasks[task.id] ?? task;
  }

  Future<PipelineTask> retryTask(String taskId) async {
    return taskManager.retry(taskId, (kind) {
      final s = _stages[kind];
      if (s == null) throw StateError('Missing stage $kind');
      return s;
    });
  }

  Future<bool> cancelTask(String taskId) => taskManager.cancel(taskId);

  PipelineMonitorSnapshot monitor() {
    final started = _startedAt ?? DateTime.now().toUtc();
    return PipelineMonitorSnapshot(
      status: _status,
      currentStage: _currentStage,
      queueLength: taskManager.readyQueue.length,
      completedTasks: taskManager.completedCount,
      failedTasks: taskManager.failedCount,
      retryCount: taskManager.retryTriggeredCount,
      processingSpeedPerSec: taskManager.processingSpeedPerSec(started),
      averageTaskTime: taskManager.averageTaskTime,
      queues: [
        taskManager.readyQueue.metrics,
        taskManager.retryQueue.metrics,
      ],
      activeWorkers: taskManager.dispatcher.pool.activeCount,
      retryQueueLength: taskManager.retryQueue.length,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  void _ensureLoop() {
    if (_loopActive) return;
    _loopActive = true;
    scheduleMicrotask(_drainLoop);
  }

  Future<void> _drainLoop() async {
    try {
      while (_status == PipelineStatus.running ||
          _status == PipelineStatus.recovering) {
        if (_pauseGate != null) {
          await _pauseGate!.future;
        }
        if (_status != PipelineStatus.running &&
            _status != PipelineStatus.recovering) {
          break;
        }
        final next = await taskManager.dequeueReady();
        if (next == null) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          if (taskManager.readyQueue.length == 0) break;
          continue;
        }
        final stage = _stages[next.stage];
        if (stage == null) {
          logger.warning('Missing stage for ${next.stage}', tag: 'Pipeline');
          continue;
        }
        _currentStage = next.stage;
        await taskManager.execute(next, stage);
        _currentStage = null;
      }
    } finally {
      _loopActive = false;
      if (_status == PipelineStatus.running &&
          taskManager.readyQueue.length > 0) {
        _ensureLoop();
      }
    }
  }

  void dispose() {
    _status = PipelineStatus.stopped;
    taskManager.dispose();
  }
}
