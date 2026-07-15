import 'dart:math' as math;

import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';

/// Derives pitch / roll / yaw and tilt from accelerometer + magnetometer.
class ImuOrientationProcessor {
  /// Creates [ImuOrientationProcessor].
  const ImuOrientationProcessor();

  /// Computes orientation and lean relative to an optional rest gravity baseline.
  ///
  /// When [restGravityUnit] is set (mount pose at stream start), [tiltDegrees] is
  /// the angle between current gravity and that baseline — phone stand / dash
  /// mounts stay near 0°. Without a baseline, lean vs the nearest device axis
  /// is used (table / portrait / landscape ≈ 0° when axis-aligned).
  ({ImuOrientation orientation, double tiltDegrees}) process({
    required ImuVector3 accelerometer,
    required ImuVector3 magnetometer,
    ImuVector3? restGravityUnit,
  }) {
    final ax = accelerometer.x;
    final ay = accelerometer.y;
    final az = accelerometer.z;

    final pitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    final roll = math.atan2(ay, az);

    final pitchDeg = pitch * _radToDeg;
    final rollDeg = roll * _radToDeg;

    final mag = accelerometer.magnitude;
    final tiltDeg = mag < 1e-3
        ? 0.0
        : _leanDegrees(
            gravityUnit: accelerometer.normalized,
            restGravityUnit: restGravityUnit,
          );

    final yaw = _magneticHeading(
      magnetometer: magnetometer,
      pitch: pitch,
      roll: roll,
    );

    return (
      orientation: ImuOrientation(
        pitchDegrees: pitchDeg,
        rollDegrees: rollDeg,
        yawDegrees: yaw,
      ),
      tiltDegrees: tiltDeg,
    );
  }

  double _leanDegrees({
    required ImuVector3 gravityUnit,
    ImuVector3? restGravityUnit,
  }) {
    final reference = restGravityUnit;
    if (reference != null && reference.magnitude > 0.5) {
      final cos = gravityUnit.dot(reference.normalized).clamp(-1.0, 1.0);
      return math.acos(cos) * _radToDeg;
    }
    // Absolute: angle from nearest axis (legacy / pre-baseline).
    final maxAlign = math.max(
      gravityUnit.x.abs(),
      math.max(gravityUnit.y.abs(), gravityUnit.z.abs()),
    );
    return math.acos(maxAlign.clamp(0.0, 1.0)) * _radToDeg;
  }

  double? _magneticHeading({
    required ImuVector3 magnetometer,
    required double pitch,
    required double roll,
  }) {
    final mx = magnetometer.x;
    final my = magnetometer.y;
    final mz = magnetometer.z;
    if (magnetometer.magnitude < 1e-3) {
      return null;
    }

    final cosR = math.cos(roll);
    final sinR = math.sin(roll);
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    // Tilt-compensated magnetometer → heading.
    final xh = mx * cosP + mz * sinP;
    final yh = mx * sinR * sinP + my * cosR - mz * sinR * cosP;
    var heading = math.atan2(-yh, xh) * _radToDeg;
    if (heading < 0) {
      heading += 360;
    }
    return heading;
  }

  static const double _radToDeg = 180 / math.pi;
}

/// Rolling-window vibration estimate (RMS / peak of linear accel).
class VibrationProcessor {
  /// Creates [VibrationProcessor].
  VibrationProcessor({this.windowSize = ImuConfig.vibrationWindowSize});

  /// Sample count in the circular buffer.
  final int windowSize;

  final List<double> _linearMags = <double>[];

  /// Clears the analysis window.
  void reset() => _linearMags.clear();

  /// Updates with calibrated accelerometer sample and returns metrics.
  VibrationMetrics update(ImuVector3 accelerometer) {
    // Remove gravity magnitude (~9.81) → linear accel magnitude estimate.
    const g = 9.80665;
    final linear = (accelerometer.magnitude - g).abs();
    _linearMags.add(linear);
    if (_linearMags.length > windowSize) {
      _linearMags.removeAt(0);
    }
    if (_linearMags.isEmpty) {
      return const VibrationMetrics.calm();
    }

    var sumSq = 0.0;
    var peak = 0.0;
    for (final v in _linearMags) {
      sumSq += v * v;
      if (v > peak) {
        peak = v;
      }
    }
    final rms = math.sqrt(sumSq / _linearMags.length);
    return VibrationMetrics(
      rms: rms,
      peak: peak,
      intensity: _band(rms),
    );
  }

