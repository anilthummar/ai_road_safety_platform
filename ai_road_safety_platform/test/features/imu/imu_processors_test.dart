import 'package:ai_road_safety_platform/features/imu/data/processors/imu_processors.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImuOrientationProcessor', () {
    const processor = ImuOrientationProcessor();

    test('flat upright Z-up has near-zero tilt and pitch/roll', () {
      final result = processor.process(
        accelerometer: const ImuVector3(x: 0, y: 0, z: 9.81),
        magnetometer: const ImuVector3(x: 20, y: 0, z: 40),
      );

      expect(result.tiltDegrees, closeTo(0, 1));
      expect(result.orientation.pitchDegrees.abs(), lessThan(2));
      expect(result.orientation.rollDegrees.abs(), lessThan(2));
      expect(result.orientation.yawDegrees, isNotNull);
    });

    test('portrait Y-up mount also has near-zero lean', () {
      final result = processor.process(
        accelerometer: const ImuVector3(x: 0, y: 9.81, z: 0),
        magnetometer: const ImuVector3.zero(),
      );

      expect(result.tiltDegrees, closeTo(0, 1));
    });

    test('45° absolute lean between X and Y raises tilt without baseline', () {
      final result = processor.process(
        accelerometer: const ImuVector3(x: 6.94, y: 6.94, z: 0),
        magnetometer: const ImuVector3.zero(),
      );

      expect(result.tiltDegrees, closeTo(45, 2));
      expect(result.orientation.yawDegrees, isNull);
    });

    test('dash mount lean is near zero once rest baseline is set', () {
      const mount = ImuVector3(x: 0, y: 6.94, z: 6.94);
      final result = processor.process(
        accelerometer: mount,
        magnetometer: const ImuVector3.zero(),
        restGravityUnit: mount.normalized,
      );

      expect(result.tiltDegrees, closeTo(0, 1));
    });

    test('tip away from rest baseline raises relative tilt', () {
      const rest = ImuVector3(x: 0, y: 9.81, z: 0);
      const tipped = ImuVector3(x: 6.94, y: 6.94, z: 0);
      final result = processor.process(
        accelerometer: tipped,
        magnetometer: const ImuVector3.zero(),
        restGravityUnit: rest.normalized,
      );

      expect(result.tiltDegrees, closeTo(45, 2));
    });
  });

  group('VibrationProcessor', () {
    test('still device near g is calm', () {
      final processor = VibrationProcessor(windowSize: 5);
      VibrationMetrics? last;
      for (var i = 0; i < 5; i++) {
        last = processor.update(const ImuVector3(x: 0, y: 0, z: 9.81));
      }
      expect(last!.intensity, VibrationIntensity.calm);
      expect(last.rms, lessThan(0.25));
    });

    test('large linear accel maps to severe', () {
      final processor = VibrationProcessor(windowSize: 5);
      VibrationMetrics? last;
      for (var i = 0; i < 5; i++) {
        last = processor.update(const ImuVector3(x: 0, y: 0, z: 15));
      }
      expect(last!.intensity, VibrationIntensity.severe);
    });
  });

  group('ImuCalibrationCollector', () {
    test('averages bias and preserves gravity on dominant axis', () {
      final collector = ImuCalibrationCollector();
      collector.start();
      ImuCalibration? result;
      while (result == null) {
        result = collector.addSample(
          accelerometer: const ImuVector3(x: 0.1, y: -0.05, z: 9.9),
          gyroscope: const ImuVector3(x: 0.01, y: 0.02, z: -0.01),
        );
      }
      expect(result.isCalibrated, isTrue);
      expect(result.accelerometerBias.x, closeTo(0.1, 0.01));
      expect(result.accelerometerBias.y, closeTo(-0.05, 0.01));
      expect(result.accelerometerBias.z, closeTo(9.9 - 9.80665, 0.05));
      expect(result.gyroscopeBias.x, closeTo(0.01, 0.001));
    });
  });
}
