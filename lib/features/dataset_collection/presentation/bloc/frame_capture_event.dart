import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:equatable/equatable.dart';

/// Frame acquisition Bloc events (Phase 12.3).
sealed class FrameCaptureEvent extends Equatable {
  const FrameCaptureEvent();

  @override
  List<Object?> get props => [];
}

/// Start intake for a dataset session.
final class FrameCaptureStartCapture extends FrameCaptureEvent {
  /// Start params.
  final StartFrameCaptureParams params;

  /// Creates [FrameCaptureStartCapture].
  const FrameCaptureStartCapture(this.params);

  @override
  List<Object?> get props => [params];
}

/// Stop intake.
final class FrameCaptureStopCapture extends FrameCaptureEvent {
  const FrameCaptureStopCapture();
}

/// Pause intake.
final class FrameCapturePauseCapture extends FrameCaptureEvent {
  const FrameCapturePauseCapture();
}

/// Resume intake.
final class FrameCaptureResumeCapture extends FrameCaptureEvent {
  const FrameCaptureResumeCapture();
}

/// Manual capture button.
final class FrameCaptureManualCapture extends FrameCaptureEvent {
  const FrameCaptureManualCapture();
}

/// A frame was admitted (from repository stream).
final class FrameCaptureFrameReceived extends FrameCaptureEvent {
  /// Admitted frame.
  final CapturedFrame frame;

  /// Creates [FrameCaptureFrameReceived].
  const FrameCaptureFrameReceived(this.frame);

  @override
  List<Object?> get props => [frame];
}

/// Queue snapshot updated.
final class FrameCaptureQueueUpdated extends FrameCaptureEvent {
  /// Snapshot.
  final FrameQueueSnapshot snapshot;

  /// Creates [FrameCaptureQueueUpdated].
  const FrameCaptureQueueUpdated(this.snapshot);

  @override
  List<Object?> get props => [snapshot];
}

/// Clear queue.
final class FrameCaptureClearQueue extends FrameCaptureEvent {
  const FrameCaptureClearQueue();
}
