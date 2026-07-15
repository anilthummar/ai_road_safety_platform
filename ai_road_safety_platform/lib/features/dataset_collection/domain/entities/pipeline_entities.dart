import 'package:equatable/equatable.dart';

/// Lifecycle of a pipeline task (Phase 12.10).
enum TaskStatus {
  pending,
  running,
  paused,
  completed,
  failed,
  cancelled,
  retrying,
}

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.pending => 'Pending',
        TaskStatus.running => 'Running',
        TaskStatus.paused => 'Paused',
        TaskStatus.completed => 'Completed',
        TaskStatus.failed => 'Failed',
        TaskStatus.cancelled => 'Cancelled',
        TaskStatus.retrying => 'Retrying',
      };
}

/// Overall pipeline runtime state.
enum PipelineStatus {
  idle,
  running,
  paused,
  stopped,
  recovering,
  failure,
}

extension PipelineStatusX on PipelineStatus {
  String get label => switch (this) {
        PipelineStatus.idle => 'Idle',
        PipelineStatus.running => 'Running',
        PipelineStatus.paused => 'Paused',
        PipelineStatus.stopped => 'Stopped',
        PipelineStatus.recovering => 'Recovering',
        PipelineStatus.failure => 'Failure',
      };
}

/// Scheduling priority (higher runs first in priority queues).
enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

extension TaskPriorityX on TaskPriority {
  int get weight => switch (this) {
        TaskPriority.low => 1,
        TaskPriority.normal => 5,
        TaskPriority.high => 10,
        TaskPriority.critical => 100,
      };

  String get label => name;
}

/// Built-in stage kinds; new kinds plug in via custom [PipelineStage].
enum PipelineStageKind {
  frameAcquisition,
  metadata,
  storage,
  datasetValidation,
  analytics,
  export,
  cloudSync,
}

extension PipelineStageKindX on PipelineStageKind {
  String get label => switch (this) {
        PipelineStageKind.frameAcquisition => 'Frame acquisition',
        PipelineStageKind.metadata => 'Metadata sync',
        PipelineStageKind.storage => 'Storage',
        PipelineStageKind.datasetValidation => 'Dataset validation',
        PipelineStageKind.analytics => 'Analytics',
        PipelineStageKind.export => 'Export (placeholder)',
        PipelineStageKind.cloudSync => 'Cloud sync (placeholder)',
      };

  bool get isPlaceholder =>
      this == PipelineStageKind.export || this == PipelineStageKind.cloudSync;
}

/// Retry configuration with optional exponential backoff.
class RetryPolicy extends Equatable {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.backoffMultiplier = 2,
    this.maxDelay = const Duration(seconds: 10),
  });

  static const RetryPolicy disabled = RetryPolicy(maxRetries: 0);

  /// Delay before attempt [attempt] (1-based after first failure).
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    final ms = initialDelay.inMilliseconds *
        (backoffMultiplier <= 1
            ? 1
            : _pow(backoffMultiplier, attempt - 1));
    final capped = ms > maxDelay.inMilliseconds
        ? maxDelay.inMilliseconds
        : ms.round();
    return Duration(milliseconds: capped);
  }

  double _pow(double base, int exp) {
    var r = 1.0;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }

  @override
  List<Object?> get props =>
      [maxRetries, initialDelay, backoffMultiplier, maxDelay];
}

/// Immutable unit of work flowing through the pipeline.
class PipelineTask extends Equatable {
  final String id;
  final PipelineStageKind stage;
  final TaskPriority priority;
  final TaskStatus status;
  final String name;
  final Map<String, Object?> payload;
  final int attempt;
  final RetryPolicy retryPolicy;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final double progress;
  final Duration? duration;
  final String? sessionId;

  const PipelineTask({
    required this.id,
    required this.stage,
    required this.name,
    required this.createdAt,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.pending,
    this.payload = const {},
    this.attempt = 0,
    this.retryPolicy = const RetryPolicy(),
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.progress = 0,
    this.duration,
    this.sessionId,
  });

