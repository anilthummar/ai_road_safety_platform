import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/inference_repository.dart';

/// Loads the TFLite engine and labels.
class InitializeInferenceUseCase
    extends UseCase<Result<InferenceSession>, NoParams> {
  final InferenceRepository _repository;

  /// Creates [InitializeInferenceUseCase].
  InitializeInferenceUseCase(this._repository);

  @override
  Future<Result<InferenceSession>> call(NoParams params) {
    return _repository.initialize();
  }
}

/// Starts real-time inference on the camera frame pipe.
class StartInferenceUseCase extends UseCase<Result<InferenceSession>, NoParams> {
  final InferenceRepository _repository;

  /// Creates [StartInferenceUseCase].
  StartInferenceUseCase(this._repository);

  @override
  Future<Result<InferenceSession>> call(NoParams params) {
    return _repository.start();
  }
}

/// Stops real-time inference while keeping the model loaded.
class StopInferenceUseCase extends UseCase<Result<InferenceSession>, NoParams> {
  final InferenceRepository _repository;

  /// Creates [StopInferenceUseCase].
  StopInferenceUseCase(this._repository);

  @override
  Future<Result<InferenceSession>> call(NoParams params) {
    return _repository.stop();
  }
}

/// Tears down the inference engine.
class DisposeInferenceUseCase extends UseCase<Result<void>, NoParams> {
  final InferenceRepository _repository;

  /// Creates [DisposeInferenceUseCase].
  DisposeInferenceUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.disposeEngine();
  }
}

/// One-shot detection use case for unit / integration tests.
class DetectFrameUseCase
    extends UseCase<Result<InferenceResult>, CameraRawFrame> {
  final InferenceRepository _repository;

  /// Creates [DetectFrameUseCase].
  DetectFrameUseCase(this._repository);

  @override
  Future<Result<InferenceResult>> call(CameraRawFrame params) {
    return _repository.detect(params);
  }
}
