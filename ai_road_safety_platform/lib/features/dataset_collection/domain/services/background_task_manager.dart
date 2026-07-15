import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_worker.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_queues.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';
import 'package:uuid/uuid.dart';

/// Schedules, retries, cancels, and tracks background tasks.
class BackgroundTaskManager {
  final PriorityTaskQueue readyQueue;
  final FifoTaskQueue retryQueue;
  final TaskDispatcher dispatcher;
  final AppLogger logger;
  final Uuid _uuid;
  final Duration defaultTimeout;

  final Map<String, PipelineTask> _tasks = {};
  final Map<String, Completer<void>> _cancelTokens = {};
  final List<PipelineTask> _history = [];

  int completedCount = 0;
  int failedCount = 0;
  int retryTriggeredCount = 0;
  final List<Duration> _durations = [];

  Timer? _drainTimer;

  BackgroundTaskManager({
    required this.dispatcher,
    required this.logger,
    PriorityTaskQueue? readyQueue,
    FifoTaskQueue? retryQueue,
    Uuid? uuid,
    this.defaultTimeout = const Duration(seconds: 30),
  })  : readyQueue = readyQueue ??
            PriorityTaskQueue(name: 'ready', capacity: 128),
        retryQueue = retryQueue ??
            FifoTaskQueue(
              name: 'retry',
              capacity: 64,
              backpressure: BackpressurePolicy.reject,
            ),
        _uuid = uuid ?? const Uuid();

  List<PipelineTask> get history => List.unmodifiable(_history.reversed);
  Map<String, PipelineTask> get tasks => Map.unmodifiable(_tasks);

  /// Enqueues [task]; returns enqueue outcome.
  TaskEnqueueResult schedule(PipelineTask task) {
    if (_tasks.containsKey(task.id) &&
        _tasks[task.id]!.status == TaskStatus.running) {
      return TaskEnqueueResult.duplicate;
    }
    final pending = task.copyWith(status: TaskStatus.pending);
    _tasks[pending.id] = pending;
    final result = readyQueue.enqueue(pending);
    if (result == TaskEnqueueResult.overflowRejected) {
      logger.warning('Queue Overflow ${readyQueue.name}', tag: 'Pipeline');
      _tasks.remove(pending.id);
    } else if (result == TaskEnqueueResult.duplicate) {
      logger.debug('Duplicate task ${pending.id}', tag: 'Pipeline');
    }
    _kick();
    return result;
  }

  PipelineTask createTask({
    required PipelineStageKind stage,
    required String name,
    TaskPriority priority = TaskPriority.normal,
    Map<String, Object?> payload = const {},
    RetryPolicy retryPolicy = const RetryPolicy(),
    String? sessionId,
    String? id,
  }) {
    return PipelineTask(
      id: id ?? _uuid.v4(),
      stage: stage,
      name: name,
      priority: priority,
      payload: payload,
      retryPolicy: retryPolicy,
      createdAt: DateTime.now().toUtc(),
      sessionId: sessionId,
    );
  }

  Future<bool> cancel(String taskId) async {
    final queued = readyQueue.removeById(taskId) ??
        retryQueue.removeById(taskId);
    if (queued != null) {
      final cancelled = queued.copyWith(
        status: TaskStatus.cancelled,
        completedAt: DateTime.now().toUtc(),
      );
      _tasks[taskId] = cancelled;
      _history.add(cancelled);
      logger.info('Task Cancelled $taskId', tag: 'Pipeline');
      return true;
    }
    final token = _cancelTokens[taskId];
    if (token != null && !token.isCompleted) {
      token.complete();
      return true;
    }
    final existing = _tasks[taskId];
    if (existing != null &&
        (existing.status == TaskStatus.pending ||
            existing.status == TaskStatus.retrying)) {
      _tasks[taskId] = existing.copyWith(
        status: TaskStatus.cancelled,
        completedAt: DateTime.now().toUtc(),
      );
      return true;
    }
    return false;
  }