  PipelineTask copyWith({
    String? id,
    PipelineStageKind? stage,
    TaskPriority? priority,
    TaskStatus? status,
    String? name,
    Map<String, Object?>? payload,
    int? attempt,
    RetryPolicy? retryPolicy,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    double? progress,
    Duration? duration,
    String? sessionId,
    bool clearError = false,
    bool clearStarted = false,
    bool clearCompleted = false,
  }) {
    return PipelineTask(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      name: name ?? this.name,
      payload: payload ?? this.payload,
      attempt: attempt ?? this.attempt,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      createdAt: createdAt ?? this.createdAt,
      startedAt: clearStarted ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stage': stage.name,
        'priority': priority.name,
        'status': status.name,
        'name': name,
        'payload': payload,
        'attempt': attempt,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'startedAt': startedAt?.toUtc().toIso8601String(),
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'errorMessage': errorMessage,
        'progress': progress,
        'durationMs': duration?.inMilliseconds,
        'sessionId': sessionId,
      };

  factory PipelineTask.fromJson(Map<String, dynamic> json) {
    return PipelineTask(
      id: json['id'] as String? ?? '',
      stage: PipelineStageKind.values.firstWhere(
        (s) => s.name == json['stage'],
        orElse: () => PipelineStageKind.metadata,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.normal,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      name: json['name'] as String? ?? '',
      payload: Map<String, Object?>.from(json['payload'] as Map? ?? const {}),
      attempt: (json['attempt'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      errorMessage: json['errorMessage'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      duration: json['durationMs'] is num
          ? Duration(milliseconds: (json['durationMs'] as num).toInt())
          : null,
      sessionId: json['sessionId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        stage,
        priority,
        status,
        name,
        payload,
        attempt,
        retryPolicy,
        createdAt,
        startedAt,
        completedAt,
        errorMessage,
        progress,
        duration,
        sessionId,
      ];
}

/// Snapshot of a single queue.
class QueueMetrics extends Equatable {
  final String name;
  final int length;
  final int capacity;
  final int overflowCount;
  final int enqueuedTotal;
  final int dequeuedTotal;

  const QueueMetrics({
    required this.name,
    required this.length,
    required this.capacity,
    this.overflowCount = 0,
    this.enqueuedTotal = 0,
    this.dequeuedTotal = 0,
  });

  double get fillRatio => capacity <= 0 ? 0 : length / capacity;

  @override
  List<Object?> get props =>
      [name, length, capacity, overflowCount, enqueuedTotal, dequeuedTotal];
}

/// Live pipeline monitor snapshot for UI / logging.
class PipelineMonitorSnapshot extends Equatable {
  final PipelineStatus status;
  final PipelineStageKind? currentStage;
  final int queueLength;
  final int completedTasks;
  final int failedTasks;
  final int retryCount;
  final double processingSpeedPerSec;
  final Duration averageTaskTime;
  final List<QueueMetrics> queues;
  final int activeWorkers;
  final int retryQueueLength;
  final DateTime updatedAt;

  const PipelineMonitorSnapshot({
    required this.status,
    required this.updatedAt,
    this.currentStage,
    this.queueLength = 0,
    this.completedTasks = 0,
    this.failedTasks = 0,
    this.retryCount = 0,
    this.processingSpeedPerSec = 0,
    this.averageTaskTime = Duration.zero,
    this.queues = const [],
    this.activeWorkers = 0,
    this.retryQueueLength = 0,
  });

  static PipelineMonitorSnapshot idle() => PipelineMonitorSnapshot(
        status: PipelineStatus.idle,
        updatedAt: DateTime.now().toUtc(),
      );

  @override
  List<Object?> get props => [
        status,
        currentStage,
        queueLength,
        completedTasks,
        failedTasks,
        retryCount,
        processingSpeedPerSec,
        averageTaskTime,
        queues,
        activeWorkers,
        retryQueueLength,
        updatedAt,
      ];
}

/// Result of enqueueing a task.
enum TaskEnqueueResult {
  enqueued,
  duplicate,
  overflowRejected,
  overflowDroppedOldest,
  pipelineStopped,
}

/// Outcome of a stage execution.
class StageResult extends Equatable {
  final bool success;
  final String? message;
  final Map<String, Object?> output;

  const StageResult({
    required this.success,
    this.message,
    this.output = const {},
  });

  factory StageResult.ok([Map<String, Object?> output = const {}]) =>
      StageResult(success: true, output: output);

  factory StageResult.fail(String message) =>
      StageResult(success: false, message: message);

  @override
  List<Object?> get props => [success, message, output];
}
