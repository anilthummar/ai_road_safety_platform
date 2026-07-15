import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';

/// Checks camera permission without presenting a system dialog.
class CheckCameraPermissionUseCase
    extends UseCase<Result<CameraPermissionStatus>, NoParams> {
  final CameraRepository _repository;

  /// Creates [CheckCameraPermissionUseCase].
  CheckCameraPermissionUseCase(this._repository);

  @override
  Future<Result<CameraPermissionStatus>> call(NoParams params) {
    return _repository.checkPermission();
  }
}

/// Requests camera permission from the OS.
class RequestCameraPermissionUseCase
    extends UseCase<Result<CameraPermissionStatus>, NoParams> {
  final CameraRepository _repository;

  /// Creates [RequestCameraPermissionUseCase].
  RequestCameraPermissionUseCase(this._repository);

  @override
  Future<Result<CameraPermissionStatus>> call(NoParams params) {
    return _repository.requestPermission();
  }
}

/// Opens OS settings so the user can grant camera access manually.
class OpenCameraPermissionSettingsUseCase
    extends UseCase<Result<bool>, NoParams> {
  final CameraRepository _repository;

  /// Creates [OpenCameraPermissionSettingsUseCase].
  OpenCameraPermissionSettingsUseCase(this._repository);

  @override
  Future<Result<bool>> call(NoParams params) {
    return _repository.openPermissionSettings();
  }
}

/// Parameters for camera initialization.
class InitializeCameraParams {
  /// Preferred lens; defaults to rear for road-facing capture.
  final CameraLensPreference lens;

  /// Creates [InitializeCameraParams].
  const InitializeCameraParams({
    this.lens = CameraLensPreference.rear,
  });
}

/// Initializes rear (or selected) camera for live preview.
class InitializeCameraUseCase
    extends UseCase<Result<CameraSession>, InitializeCameraParams> {
  final CameraRepository _repository;

  /// Creates [InitializeCameraUseCase].
  InitializeCameraUseCase(this._repository);

  @override
  Future<Result<CameraSession>> call(InitializeCameraParams params) {
    return _repository.initialize(lens: params.lens);
  }
}

/// Pauses camera when the app backgrounds or the user requests pause.
class PauseCameraUseCase extends UseCase<Result<CameraSession>, NoParams> {
  final CameraRepository _repository;

  /// Creates [PauseCameraUseCase].
  PauseCameraUseCase(this._repository);

  @override
  Future<Result<CameraSession>> call(NoParams params) {
    return _repository.pause();
  }
}

/// Resumes camera after pause / return to foreground.
class ResumeCameraUseCase extends UseCase<Result<CameraSession>, NoParams> {
  final CameraRepository _repository;

  /// Creates [ResumeCameraUseCase].
  ResumeCameraUseCase(this._repository);

  @override
  Future<Result<CameraSession>> call(NoParams params) {
    return _repository.resume();
  }
}

/// Parameters for starting throttled frame streaming.
class StartFrameStreamingParams {
  /// Target frames per second for metadata emissions (memory-safe).
  final int targetFps;

  /// Creates [StartFrameStreamingParams].
  const StartFrameStreamingParams({this.targetFps = 8});
}

/// Starts memory-optimized frame metadata streaming (no AI).
class StartFrameStreamingUseCase
    extends UseCase<Result<CameraSession>, StartFrameStreamingParams> {
  final CameraRepository _repository;

  /// Creates [StartFrameStreamingUseCase].
  StartFrameStreamingUseCase(this._repository);

  @override
  Future<Result<CameraSession>> call(StartFrameStreamingParams params) {
    return _repository.startFrameStreaming(targetFps: params.targetFps);
  }
}

/// Stops frame streaming while optionally keeping preview alive.
class StopFrameStreamingUseCase
    extends UseCase<Result<CameraSession>, NoParams> {
  final CameraRepository _repository;

  /// Creates [StopFrameStreamingUseCase].
  StopFrameStreamingUseCase(this._repository);

  @override
  Future<Result<CameraSession>> call(NoParams params) {
    return _repository.stopFrameStreaming();
  }
}

/// Releases camera resources when leaving the camera feature.
class DisposeCameraUseCase extends UseCase<Result<void>, NoParams> {
  final CameraRepository _repository;

  /// Creates [DisposeCameraUseCase].
  DisposeCameraUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.disposeCamera();
  }
}

/// Parameters for orientation updates.
class CameraOrientationParams {
  /// Device orientation in degrees (0, 90, 180, 270).
  final int degrees;

  /// Creates [CameraOrientationParams].
  const CameraOrientationParams(this.degrees);
}

/// Applies device rotation to the camera session.
class HandleCameraOrientationUseCase
    extends UseCase<Result<CameraSession>, CameraOrientationParams> {
  final CameraRepository _repository;

  /// Creates [HandleCameraOrientationUseCase].
  HandleCameraOrientationUseCase(this._repository);

  @override
  Future<Result<CameraSession>> call(CameraOrientationParams params) {
    return _repository.handleOrientationChanged(params.degrees);
  }
}
