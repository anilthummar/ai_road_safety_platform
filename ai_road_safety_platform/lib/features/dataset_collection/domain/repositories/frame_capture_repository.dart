import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:equatable/equatable.dart';

/// Parameters for starting the acquisition engine bound to a dataset session.
class StartFrameCaptureParams extends Equatable {
  /// Dataset recording session id.
  final String sessionId;

  /// Camera lens label stored on captured frames.
  final String lensDirection;

  /// Sensor rotation degrees.
  final int rotationDegrees;

  /// Creates [StartFrameCaptureParams].
  const StartFrameCaptureParams({
    required this.sessionId,
    this.lensDirection = 'rear',
    this.rotationDegrees = 0,
  });

  @override
  List<Object?> get props => [sessionId, lensDirection, rotationDegrees];
}

/// Domain contract for the intelligent data acquisition engine (Phase 12.3).
abstract class FrameCaptureRepository {
  /// Captures a single frame using the manual rule (session must be active).
  Future<Result<CapturedFrame>> captureFrame();

  /// Enqueues an already-built frame (pipeline / tests).
  Future<Result<CapturedFrame>> enqueueFrame(CapturedFrame frame);

  /// Dequeues the oldest frame.
  Future<Result<CapturedFrame?>> dequeueFrame();

  /// Clears the in-memory queue.
  Future<Result<void>> clearQueue();

  /// Current queue length.
  Future<Result<int>> queueSize();

  /// Starts camera metadata intake + rule evaluation for [params.sessionId].
  Future<Result<void>> startCapture(StartFrameCaptureParams params);

  /// Stops intake and resets rules (queue optionally retained until cleared).
  Future<Result<void>> stopCapture();

  /// Pauses automatic intake (manual also blocked while paused).
  Future<Result<void>> pauseCapture();

  /// Resumes after [pauseCapture].
  Future<Result<void>> resumeCapture();

  /// Live queue / counters for UI.
  Stream<FrameQueueSnapshot> watchQueue();

  /// Emits each successfully enqueued frame (no disk I/O).
  Stream<CapturedFrame> watchCapturedFrames();

  /// Whether the engine is currently capturing.
  bool get isCapturing;

  /// Whether the engine is paused.
  bool get isPaused;
}
