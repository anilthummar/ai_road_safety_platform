import 'package:equatable/equatable.dart';

/// Preferred physical camera lens for initialization.
enum CameraLensPreference {
  /// Rear / world-facing camera (default for road safety).
  rear,

  /// Front / user-facing camera.
  front,
}

/// OS-level camera permission status.
enum CameraPermissionStatus {
  /// Permission has been granted.
  granted,

  /// Permission denied but can ask again.
  denied,

  /// Permanently denied; user must open system settings.
  permanentlyDenied,

  /// Permission not yet requested.
  restricted,

  /// Platform does not require runtime permission.
  limited,
}

/// Immutable snapshot of an active camera session (domain only — no Flutter types).
class CameraSession extends Equatable {
  /// Stable session identifier for logging / correlating frames.
  final String sessionId;

  /// Device camera name from the platform plugin.
  final String cameraName;

  /// Selected lens preference used at init.
  final CameraLensPreference lens;

  /// Preview width in pixels.
  final int previewWidth;

  /// Preview height in pixels.
  final int previewHeight;

  /// Sensor orientation degrees reported by the device.
  final int sensorOrientation;

  /// Whether the session is currently paused (app background / explicit pause).
  final bool isPaused;

  /// Whether image frames are being streamed for downstream consumers.
  final bool isStreamingFrames;

  /// Creates a [CameraSession].
  const CameraSession({
    required this.sessionId,
    required this.cameraName,
    required this.lens,
    required this.previewWidth,
    required this.previewHeight,
    required this.sensorOrientation,
    this.isPaused = false,
    this.isStreamingFrames = false,
  });

  /// Aspect ratio of the preview buffer.
  double get aspectRatio {
    if (previewHeight == 0) return 1;
    return previewWidth / previewHeight;
  }

  /// Returns a copy with selective overrides.
  CameraSession copyWith({
    String? sessionId,
    String? cameraName,
    CameraLensPreference? lens,
    int? previewWidth,
    int? previewHeight,
    int? sensorOrientation,
    bool? isPaused,
    bool? isStreamingFrames,
  }) {
    return CameraSession(
      sessionId: sessionId ?? this.sessionId,
      cameraName: cameraName ?? this.cameraName,
      lens: lens ?? this.lens,
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      sensorOrientation: sensorOrientation ?? this.sensorOrientation,
      isPaused: isPaused ?? this.isPaused,
      isStreamingFrames: isStreamingFrames ?? this.isStreamingFrames,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        cameraName,
        lens,
        previewWidth,
        previewHeight,
        sensorOrientation,
        isPaused,
        isStreamingFrames,
      ];
}

/// Lightweight frame metadata for streaming (no pixel buffers retained).
///
/// Pixel data is intentionally omitted here to avoid memory pressure; future
/// AI phases will consume frames via a dedicated processing pipeline.
class CameraFrameMeta extends Equatable {
  /// Session that produced the frame.
  final String sessionId;

  /// Monotonic frame sequence number within the session.
  final int sequence;

  /// Capture timestamp.
  final DateTime timestamp;

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;

  /// True when this frame was dropped by the throttle to protect memory.
  final bool wasDropped;

  /// Creates [CameraFrameMeta].
  const CameraFrameMeta({
    required this.sessionId,
    required this.sequence,
    required this.timestamp,
    required this.width,
    required this.height,
    this.wasDropped = false,
  });

  @override
  List<Object?> get props => [
        sessionId,
        sequence,
        timestamp,
        width,
        height,
        wasDropped,
      ];
}
