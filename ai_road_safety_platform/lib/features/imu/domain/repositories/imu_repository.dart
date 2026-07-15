import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';

/// Domain contract for IMU motion sensing.
abstract class ImuRepository {
  /// Session stream (streaming / calibrating / calibration meta).
  Stream<ImuSession> get sessionStream;

  /// Throttled fused samples.
  Stream<ImuSample> get sampleStream;

  /// Starts IMU streams.
  Future<Result<void>> startStreaming();

  /// Stops IMU streams.
  Future<Result<void>> stopStreaming();

  /// Rest calibration → persisted bias.
  Future<Result<ImuCalibration>> calibrate();

  /// Releases sensors.
  Future<Result<void>> dispose();
}
