import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';

/// Local IMU sensor access contract.
abstract class ImuLocalDataSource {
  /// Loaded or default calibration.
  ImuCalibration get calibration;

  /// Whether fused streams are running.
  bool get isStreaming;

  /// Whether rest calibration is collecting.
  bool get isCalibrating;

  /// Emits session changes (start/stop/calibration).
  Stream<ImuSession> get sessionStream;

  /// Throttled fused IMU samples.
  Stream<ImuSample> get sampleStream;

  /// Starts accelerometer / gyro / magnetometer streams.
  Future<void> startStreaming();

  /// Stops sensor streams.
  Future<void> stopStreaming();

  /// Holds still for [ImuConfig.calibrationDuration] and persists bias.
  Future<ImuCalibration> calibrate();

  /// Clears active subscriptions.
  Future<void> dispose();
}
