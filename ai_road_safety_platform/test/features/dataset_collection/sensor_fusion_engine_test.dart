import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/sensor_fusion_engine.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = SensorFusionEngine();

  final now = DateTime.utc(2026, 7, 14, 12);

  test('fuse with camera gps imu scores high', () {
    final sample = engine.fuse(
      at: now,
      camera: FusedCameraRef(timestamp: now, sequence: 1),
      gpsFix: GpsFix(
        latitude: 23,
        longitude: 72,
        accuracyMeters: 5,
        timestamp: now.subtract(const Duration(milliseconds: 100)),
      ),
      imuSample: ImuSample(
        accelerometer: const ImuVector3(x: 0, y: 0, z: 9.8),
        gyroscope: const ImuVector3.zero(),
        magnetometer: const ImuVector3.zero(),
        orientation: const ImuOrientation(pitchDegrees: 0, rollDegrees: 0),
        tiltDegrees: 1,
        vibration: const VibrationMetrics.calm(),
        timestamp: now.subtract(const Duration(milliseconds: 50)),
      ),
    );
    expect(sample.sourcesPresent, contains(FusionSensorChannel.camera));
    expect(sample.sourcesPresent, contains(FusionSensorChannel.gps));
    expect(sample.sourcesPresent, contains(FusionSensorChannel.imu));
    expect(sample.qualityScore, greaterThan(70));
    expect(sample.sonar.available, isFalse);
  });

  test('stale gps lowers score', () {
    final fresh = engine.fuse(
      at: now,
      gpsFix: GpsFix(
        latitude: 1,
        longitude: 2,
        accuracyMeters: 5,
        timestamp: now.subtract(const Duration(milliseconds: 100)),
      ),
    );
    final stale = engine.fuse(
      at: now,
      gpsFix: GpsFix(
        latitude: 1,
        longitude: 2,
        accuracyMeters: 5,
        timestamp: now.subtract(const Duration(seconds: 10)),
      ),
    );
    expect(stale.qualityScore, lessThan(fresh.qualityScore));
  });

  test('channel health marks sonar disabled', () {
    final channels = engine.buildChannelStatuses(
      now: now,
      config: SensorFusionConfig.defaults,
    );
    final sonar = channels.firstWhere(
      (c) => c.channel == FusionSensorChannel.sonar,
    );
    expect(sonar.health, FusionChannelHealth.disabled);
  });

  test('FusedSample json round-trip', () {
    final sample = engine.fuse(
      at: now,
      camera: FusedCameraRef(timestamp: now, sequence: 3),
      gpsFix: GpsFix(
        latitude: 10,
        longitude: 20,
        accuracyMeters: 3,
        timestamp: now,
      ),
    );
    expect(FusedSample.fromJson(sample.toJson()).qualityBand, sample.qualityBand);
  });
}
