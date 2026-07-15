import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';

/// Starts fused IMU sensor streams.
class StartImuStreamingUseCase extends UseCase<Result<void>, NoParams> {
  final ImuRepository _repository;

  /// Creates [StartImuStreamingUseCase].
  StartImuStreamingUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.startStreaming();
  }
}

/// Stops fused IMU sensor streams.
class StopImuStreamingUseCase extends UseCase<Result<void>, NoParams> {
  final ImuRepository _repository;

  /// Creates [StopImuStreamingUseCase].
  StopImuStreamingUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.stopStreaming();
  }
}

/// Runs rest-state bias calibration.
class CalibrateImuUseCase extends UseCase<Result<ImuCalibration>, NoParams> {
  final ImuRepository _repository;

  /// Creates [CalibrateImuUseCase].
  CalibrateImuUseCase(this._repository);

  @override
  Future<Result<ImuCalibration>> call(NoParams params) {
    return _repository.calibrate();
  }
}

/// Releases IMU resources.
class DisposeImuUseCase extends UseCase<Result<void>, NoParams> {
  final ImuRepository _repository;

  /// Creates [DisposeImuUseCase].
  DisposeImuUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.dispose();
  }
}
