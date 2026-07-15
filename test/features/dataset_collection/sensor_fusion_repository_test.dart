import 'dart:async';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/sensor_fusion_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/sensor_fusion_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/sensor_fusion_engine.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

class _MockGps extends Mock implements GpsRepository {}

class _MockImu extends Mock implements ImuRepository {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late _MockGps gps;
  late _MockImu imu;
  late SensorFusionRepositoryImpl repo;
  late StreamController<GpsFix> gpsCtrl;
  late StreamController<ImuSample> imuCtrl;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fusion_');
    files = _MockFiles();
    gps = _MockGps();
    imu = _MockImu();
    gpsCtrl = StreamController<GpsFix>.broadcast();
    imuCtrl = StreamController<ImuSample>.broadcast();

    final paths = DatasetPaths(root: temp.path);
    when(() => files.paths).thenReturn(paths);
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory(paths.sensorFusion).create(recursive: true);
    });
    when(() => gps.startTracking()).thenAnswer(
      (_) async => const Ok(
        GpsSession(
          isStreaming: true,
          isServiceEnabled: true,
          fixCount: 0,
        ),
      ),
    );
    when(() => gps.stopTracking()).thenAnswer(
      (_) async => const Ok(
        GpsSession(
          isStreaming: false,
          isServiceEnabled: true,
          fixCount: 0,
        ),
      ),
    );
    when(() => gps.watchFixes()).thenAnswer((_) => gpsCtrl.stream);
    when(() => imu.startStreaming()).thenAnswer((_) async => const Ok(null));
    when(() => imu.stopStreaming()).thenAnswer((_) async => const Ok(null));
    when(() => imu.sampleStream).thenAnswer((_) => imuCtrl.stream);

    repo = SensorFusionRepositoryImpl(
      localDataSource: SensorFusionLocalDataSourceImpl(
        fileManager: files,
        logger: AppLogger(),
      ),
      engine: const SensorFusionEngine(),
      gpsRepository: gps,
      imuRepository: imu,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    await gpsCtrl.close();
    await imuCtrl.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('createDemoSample persists high quality sample', () async {
    final result = await repo.createDemoSample();
    expect(result.isOk, isTrue);
    final sample = result.fold(
      onOk: (s) => s,
      onErr: (_) => throw StateError('expected ok'),
    );
    expect(sample.sourcesPresent.length, greaterThanOrEqualTo(3));
    expect(sample.qualityScore, greaterThan(60));

    final snap = await repo.loadSnapshot();
    expect(
      snap.fold(onOk: (s) => s.recentSamples.length, onErr: (_) => 0),
      1,
    );
  });

  test('fuseTick uses latest gps/imu caches', () async {
    final now = DateTime.now().toUtc();
    await repo.startFusion(enableCamera: false);
    gpsCtrl.add(
      GpsFix(
        latitude: 1,
        longitude: 2,
        accuracyMeters: 4,
        timestamp: now,
      ),
    );
    imuCtrl.add(
      ImuSample(
        accelerometer: const ImuVector3(x: 0, y: 0, z: 9.8),
        gyroscope: const ImuVector3.zero(),
        magnetometer: const ImuVector3.zero(),
        orientation: const ImuOrientation(pitchDegrees: 0, rollDegrees: 0),
        tiltDegrees: 0.5,
        vibration: const VibrationMetrics.calm(),
        timestamp: now,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final fused = await repo.fuseTick(at: now);
    expect(fused.isOk, isTrue);
    expect(
      fused.fold(onOk: (s) => s.gps != null && s.imu != null, onErr: (_) => false),
      isTrue,
    );
    await repo.stopFusion();
  });

  test('clearSamples empties buffer', () async {
    await repo.createDemoSample();
    expect((await repo.clearSamples()).isOk, isTrue);
    final snap = await repo.loadSnapshot();
    expect(
      snap.fold(onOk: (s) => s.recentSamples, onErr: (_) => <FusedSample>[]),
      isEmpty,
    );
  });
}
