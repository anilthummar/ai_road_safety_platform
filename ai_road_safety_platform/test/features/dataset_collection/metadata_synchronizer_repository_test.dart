import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/memory_metadata_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/metadata_repository_impl.dart';
import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSensors extends Mock implements SensorSnapshotProvider {}

CapturedFrame _frame({String sessionId = 's1'}) {
  return CapturedFrame(
    frameId: 'f1',
    timestamp: DateTime.utc(2026, 7, 14, 12),
    width: 640,
    height: 480,
    rotation: 90,
    sessionId: sessionId,
    captureReason: const CaptureReason(
      ruleId: 'manual',
      message: 'Manual',
      type: CaptureType.manual,
    ),
    captureType: CaptureType.manual,
    cameraLensDirection: 'rear',
  );
}

SensorSnapshotBundle _bundle({
  bool gps = true,
  bool imu = true,
  bool ai = true,
}) {
  final at = DateTime.utc(2026, 7, 14, 12);
  return SensorSnapshotBundle(
    location: gps
        ? LocationMetadata(
            latitude: 23.0,
            longitude: 72.5,
            altitude: 50,
            accuracy: 4,
            heading: 90,
            speed: 10,
            timestamp: at,
          )
        : LocationMetadata.missing(at),
    motion: imu
        ? const MotionMetadata(
            accelerometerX: 0.1,
            accelerometerY: 0.2,
            accelerometerZ: 9.8,
            gyroscopeX: 0,
            gyroscopeY: 0,
            gyroscopeZ: 0.01,
            orientation: 45,
          )
        : const MotionMetadata.missing(),
    inference: ai
        ? const InferenceMetadata(
            prediction: 'water',
            confidence: 0.8,
            waterCoverage: 12,
            riskLevel: 'Medium',
            modelVersion: 'flood_seg.tflite',
            inferenceTimeMs: 22,
          )
        : const InferenceMetadata.missing(),
    device: const DeviceMetadata(
      deviceModel: 'test',
      manufacturer: 'test',
      androidVersion: '14',
      batteryLevel: -1,
      chargingStatus: 'unknown',
      screenRotation: 90,
      appVersion: '1.0.0',
    ),
    sensorStatus: SensorStatusSnapshot(
      gpsLive: gps,
      imuLive: imu,
      aiLive: ai,
      riskLive: false,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_frame());
    registerFallbackValue(DateTime.utc(2026, 7, 14));
  });

  group('MetadataSynchronizerImpl', () {
    late _MockSensors sensors;
    late MetadataSynchronizerImpl sync;

    setUp(() {
      sensors = _MockSensors();
      sync = MetadataSynchronizerImpl(sensors: sensors, logger: AppLogger());
    });

    test('merges sensors and marks warnings when missing', () async {
      when(
        () => sensors.collect(
          frame: any(named: 'frame'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async => _bundle(gps: false, ai: false));

      final meta = await sync.synchronize(frame: _frame(), frameNumber: 1);
      expect(meta.session.frameNumber, 1);
      expect(meta.validation.hasGps, isFalse);
      expect(meta.validation.hasAi, isFalse);
      expect(meta.validation.hasImu, isTrue);
      expect(meta.validation.warnings, contains('Missing GPS'));
      expect(meta.device.screenRotation, 90);
    });

    test('success path with full sensors', () async {
      when(
        () => sensors.collect(
          frame: any(named: 'frame'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async => _bundle());

      final meta = await sync.synchronize(frame: _frame(), frameNumber: 3);
      expect(meta.location.latitude, 23.0);
      expect(meta.inference.prediction, 'water');
      expect(meta.validation.warnings, isEmpty);
    });
  });

  group('MetadataRepositoryImpl', () {
    late _MockSensors sensors;
    late MemoryMetadataLocalDataSource local;
    late MetadataRepositoryImpl repo;

    setUp(() {
      sensors = _MockSensors();
      when(() => sensors.status).thenReturn(const SensorStatusSnapshot.cold());
      when(sensors.start).thenReturn(null);
      when(
        () => sensors.collect(
          frame: any(named: 'frame'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async => _bundle());

      local = MemoryMetadataLocalDataSource();
      repo = MetadataRepositoryImpl(
        localDataSource: local,
        synchronizer: MetadataSynchronizerImpl(
          sensors: sensors,
          logger: AppLogger(),
        ),
        sensors: sensors,
        errorHandler: ErrorHandler(logger: AppLogger()),
      );
    });

    test('generateMetadata stores latest and increments frame number', () async {
      final a = await repo.generateMetadata(_frame());
      final b = await repo.generateMetadata(_frame());
      expect(a.isOk, isTrue);
      expect(b.getOrThrow().session.frameNumber, 2);
      expect(local.latest?.session.frameNumber, 2);
    });

    test('clearMetadata empties buffer', () async {
      await repo.generateMetadata(_frame());
      await repo.clearMetadata();
      final latest = await repo.getLatestMetadata();
      expect(latest.getOrThrow(), isNull);
    });

    test('rejects empty session', () async {
      final result = await repo.generateMetadata(_frame(sessionId: ''));
      expect(result.isErr, isTrue);
    });
  });
}