  Future<PipelineTask> execute(
    PipelineTask task,
    PipelineStage stage,
  ) async {
    if (task.status == TaskStatus.cancelled) return task;

    final started = DateTime.now().toUtc();
    var running = task.copyWith(
      status: TaskStatus.running,
      startedAt: started,
      attempt: task.attempt + 1,
      progress: 0.1,
      clearError: true,
    );
    _tasks[running.id] = running;
    _cancelTokens[running.id] = Completer<void>();
    logger.info('Task Started ${running.id} ${stage.kind.name}',
        tag: 'Pipeline');

    try {
      final result = await dispatcher
          .dispatch(() => stage.process(running))
          .timeout(defaultTimeout);

      if (_cancelTokens[running.id]?.isCompleted == true) {
        running = running.copyWith(
          status: TaskStatus.cancelled,
          completedAt: DateTime.now().toUtc(),
        );
        _finish(running);
        return running;
      }

      if (!result.success) {
        return _failOrRetry(running, result.message ?? 'Stage failed', stage);
      }

      final doneAt = DateTime.now().toUtc();
      running = running.copyWith(
        status: TaskStatus.completed,
        progress: 1,
        completedAt: doneAt,
        duration: doneAt.difference(started),
        payload: {...running.payload, ...result.output},
      );
      completedCount++;
      _durations.add(running.duration!);
      logger.info('Task Completed ${running.id}', tag: 'Pipeline');
      _finish(running);
      return running;
    } on TimeoutException {
      return _failOrRetry(running, 'Task timeout', stage);
    } catch (e) {
      return _failOrRetry(running, e.toString(), stage);
    } finally {
      _cancelTokens.remove(running.id);
    }
  }

  Future<PipelineTask> retry(
    String taskId,
    PipelineStage Function(PipelineStageKind) stageFor,
  ) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw StateError('Unknown task $taskId');
    }
    if (task.attempt > task.retryPolicy.maxRetries) {
      throw StateError('Max retries exceeded for $taskId');
    }
    retryTriggeredCount++;
    logger.info('Retry Triggered $taskId', tag: 'Pipeline');
      final delay = task.retryPolicy.delayForAttempt(task.attempt + 1);
      final retrying =
          task.copyWith(status: TaskStatus.retrying, clearError: true);
      _tasks[taskId] = retrying;
      retryQueue.enqueue(retrying);
      await Future<void>.delayed(delay);
      retryQueue.removeById(taskId);
      return execute(retrying, stageFor(retrying.stage));
  }

  Future<PipelineTask> _failOrRetry(
    PipelineTask task,
    String error,
    PipelineStage stage,
  ) async {
    logger.warning('Task Failed ${task.id}: $error', tag: 'Pipeline');
    if (task.attempt <= task.retryPolicy.maxRetries) {
      retryTriggeredCount++;
      logger.info('Retry Triggered ${task.id}', tag: 'Pipeline');
      final delay = task.retryPolicy.delayForAttempt(task.attempt);
      final retrying = task.copyWith(
        status: TaskStatus.retrying,
        errorMessage: error,
      );
      _tasks[task.id] = retrying;
      retryQueue.enqueue(retrying);
      await Future<void>.delayed(delay);
      retryQueue.removeById(task.id);
      return execute(retrying, stage);
    }
    final failed = task.copyWith(
      status: TaskStatus.failed,
      errorMessage: error,
      completedAt: DateTime.now().toUtc(),
      progress: 0,
    );
    failedCount++;
    _finish(failed);
    return failed;
  }

  void _finish(PipelineTask task) {
    _tasks[task.id] = task;
    _history.add(task);
    if (_history.length > 200) _history.removeAt(0);
  }

  Duration get averageTaskTime {
    if (_durations.isEmpty) return Duration.zero;
    final totalMs =
        _durations.fold<int>(0, (s, d) => s + d.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ _durations.length);
  }

  double processingSpeedPerSec(DateTime pipelineStartedAt) {
    final elapsed =
        DateTime.now().toUtc().difference(pipelineStartedAt).inMilliseconds;
    if (elapsed <= 0) return 0;
    return completedCount / (elapsed / 1000.0);
  }

  void _kick() {
    _drainTimer ??= Timer(const Duration(milliseconds: 1), () {
      _drainTimer = null;
    });
  }

  /// Optional cooperative drain hook used by orchestrator.
  Future<PipelineTask?> dequeueReady() async {
    return readyQueue.dequeue();
  }

  void dispose() {
    _drainTimer?.cancel();
    readyQueue.clear();
    retryQueue.clear();
  }
}
