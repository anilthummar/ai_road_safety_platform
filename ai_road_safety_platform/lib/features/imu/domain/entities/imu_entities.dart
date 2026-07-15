import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Qualitative vehicle vibration intensity.
enum VibrationIntensity {
  /// Near-still.
  calm,

  /// Normal road vibration.
  moderate,

  /// Rough surface / pothole-like.
  rough,

  /// Severe shock.
  severe,
}

/// 3-axis vector in SI units (m/s² or rad/s or µT).
class ImuVector3 extends Equatable {
  /// X axis.
  final double x;

  /// Y axis.
  final double y;

  /// Z axis.
  final double z;

  /// Creates [ImuVector3].
  const ImuVector3({required this.x, required this.y, required this.z});

  /// Zero vector.
  const ImuVector3.zero() : x = 0, y = 0, z = 0;

  /// Euclidean magnitude.
  double get magnitude => math.sqrt(x * x + y * y + z * z);

  /// Unit vector (zero if magnitude is tiny).
  ImuVector3 get normalized {
    final m = magnitude;
    if (m < 1e-9) return const ImuVector3.zero();
    return ImuVector3(x: x / m, y: y / m, z: z / m);
  }

  /// Dot product.
  double dot(ImuVector3 other) => x * other.x + y * other.y + z * other.z;

  /// Subtract [other].
  ImuVector3 operator -(ImuVector3 other) =>
      ImuVector3(x: x - other.x, y: y - other.y, z: z - other.z);

  /// Add [other].
  ImuVector3 operator +(ImuVector3 other) =>
      ImuVector3(x: x + other.x, y: y + other.y, z: z + other.z);

  /// Scale by [factor].
  ImuVector3 operator *(double factor) =>
      ImuVector3(x: x * factor, y: y * factor, z: z * factor);

  @override
  List<Object?> get props => [x, y, z];
}

/// Device orientation derived from IMU (degrees).
class ImuOrientation extends Equatable {
  /// Pitch (nose up/down) in degrees.
  final double pitchDegrees;

  /// Roll (wing up/down) in degrees.
  final double rollDegrees;

  /// Yaw / magnetic heading in degrees \[0–360), nullable if magnetometer weak.
  final double? yawDegrees;

  /// Creates [ImuOrientation].
  const ImuOrientation({
    required this.pitchDegrees,
    required this.rollDegrees,
    this.yawDegrees,
  });

  @override
  List<Object?> get props => [pitchDegrees, rollDegrees, yawDegrees];
}

/// Bias offsets measured during rest calibration.
class ImuCalibration extends Equatable {
  /// Accelerometer bias (m/s²).
  final ImuVector3 accelerometerBias;

  /// Gyroscope bias (rad/s).
  final ImuVector3 gyroscopeBias;

  /// Samples used to estimate bias.
  final int samplesUsed;

  /// When calibration completed.
  final DateTime? calibratedAt;

  /// Creates [ImuCalibration].
  const ImuCalibration({
    required this.accelerometerBias,
    required this.gyroscopeBias,
    required this.samplesUsed,
    this.calibratedAt,
  });

  /// Uncalibrated defaults.
  const ImuCalibration.uncalibrated()
      : accelerometerBias = const ImuVector3.zero(),
        gyroscopeBias = const ImuVector3.zero(),
        samplesUsed = 0,
        calibratedAt = null;

  /// Whether a rest calibration has been applied.
  bool get isCalibrated => calibratedAt != null && samplesUsed > 0;

  @override
  List<Object?> get props => [
        accelerometerBias,
        gyroscopeBias,
        samplesUsed,
        calibratedAt,
      ];
}

/// Vibration metrics for vehicle / road roughness.
class VibrationMetrics extends Equatable {
  /// RMS of linear acceleration deviation from gravity (m/s²).
  final double rms;

  /// Peak absolute deviation in the analysis window (m/s²).
  final double peak;

  /// Qualitative intensity band.
  final VibrationIntensity intensity;

  /// Creates [VibrationMetrics].
  const VibrationMetrics({
    required this.rms,
    required this.peak,
    required this.intensity,
  });