  VibrationIntensity _band(double rms) {
    if (rms < 0.25) {
      return VibrationIntensity.calm;
    }
    if (rms < 0.8) {
      return VibrationIntensity.moderate;
    }
    if (rms < 1.8) {
      return VibrationIntensity.rough;
    }
    return VibrationIntensity.severe;
  }
}

/// Collects rest samples and averages bias for accel + gyro.
class ImuCalibrationCollector {
  /// Creates [ImuCalibrationCollector].
  ImuCalibrationCollector();

  final List<ImuVector3> _accel = <ImuVector3>[];
  final List<ImuVector3> _gyro = <ImuVector3>[];

  /// Whether collection is active.
  bool get isCollecting => _collecting;
  bool _collecting = false;

  /// Expected samples (~duration / sensorInterval).
  int get targetSamples =>
      ImuConfig.calibrationDuration.inMilliseconds ~/
      ImuConfig.sensorInterval.inMilliseconds;

  /// Progress 0–1.
  double get progress {
    if (targetSamples <= 0) {
      return 1;
    }
    return (_accel.length / targetSamples).clamp(0.0, 1.0);
  }

  /// Whether enough samples were collected.
  bool get isComplete => _accel.length >= targetSamples;

  /// Starts a new collection window.
  void start() {
    _accel.clear();
    _gyro.clear();
    _collecting = true;
  }

  /// Cancels without producing a result.
  void cancel() {
    _accel.clear();
    _gyro.clear();
    _collecting = false;
  }

  /// Adds a raw (uncalibrated) sample pair. Returns finished calibration if complete.
  ImuCalibration? addSample({
    required ImuVector3 accelerometer,
    required ImuVector3 gyroscope,
  }) {
    if (!_collecting) {
      return null;
    }
    _accel.add(accelerometer);
    _gyro.add(gyroscope);
    if (!isComplete) {
      return null;
    }
    _collecting = false;
    return finish();
  }

  /// Averages biases. Accel bias keeps gravity on Z when device is flat:
  /// we subtract mean of axis so calibrated at-rest ≈ (0,0,g) when flat.
  ImuCalibration finish() {
    final n = _accel.length;
    if (n == 0) {
      return const ImuCalibration.uncalibrated();
    }

    var ax = 0.0, ay = 0.0, az = 0.0;
    var gx = 0.0, gy = 0.0, gz = 0.0;
    for (var i = 0; i < n; i++) {
      ax += _accel[i].x;
      ay += _accel[i].y;
      az += _accel[i].z;
      gx += _gyro[i].x;
      gy += _gyro[i].y;
      gz += _gyro[i].z;
    }
    ax /= n;
    ay /= n;
    az /= n;
    gx /= n;
    gy /= n;
    gz /= n;

    // Prefer gravity-aligned rest: keep residual g on the dominant axis.
    final absX = ax.abs();
    final absY = ay.abs();
    final absZ = az.abs();
    const g = 9.80665;
    var biasX = ax;
    var biasY = ay;
    var biasZ = az;
    if (absZ >= absX && absZ >= absY) {
      biasZ = az - (az >= 0 ? g : -g);
    } else if (absY >= absX && absY >= absZ) {
      biasY = ay - (ay >= 0 ? g : -g);
    } else {
      biasX = ax - (ax >= 0 ? g : -g);
    }

    return ImuCalibration(
      accelerometerBias: ImuVector3(x: biasX, y: biasY, z: biasZ),
      gyroscopeBias: ImuVector3(x: gx, y: gy, z: gz),
      samplesUsed: n,
      calibratedAt: DateTime.now(),
    );
  }
}
