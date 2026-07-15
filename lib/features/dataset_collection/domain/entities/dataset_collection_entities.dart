import 'package:equatable/equatable.dart';

/// Lifecycle of a dataset recording session (Phase 12.2).
enum DatasetSessionStatus {
  /// Created / idle — not recording.
  idle,

  /// Actively recording (no frames yet in 12.2).
  recording,

  /// Recording paused; can resume.
  paused,

  /// Explicitly stopped by the user.
  stopped,

  /// Successfully finished.
  completed,

  /// Discarded / cancelled.
  cancelled,

  /// Terminal failure.
  failed,

  /// Soft-archived (reserved).
  archived,
}

/// Display / mapping helpers for [DatasetSessionStatus].
extension DatasetSessionStatusX on DatasetSessionStatus {
  /// Short UI label.
  String get label => switch (this) {
        DatasetSessionStatus.idle => 'Idle',
        DatasetSessionStatus.recording => 'Recording',
        DatasetSessionStatus.paused => 'Paused',
        DatasetSessionStatus.stopped => 'Stopped',
        DatasetSessionStatus.completed => 'Completed',
        DatasetSessionStatus.cancelled => 'Cancelled',
        DatasetSessionStatus.failed => 'Failed',
        DatasetSessionStatus.archived => 'Archived',
      };

  /// True while an unfinished recording can be restored.
  bool get isUnfinished =>
      this == DatasetSessionStatus.recording ||
      this == DatasetSessionStatus.paused;

  /// True when the session may no longer be resumed.
  bool get isTerminal =>
      this == DatasetSessionStatus.stopped ||
      this == DatasetSessionStatus.completed ||
      this == DatasetSessionStatus.cancelled ||
      this == DatasetSessionStatus.failed ||
      this == DatasetSessionStatus.archived;

  /// Parses wire / legacy status names (`ready`→idle, `active`→recording).
  static DatasetSessionStatus parse(String? name) {
    final key = (name ?? '').trim().toLowerCase();
    return switch (key) {
      'ready' || 'idle' => DatasetSessionStatus.idle,
      'active' || 'recording' => DatasetSessionStatus.recording,
      'paused' => DatasetSessionStatus.paused,
      'stopped' => DatasetSessionStatus.stopped,
      'completed' => DatasetSessionStatus.completed,
      'cancelled' || 'canceled' => DatasetSessionStatus.cancelled,
      'failed' => DatasetSessionStatus.failed,
      'archived' => DatasetSessionStatus.archived,
      _ => DatasetSessionStatus.idle,
    };
  }
}

/// One local dataset recording session (session manager — no capture in 12.2).
class DatasetSession extends Equatable {
  /// Unique id (UUID).
  final String id;

  /// Human-readable session name.
  final String sessionName;

  /// Optional description.
  final String description;

  /// Row creation time.
  final DateTime createdAt;

  /// Last metadata update.
  final DateTime updatedAt;

  /// When recording started.
  final DateTime? startedAt;

  /// When recording ended / cancelled.
  final DateTime? endedAt;

  /// Persisted accumulated duration (excludes paused gaps when updated).
  final Duration duration;

  /// Lifecycle status.
  final DatasetSessionStatus status;

  /// Captured frame count (0 until capture phase).
  final int frameCount;

  /// Flood-related event count (0 until capture phase).
  final int floodEventCount;

  /// Bytes attributed to this session on disk.
  final int totalStorage;

  /// Rolling average speed km/h.
  final double averageSpeed;

  /// Rolling average model confidence \[0–1\].
  final double averageConfidence;

  /// Rolling average flood coverage % \[0–100\].
  final double averageFloodCoverage;

  /// Device label at creation time.
  final String deviceName;

  /// App version at creation time.
  final String appVersion;

  /// Segmentation / detector model version tag.
  final String modelVersion;

  /// Creates [DatasetSession].
  const DatasetSession({
    required this.id,
    required this.sessionName,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.status,
    required this.frameCount,
    required this.floodEventCount,
    required this.totalStorage,
    required this.averageSpeed,
    required this.averageConfidence,
    required this.averageFloodCoverage,
    required this.deviceName,
    required this.appVersion,
    required this.modelVersion,
    this.startedAt,
    this.endedAt,
  });

  /// Spec alias for [floodEventCount].
  int get floodEvents => floodEventCount;

  /// Spec alias for [totalStorage].
  int get storageUsed => totalStorage;

  /// Whether recording is active.
  bool get isRecording => status == DatasetSessionStatus.recording;

