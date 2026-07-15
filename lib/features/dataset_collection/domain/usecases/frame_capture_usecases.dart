import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';

/// Starts the frame acquisition engine for a dataset session.
class StartFrameCaptureUseCase
    extends UseCase<Result<void>, StartFrameCaptureParams> {
  final FrameCaptureRepository _repository;

  /// Creates [StartFrameCaptureUseCase].
  StartFrameCaptureUseCase(this._repository);

  @override
  Future<Result<void>> call(StartFrameCaptureParams params) {
    return _repository.startCapture(params);
  }
}

/// Stops the acquisition engine.
class StopFrameCaptureUseCase extends UseCase<Result<void>, NoParams> {
  final FrameCaptureRepository _repository;

  /// Creates [StopFrameCaptureUseCase].
  StopFrameCaptureUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.stopCapture();
}

/// Pauses automatic / manual intake.
class PauseFrameCaptureUseCase extends UseCase<Result<void>, NoParams> {
  final FrameCaptureRepository _repository;

  /// Creates [PauseFrameCaptureUseCase].
  PauseFrameCaptureUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.pauseCapture();
}

/// Resumes intake after pause.
class ResumeFrameCaptureUseCase extends UseCase<Result<void>, NoParams> {
  final FrameCaptureRepository _repository;

  /// Creates [ResumeFrameCaptureUseCase].
  ResumeFrameCaptureUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.resumeCapture();
}

/// Triggers a single manual capture.
class CaptureSingleFrameUseCase
    extends UseCase<Result<CapturedFrame>, NoParams> {
  final FrameCaptureRepository _repository;

  /// Creates [CaptureSingleFrameUseCase].
  CaptureSingleFrameUseCase(this._repository);

  @override
  Future<Result<CapturedFrame>> call(NoParams params) {
    return _repository.captureFrame();
  }
}

/// Enqueues a [CapturedFrame] into the memory queue.
class EnqueueFrameUseCase
    extends UseCase<Result<CapturedFrame>, CapturedFrame> {
  final FrameCaptureRepository _repository;

  /// Creates [EnqueueFrameUseCase].
  EnqueueFrameUseCase(this._repository);

  @override
  Future<Result<CapturedFrame>> call(CapturedFrame params) {
    return _repository.enqueueFrame(params);
  }
}

/// Dequeues the oldest frame.
class DequeueFrameUseCase extends UseCase<Result<CapturedFrame?>, NoParams> {
  final FrameCaptureRepository _repository;

  /// Creates [DequeueFrameUseCase].
  DequeueFrameUseCase(this._repository);

  @override
  Future<Result<CapturedFrame?>> call(NoParams params) {
    return _repository.dequeueFrame();
  }
}

/// Clears the in-memory frame queue.
class ClearFrameQueueUseCase extends UseCase<Result<void>, NoParams> {
  final FrameCaptureRepository _repository;

  /// Creates [ClearFrameQueueUseCase].
  ClearFrameQueueUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.clearQueue();
}
