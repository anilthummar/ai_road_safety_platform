import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:equatable/equatable.dart';

/// Camera feature states.
sealed class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class CameraInitial extends CameraState {
  const CameraInitial();
}

/// Loading / initializing hardware or permission prompt in progress.
class CameraLoading extends CameraState {
  /// Optional status message for the loading indicator.
  final String message;

  /// Creates [CameraLoading].
  const CameraLoading({this.message = 'Starting camera…'});

  @override
  List<Object?> get props => [message];
}

/// Permission was denied (or permanently denied).
class CameraPermissionDenied extends CameraState {
  /// Whether the user must open system settings.
  final bool isPermanentlyDenied;

  /// User-facing message.
  final String message;

  /// Creates [CameraPermissionDenied].
  const CameraPermissionDenied({
    required this.isPermanentlyDenied,
    this.message = 'Camera permission is required for hazard detection.',
  });

  @override
  List<Object?> get props => [isPermanentlyDenied, message];
}

/// Camera is ready with an active preview session.
class CameraReady extends CameraState {
  /// Domain session metadata.
  final CameraSession session;

  /// Creates [CameraReady].
  const CameraReady({required this.session});

  /// Convenience flags.
  bool get isPaused => session.isPaused;

  /// Whether frame metadata streaming is active.
  bool get isStreaming => session.isStreamingFrames;

  /// Copy helper.
  CameraReady copyWith({CameraSession? session}) {
    return CameraReady(session: session ?? this.session);
  }

  @override
  List<Object?> get props => [session];
}

/// Recoverable / fatal camera failure.
class CameraError extends CameraState {
  /// Domain failure for display.
  final Failure failure;

  /// Creates [CameraError].
  const CameraError(this.failure);

  @override
  List<Object?> get props => [failure];
}