  /// Whether recording is paused.
  bool get isPaused => status == DatasetSessionStatus.paused;

  /// Whether capture has started.
  bool get hasStarted => startedAt != null;

  /// Whether the session stores any frames yet.
  bool get hasFrames => frameCount > 0;

  /// Copy helper.
  DatasetSession copyWith({
    String? id,
    String? sessionName,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    DatasetSessionStatus? status,
    int? frameCount,
    int? floodEventCount,
    int? totalStorage,
    double? averageSpeed,
    double? averageConfidence,
    double? averageFloodCoverage,
    String? deviceName,
    String? appVersion,
    String? modelVersion,
    bool clearStartedAt = false,
    bool clearEndedAt = false,
  }) {
    return DatasetSession(
      id: id ?? this.id,
      sessionName: sessionName ?? this.sessionName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      duration: duration ?? this.duration,
      status: status ?? this.status,
      frameCount: frameCount ?? this.frameCount,
      floodEventCount: floodEventCount ?? this.floodEventCount,
      totalStorage: totalStorage ?? this.totalStorage,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      averageFloodCoverage:
          averageFloodCoverage ?? this.averageFloodCoverage,
      deviceName: deviceName ?? this.deviceName,
      appVersion: appVersion ?? this.appVersion,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionName,
        description,
        createdAt,
        updatedAt,
        startedAt,
        endedAt,
        duration,
        status,
        frameCount,
        floodEventCount,
        totalStorage,
        averageSpeed,
        averageConfidence,
        averageFloodCoverage,
        deviceName,
        appVersion,
        modelVersion,
      ];
}

/// Aggregate metrics across all local dataset sessions.
class DatasetStatistics extends Equatable {
  /// Session count.
  final int totalSessions;

  /// Sum of frames.
  final int totalFrames;

  /// Sum of flood events.
  final int totalFloodEvents;

  /// Sum of session storage bytes.
  final int totalStorage;

  /// Mean averageSpeed across sessions (0 if none).
  final double averageSpeed;

  /// Mean averageConfidence across sessions (0 if none).
  final double averageConfidence;

  /// Creates [DatasetStatistics].
  const DatasetStatistics({
    required this.totalSessions,
    required this.totalFrames,
    required this.totalFloodEvents,
    required this.totalStorage,
    required this.averageSpeed,
    required this.averageConfidence,
  });

  /// Empty aggregates.
  const DatasetStatistics.empty()
      : totalSessions = 0,
        totalFrames = 0,
        totalFloodEvents = 0,
        totalStorage = 0,
        averageSpeed = 0,
        averageConfidence = 0;

  @override
  List<Object?> get props => [
        totalSessions,
        totalFrames,
        totalFloodEvents,
        totalStorage,
        averageSpeed,
        averageConfidence,
      ];
}

/// On-device storage snapshot for the dataset root folder.
class DatasetStorage extends Equatable {
  /// Device total bytes when known; otherwise `0`.
  final int totalDiskSpace;

  /// Bytes used under the dataset folder.
  final int usedDiskSpace;

  /// Approximate free bytes when known; otherwise `0`.
  final int remainingDiskSpace;

  /// Absolute path to the dataset root directory.
  final String datasetFolder;

  /// Creates [DatasetStorage].
  const DatasetStorage({
    required this.totalDiskSpace,
    required this.usedDiskSpace,
    required this.remainingDiskSpace,
    required this.datasetFolder,
  });

  /// Usage ratio \[0–1\] when total is known.
  double get usedRatio {
    if (totalDiskSpace <= 0) return 0;
    return (usedDiskSpace / totalDiskSpace).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        totalDiskSpace,
        usedDiskSpace,
        remainingDiskSpace,
        datasetFolder,
      ];
}

/// Input for creating / starting a new session.
class CreateDatasetSessionParams extends Equatable {
  /// Session display name.
  final String sessionName;

  /// Optional description.
  final String description;

  /// Creates [CreateDatasetSessionParams].
  const CreateDatasetSessionParams({
    required this.sessionName,
    this.description = '',
  });

  @override
  List<Object?> get props => [sessionName, description];
}

/// Input for renaming a session.
class RenameDatasetSessionParams extends Equatable {
  /// Target session id.
  final String id;

  /// New name.
  final String sessionName;

  /// Creates [RenameDatasetSessionParams].
  const RenameDatasetSessionParams({
    required this.id,
    required this.sessionName,
  });

  @override
  List<Object?> get props => [id, sessionName];
}
