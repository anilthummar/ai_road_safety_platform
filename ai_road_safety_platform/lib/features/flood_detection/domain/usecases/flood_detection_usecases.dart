import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';

/// Loads the flood segmentation engine.
class InitializeFloodDetectionUseCase
    extends UseCase<Result<FloodDetectionSession>, NoParams> {
  final FloodDetectionRepository _repository;

  /// Creates [InitializeFloodDetectionUseCase].
  InitializeFloodDetectionUseCase(this._repository);

  @override
  Future<Result<FloodDetectionSession>> call(NoParams params) {
    return _repository.initialize();
  }
}

/// Starts live flood segmentation.
class StartFloodDetectionUseCase
    extends UseCase<Result<FloodDetectionSession>, NoParams> {
  final FloodDetectionRepository _repository;

  /// Creates [StartFloodDetectionUseCase].
  StartFloodDetectionUseCase(this._repository);

  @override
  Future<Result<FloodDetectionSession>> call(NoParams params) {
    return _repository.start();
  }
}

/// Stops live flood segmentation.
class StopFloodDetectionUseCase
    extends UseCase<Result<FloodDetectionSession>, NoParams> {
  final FloodDetectionRepository _repository;

  /// Creates [StopFloodDetectionUseCase].
  StopFloodDetectionUseCase(this._repository);

  @override
  Future<Result<FloodDetectionSession>> call(NoParams params) {
    return _repository.stop();
  }
}

/// Disposes the flood segmentation engine.
class DisposeFloodDetectionUseCase extends UseCase<Result<void>, NoParams> {
  final FloodDetectionRepository _repository;

  /// Creates [DisposeFloodDetectionUseCase].
  DisposeFloodDetectionUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.disposeEngine();
  }
}

/// One-shot frame segmentation.
class SegmentFloodFrameUseCase
    extends UseCase<Result<FloodSegmentationResult>, CameraRawFrame> {
  final FloodDetectionRepository _repository;

  /// Creates [SegmentFloodFrameUseCase].
  SegmentFloodFrameUseCase(this._repository);

  @override
  Future<Result<FloodSegmentationResult>> call(CameraRawFrame params) {
    return _repository.segment(params);
  }
}
