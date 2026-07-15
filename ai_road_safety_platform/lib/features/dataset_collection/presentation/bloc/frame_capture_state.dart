import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:equatable/equatable.dart';

/// Frame acquisition presentation states (Phase 12.3).
sealed class FrameCaptureState extends Equatable {
  const FrameCaptureState();

  @override
  List<Object?> get props => [];
}

/// Cold start.
final class FrameCaptureInitial extends FrameCaptureState {
  const FrameCaptureInitial();
}

/// Actively acquiring frames.
final class FrameCaptureCapturing extends FrameCaptureState {
  /// Bound dataset session.
  final String sessionId;

  /// Queue snapshot.
  final FrameQueueSnapshot queue;

  /// Last admitted frame (optional).
  final CapturedFrame? lastFrame;

  /// Creates [FrameCaptureCapturing].
  const FrameCaptureCapturing({
    required this.sessionId,
    required this.queue,
    this.lastFrame,
  });

  /// Copy helper.
  FrameCaptureCapturing copyWith({
    String? sessionId,
    FrameQueueSnapshot? queue,
    CapturedFrame? lastFrame,
  }) {
    return FrameCaptureCapturing(
      sessionId: sessionId ?? this.sessionId,
      queue: queue ?? this.queue,
      lastFrame: lastFrame ?? this.lastFrame,
    );
  }

  @override
  List<Object?> get props => [sessionId, queue, lastFrame];
}

/// Acquisition paused.
final class FrameCapturePaused extends FrameCaptureState {
  /// Bound dataset session.
  final String sessionId;

  /// Queue snapshot.
  final FrameQueueSnapshot queue;

  /// Creates [FrameCapturePaused].
  const FrameCapturePaused({
    required this.sessionId,
    required this.queue,
  });

  @override
  List<Object?> get props => [sessionId, queue];
}

/// Capture stopped / idle with last known queue.
final class FrameCaptureStopped extends FrameCaptureState {
  /// Queue snapshot after stop.
  final FrameQueueSnapshot queue;

  /// Creates [FrameCaptureStopped].
  const FrameCaptureStopped({
    this.queue = const FrameQueueSnapshot.empty(),
  });

  @override
  List<Object?> get props => [queue];
}

/// Transient: queue metrics tick (UI may prefer capturing/paused).
final class FrameCaptureQueueUpdatedState extends FrameCaptureState {
  /// Snapshot.
  final FrameQueueSnapshot snapshot;

  /// Creates [FrameCaptureQueueUpdatedState].
  const FrameCaptureQueueUpdatedState(this.snapshot);

  @override
  List<Object?> get props => [snapshot];
}

/// Transient: a frame was just captured.
final class FrameCaptureFrameCaptured extends FrameCaptureState {
  /// Frame.
  final CapturedFrame frame;

  /// Queue after capture.
  final FrameQueueSnapshot queue;

  /// Creates [FrameCaptureFrameCaptured].
  const FrameCaptureFrameCaptured({
    required this.frame,
    required this.queue,
  });

  @override
  List<Object?> get props => [frame, queue];
}

/// Failure.
final class FrameCaptureError extends FrameCaptureState {
  /// Failure.
  final Failure failure;

  /// Creates [FrameCaptureError].
  const FrameCaptureError(this.failure);

  @override
  List<Object?> get props => [failure];
}
