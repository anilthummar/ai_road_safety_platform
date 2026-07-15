import 'package:equatable/equatable.dart';

/// Why a frame was admitted into the acquisition pipeline (Phase 12.3).
enum CaptureType {
  /// Periodic / automatic interval capture.
  automatic,

  /// Explicit user tap.
  manual,

  /// Future scheduled jobs.
  scheduled,

  /// Future composite / non-time rules.
  ruleTriggered,
}

/// Human-readable reason + [CaptureType] pair for a captured frame.
class CaptureReason extends Equatable {
  /// Machine-readable rule / source id.
  final String ruleId;

  /// Short explanation for logs / UI.
  final String message;

  /// Capture classification.
  final CaptureType type;

  /// Creates [CaptureReason].
  const CaptureReason({
    required this.ruleId,
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [ruleId, message, type];
}

/// Immutable metadata for a frame admitted by the acquisition engine.
///
/// **No image bytes** — Phase 12.3 streams identity into the pipeline only.
class CapturedFrame extends Equatable {
  /// Unique frame id (UUID).
  final String frameId;

  /// Capture wall-clock time.
  final DateTime timestamp;

  /// Pixel width of the source camera buffer.
  final int width;

  /// Pixel height of the source camera buffer.
  final int height;

  /// Sensor / buffer rotation degrees.
  final int rotation;

  /// Owning dataset recording session id.
  final String sessionId;

  /// Why this frame was kept.
  final CaptureReason captureReason;

  /// Capture classification (mirrors [CaptureReason.type]).
  final CaptureType captureType;

  /// Camera lens label (`rear` / `front` / `unknown`).
  final String cameraLensDirection;

  /// Optional camera pipeline sequence for de-duplication.
  final int? cameraSequence;

  /// Creates [CapturedFrame].
  const CapturedFrame({
    required this.frameId,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.rotation,
    required this.sessionId,
    required this.captureReason,
    required this.captureType,
    required this.cameraLensDirection,
    this.cameraSequence,
  });

  @override
  List<Object?> get props => [
        frameId,
        timestamp,
        width,
        height,
        rotation,
        sessionId,
        captureReason,
        captureType,
        cameraLensDirection,
        cameraSequence,
      ];
}

/// Live stats exposed to presentation (memory-only queue).
class FrameQueueSnapshot extends Equatable {
  /// Frames currently queued.
  final int size;

  /// Configured maximum.
  final int maxSize;

  /// Total frames accepted since last start.
  final int capturedCount;

  /// Total frames dropped (validation / full / duplicate).
  final int droppedCount;

  /// Effective capture rate (admitted frames / second, rolling).
  final double captureRateFps;

  /// Creates [FrameQueueSnapshot].
  const FrameQueueSnapshot({
    required this.size,
    required this.maxSize,
    required this.capturedCount,
    required this.droppedCount,
    this.captureRateFps = 0,
  });

  /// Empty idle snapshot.
  const FrameQueueSnapshot.empty({this.maxSize = 30})
      : size = 0,
        capturedCount = 0,
        droppedCount = 0,
        captureRateFps = 0;

  /// Capacity usage \[0–1\].
  double get fillRatio => maxSize <= 0 ? 0 : (size / maxSize).clamp(0.0, 1.0);

  /// True when at capacity.
  bool get isFull => size >= maxSize;

  /// Copy helper.
  FrameQueueSnapshot copyWith({
    int? size,
    int? maxSize,
    int? capturedCount,
    int? droppedCount,
    double? captureRateFps,
  }) {
    return FrameQueueSnapshot(
      size: size ?? this.size,
      maxSize: maxSize ?? this.maxSize,
      capturedCount: capturedCount ?? this.capturedCount,
      droppedCount: droppedCount ?? this.droppedCount,
      captureRateFps: captureRateFps ?? this.captureRateFps,
    );
  }

  @override
  List<Object?> get props =>
      [size, maxSize, capturedCount, droppedCount, captureRateFps];
}

/// Tunables for the acquisition engine (preview stays higher FPS elsewhere).
class FrameCaptureConfig extends Equatable {
  /// Default capture interval for [TimeIntervalRule] (1 FPS target).
  final Duration captureInterval;

  /// Max in-memory FIFO length.
  final int maxQueueSize;

  /// Reject frames smaller than this width.
  final int minWidth;

  /// Reject frames smaller than this height.
  final int minHeight;

  /// Throttle camera metadata stream while acquiring.
  final int streamTargetFps;

  /// Creates [FrameCaptureConfig].
  const FrameCaptureConfig({
    this.captureInterval = const Duration(seconds: 1),
    this.maxQueueSize = 30,
    this.minWidth = 320,
    this.minHeight = 240,
    this.streamTargetFps = 5,
  });

  @override
  List<Object?> get props => [
        captureInterval,
        maxQueueSize,
        minWidth,
        minHeight,
        streamTargetFps,
      ];
}
