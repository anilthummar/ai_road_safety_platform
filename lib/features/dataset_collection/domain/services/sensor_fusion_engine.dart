import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:uuid/uuid.dart';

/// Time-aligns camera / GPS / IMU (+ sonar stub) into a fused sample.
class SensorFusionEngine {
  final Uuid _uuid;

  const SensorFusionEngine({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  FusedGpsSlice? mapGps(GpsFix? fix, DateTime at) {
    if (fix == null) return null;
    final age = at.difference(fix.timestamp).inMilliseconds.abs();
    return FusedGpsSlice(
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracyMeters: fix.accuracyMeters,
      speedKmh: fix.speedKmh,
      headingDegrees: fix.headingDegrees,
      timestamp: fix.timestamp.toUtc(),
      ageMs: age,
    );
  }

  FusedImuSlice? mapImu(ImuSample? sample, DateTime at) {
    if (sample == null) return null;
    final age = at.difference(sample.timestamp).inMilliseconds.abs();
    return FusedImuSlice(
      accelMagnitude: sample.accelerometer.magnitude,
      gyroMagnitude: sample.gyroscope.magnitude,
      tiltDegrees: sample.tiltDegrees,
      pitchDegrees: sample.orientation.pitchDegrees,
      rollDegrees: sample.orientation.rollDegrees,
      timestamp: sample.timestamp.toUtc(),
      ageMs: age,
    );
  }

  FusionChannelHealth healthFor({
    required DateTime? lastAt,
    required DateTime now,
    required int staleMs,
    bool disabled = false,
  }) {
    if (disabled) return FusionChannelHealth.disabled;
    if (lastAt == null) return FusionChannelHealth.missing;
    final age = now.difference(lastAt).inMilliseconds.abs();
    if (age > staleMs) return FusionChannelHealth.stale;
    return FusionChannelHealth.live;
  }

  List<FusionChannelStatus> buildChannelStatuses({
    required DateTime now,
    required SensorFusionConfig config,
    DateTime? lastCameraAt,
    DateTime? lastGpsAt,
    DateTime? lastImuAt,
    bool cameraEnabled = true,
    bool gpsEnabled = true,
    bool imuEnabled = true,
  }) {
    return [
      FusionChannelStatus(
        channel: FusionSensorChannel.camera,
        health: healthFor(
          lastAt: lastCameraAt,
          now: now,
          staleMs: config.cameraStaleMs,
          disabled: !cameraEnabled,
        ),
        lastSampleAt: lastCameraAt,
        ageMs: lastCameraAt == null
            ? 0
            : now.difference(lastCameraAt).inMilliseconds.abs(),
        detail: cameraEnabled ? 'Frame clock' : 'Camera off',
      ),
      FusionChannelStatus(
        channel: FusionSensorChannel.gps,
        health: healthFor(
          lastAt: lastGpsAt,
          now: now,
          staleMs: config.gpsStaleMs,
          disabled: !gpsEnabled,
        ),
        lastSampleAt: lastGpsAt,
        ageMs: lastGpsAt == null
            ? 0
            : now.difference(lastGpsAt).inMilliseconds.abs(),
        detail: gpsEnabled ? 'GNSS fixes' : 'GPS off',
      ),
      FusionChannelStatus(
        channel: FusionSensorChannel.imu,
        health: healthFor(
          lastAt: lastImuAt,
          now: now,
          staleMs: config.imuStaleMs,
          disabled: !imuEnabled,
        ),
        lastSampleAt: lastImuAt,
        ageMs: lastImuAt == null
            ? 0
            : now.difference(lastImuAt).inMilliseconds.abs(),
        detail: imuEnabled ? 'Accel / gyro' : 'IMU off',
      ),
      const FusionChannelStatus(
        channel: FusionSensorChannel.sonar,
        health: FusionChannelHealth.disabled,
        ageMs: 0,
        detail: 'Reserved for future sonar',
      ),
    ];
  }

  /// Fuse latest sensor caches onto [at] (usually a camera or tick timestamp).
  FusedSample fuse({
    required DateTime at,
    FusedCameraRef? camera,
    GpsFix? gpsFix,
    ImuSample? imuSample,
    FusedSonarSlice sonar = const FusedSonarSlice.unavailable(),
    SensorFusionConfig config = SensorFusionConfig.defaults,
    String notes = '',
  }) {
    final gps = mapGps(gpsFix, at);
    final imu = mapImu(imuSample, at);
    final sources = <FusionSensorChannel>[
      if (camera != null) FusionSensorChannel.camera,
      if (gps != null) FusionSensorChannel.gps,
      if (imu != null) FusionSensorChannel.imu,
      if (sonar.available) FusionSensorChannel.sonar,
    ];

    var score = 0.0;
    // Completeness — core trio = camera + gps + imu (sonar optional / future).
    if (camera != null) score += 30;
    if (gps != null) score += 35;
    if (imu != null) score += 25;
    if (sonar.available) score += 10;

    // Freshness penalties.
    if (gps != null) {
      final ratio = (gps.ageMs / config.gpsStaleMs).clamp(0.0, 1.5);
      score -= 15 * ratio;
      if (gps.accuracyMeters > 25) score -= 8;
    }
    if (imu != null) {
      final ratio = (imu.ageMs / config.imuStaleMs).clamp(0.0, 1.5);
      score -= 12 * ratio;
    }
    if (camera != null) {
      final age = at.difference(camera.timestamp).inMilliseconds.abs();
      final ratio = (age / config.cameraStaleMs).clamp(0.0, 1.5);
      score -= 8 * ratio;
    }

    score = score.clamp(0.0, 100.0);
    final band = score >= 75
        ? FusionQualityBand.high
        : score >= 50
            ? FusionQualityBand.medium
            : score >= 25
                ? FusionQualityBand.low
                : FusionQualityBand.incomplete;

    return FusedSample(
      id: _uuid.v4(),
      timestamp: at.toUtc(),
      camera: camera,
      gps: gps,
      imu: imu,
      sonar: sonar,
      qualityScore: score,
      qualityBand: band,
      sourcesPresent: sources,
      notes: notes,
    );
  }
}
