import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:equatable/equatable.dart';

/// Camera feature events.
sealed class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

/// Bootstraps permission check + rear camera initialization.
class CameraStarted extends CameraEvent {
  /// Lens preference; defaults to rear for road safety capture.
  final CameraLensPreference lens;

  /// Creates [CameraStarted].
  const CameraStarted({this.lens = CameraLensPreference.rear});

  @override
  List<Object?> get props => [lens];
}

/// Re-requests permission after a denial.
class CameraPermissionRequested extends CameraEvent {
  const CameraPermissionRequested();
}

/// Opens OS settings when permission is permanently denied.
class CameraOpenSettingsRequested extends CameraEvent {
  const CameraOpenSettingsRequested();
}

/// Explicit user pause (also used for background lifecycle).
class CameraPaused extends CameraEvent {
  const CameraPaused();
}

/// Explicit user resume (also used for foreground lifecycle).
class CameraResumed extends CameraEvent {
  const CameraResumed();
}

/// Starts throttled frame metadata streaming.
class CameraFrameStreamingStarted extends CameraEvent {
  /// Target FPS for metadata emissions.
  final int targetFps;

  /// Creates [CameraFrameStreamingStarted].
  const CameraFrameStreamingStarted({this.targetFps = 8});

  @override
  List<Object?> get props => [targetFps];
}

/// Stops frame streaming.
class CameraFrameStreamingStopped extends CameraEvent {
  const CameraFrameStreamingStopped();
}

/// Device orientation changed (degrees).
class CameraOrientationChanged extends CameraEvent {
  /// Orientation degrees (0 / 90 / 180 / 270).
  final int degrees;

  /// Creates [CameraOrientationChanged].
  const CameraOrientationChanged(this.degrees);

  @override
  List<Object?> get props => [degrees];
}

/// Tears down hardware when leaving the camera screen.
class CameraDisposed extends CameraEvent {
  const CameraDisposed();
}

/// Internal: session stream fan-in (not for UI dispatch).
class CameraSessionUpdated extends CameraEvent {
  /// Latest session snapshot.
  final CameraSession session;

  /// Creates [CameraSessionUpdated].
  const CameraSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}