  /// Quiet factory.
  const VibrationMetrics.calm()
      : rms = 0,
        peak = 0,
        intensity = VibrationIntensity.calm;

  @override
  List<Object?> get props => [rms, peak, intensity];
}

/// Fused IMU sample emitted at a throttled UI/analysis rate.
class ImuSample extends Equatable {
  /// Calibrated accelerometer (m/s²).
  final ImuVector3 accelerometer;

  /// Calibrated gyroscope (rad/s).
  final ImuVector3 gyroscope;

  /// Magnetometer (µT).
  final ImuVector3 magnetometer;

  /// Pitch / roll / yaw.
  final ImuOrientation orientation;

  /// Absolute tilt from upright (degrees), 0 = flat upright Z-up approximation.
  final double tiltDegrees;

  /// Vehicle vibration estimate.
  final VibrationMetrics vibration;

  /// Capture timestamp.
  final DateTime timestamp;

  /// Creates [ImuSample].
  const ImuSample({
    required this.accelerometer,
    required this.gyroscope,
    required this.magnetometer,
    required this.orientation,
    required this.tiltDegrees,
    required this.vibration,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        accelerometer,
        gyroscope,
        magnetometer,
        orientation,
        tiltDegrees,
        vibration,
        timestamp,
      ];
}

/// Live IMU session snapshot.
class ImuSession extends Equatable {
  /// Whether sensor streams are active.
  final bool isStreaming;

  /// Whether a rest calibration is currently collecting samples.
  final bool isCalibrating;

  /// Calibration progress 0–1 while calibrating.
  final double calibrationProgress;

  /// Current calibration offsets.
  final ImuCalibration calibration;

  /// Latest fused sample.
  final ImuSample? latestSample;

  /// Creates [ImuSession].
  const ImuSession({
    required this.isStreaming,
    required this.isCalibrating,
    required this.calibration,
    this.calibrationProgress = 0,
    this.latestSample,
  });

  /// Idle factory.
  const ImuSession.idle()
      : isStreaming = false,
        isCalibrating = false,
        calibrationProgress = 0,
        calibration = const ImuCalibration.uncalibrated(),
        latestSample = null;

  /// Copy helper.
  ImuSession copyWith({
    bool? isStreaming,
    bool? isCalibrating,
    double? calibrationProgress,
    ImuCalibration? calibration,
    ImuSample? latestSample,
    bool clearSample = false,
  }) {
    return ImuSession(
      isStreaming: isStreaming ?? this.isStreaming,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      calibrationProgress: calibrationProgress ?? this.calibrationProgress,
      calibration: calibration ?? this.calibration,
      latestSample: clearSample ? null : (latestSample ?? this.latestSample),
    );
  }

  @override
  List<Object?> get props => [
        isStreaming,
        isCalibrating,
        calibrationProgress,
        calibration,
        latestSample,
      ];
}

/// IMU sampling / calibration constants.
class ImuConfig {
  ImuConfig._();

  /// Sensor hardware interval (~50 Hz).
  static const Duration sensorInterval = Duration(milliseconds: 20);

  /// Max fused sample emit rate to Bloc/UI (~12.5 Hz) — performance guard.
  static const Duration emitInterval = Duration(milliseconds: 80);

  /// Rest calibration duration.
  static const Duration calibrationDuration = Duration(seconds: 2);

  /// Rolling window for vibration RMS (~0.5 s at 50 Hz).
  static const int vibrationWindowSize = 25;

  /// Samples to average when locking rest gravity (mount pose).
  static const int restBaselineSamples = 25;

  /// SharedPreferences keys.
  static const String prefsAccelBiasX = 'imu.accel_bias_x';
  static const String prefsAccelBiasY = 'imu.accel_bias_y';
  static const String prefsAccelBiasZ = 'imu.accel_bias_z';
  static const String prefsGyroBiasX = 'imu.gyro_bias_x';
  static const String prefsGyroBiasY = 'imu.gyro_bias_y';
  static const String prefsGyroBiasZ = 'imu.gyro_bias_z';
  static const String prefsCalibratedAt = 'imu.calibrated_at';
  static const String prefsSamplesUsed = 'imu.samples_used';
}
