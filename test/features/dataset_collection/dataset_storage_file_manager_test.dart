import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_storage_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/models/frame_metadata_json_codec.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_storage_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/dataset_storage_cache.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/storage_manager_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements DatasetStorageLocalDataSource {}

class _FakeFiles implements DatasetFileManager {
  _FakeFiles(this.root, {this.sizeBytes = 0});

  final String root;
  final int sizeBytes;

  @override
  late final DatasetPaths paths = DatasetPaths(root: root);

  @override
  Future<void> ensureRootLayout() async {}

  @override
  Future<void> ensureSessionLayout(String sessionId) async {}

  @override
  Future<bool> exists(String path) async => false;

  @override
  Future<void> deletePath(String path) async {}

  @override
  Future<void> move(String from, String to) async {}

  @override
  Future<void> copy(String from, String to) async {}

  @override
  Future<void> rename(String from, String to) async {}

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {}

  @override
  Future<Uint8List> readBytes(String path) async => Uint8List(0);

  @override
  Future<void> writeText(String path, String contents) async {}

  @override
  Future<String> readText(String path) async => '';

  @override
  Future<int> directoryByteSize(String path) async => sizeBytes;

  @override
  Future<int> fileCount(String path) async => 0;

  @override
  Future<List<String>> listSessionIds() async => [];

  @override
  Future<Uint8List> generateThumbnail(Uint8List sourceJpeg, {int maxSide = 256}) async =>
      sourceJpeg;

  @override
  Future<Uint8List> compressImage(Uint8List source, {int quality = 70}) async =>
      source;

  @override
  Future<int> cleanTemporaryFiles() async => 0;

  @override
  Future<List<RecentStorageFile>> listRecentFiles({int limit = 20}) async => [];
}

FrameMetadata _meta({int frameNumber = 1}) {
  final at = DateTime.utc(2026, 7, 14);
  return FrameMetadata(
    location: LocationMetadata.missing(at),
    motion: const MotionMetadata.missing(),
    inference: const InferenceMetadata.missing(),
    device: const DeviceMetadata(
      deviceModel: 't',
      manufacturer: 't',
      androidVersion: '1',
      batteryLevel: -1,
      chargingStatus: 'unknown',
      screenRotation: 0,
      appVersion: '1.0.0',
    ),
    session: SessionMetadata(
      sessionId: 's1',
      frameNumber: frameNumber,
      captureReason: 'manual',
      captureType: CaptureType.manual,
      capturedAt: at,
      frameId: 'f1',
    ),
    validation: const MetadataValidation(
      hasGps: false,
      hasImu: false,
      hasAi: false,
      hasSession: true,
      hasTimestamp: true,
    ),
    synchronizedAt: at,
  );
}

void main() {
  group('DatasetPaths', () {
    test('frame filenames are zero-padded without timestamps', () {
      expect(DatasetPaths.frameStem(1), 'frame_000001');
      expect(DatasetPaths.originalFileName(42), 'frame_000042.jpg');
      expect(DatasetPaths.frameMetadataFileName(7), 'frame_000007.json');
      const p = DatasetPaths(root: '/tmp/dataset');
      expect(p.imagesOriginal('abc'), '/tmp/dataset/sessions/abc/images/original');
    });
  });

  group('FrameMetadataJsonCodec', () {
    test('round trip', () {
      final original = _meta(frameNumber: 3);
      final decoded =
          FrameMetadataJsonCodec.fromJson(FrameMetadataJsonCodec.toJson(original));
      expect(decoded.session.frameNumber, 3);
      expect(decoded.session.sessionId, 's1');
      expect(decoded.session.captureType, CaptureType.manual);
    });
  });

  group('DatasetStorageCache', () {
    test('evicts oldest when over max', () {
      final cache = DatasetStorageCache(maxEntries: 2);
      cache.putMetadata('s', 1, _meta(frameNumber: 1));
      cache.putMetadata('s', 2, _meta(frameNumber: 2));
      cache.putMetadata('s', 3, _meta(frameNumber: 3));
      expect(cache.getMetadata('s', 1), isNull);
      expect(cache.getMetadata('s', 3)?.session.frameNumber, 3);
    });
  });

  group('StorageManagerImpl', () {
    test('flags low storage near soft limit', () async {
      final files = _FakeFiles('/tmp/dataset', sizeBytes: 1900 * 1024 * 1024);
      final manager = StorageManagerImpl(
        fileManager: files,
        logger: AppLogger(),
        softLimitBytes: 2 * 1024 * 1024 * 1024,
        criticalUsedBytes: 1800 * 1024 * 1024,
      );
      final usage = await manager.calculateUsage();
      expect(usage.isLowStorage, isTrue);
      expect(usage.warningMessage, isNotNull);
    });
  });

  group('DatasetStorageRepositoryImpl', () {
    late _MockDs ds;
    late DatasetStorageRepositoryImpl repo;

    setUpAll(() {
      registerFallbackValue(
        SaveImageParams(
          sessionId: 's',
          frameNumber: 1,
          bytes: Uint8List.fromList([1]),
        ),
      );
      registerFallbackValue(_meta());
    });

    setUp(() {
      ds = _MockDs();
      repo = DatasetStorageRepositoryImpl(
        localDataSource: ds,
        errorHandler: ErrorHandler(logger: AppLogger()),
      );
    });

    test('saveMetadata success', () async {
      when(() => ds.saveMetadata(any())).thenAnswer((_) async => '/path.json');
      final result = await repo.saveMetadata(SaveMetadataParams(_meta()));
      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), '/path.json');
    });

    test('maps CacheException', () async {
      when(() => ds.calculateStorage()).thenThrow(
        const CacheException(message: 'disk fail'),
      );
      final result = await repo.calculateStorage();
      expect(result.isErr, isTrue);
      expect(
        result.fold(onOk: (_) => '', onErr: (f) => f.message),
        'disk fail',
      );
    });

    test('recoverSession forwards', () async {
      when(() => ds.recoverSessions(sessionId: any(named: 'sessionId')))
          .thenAnswer(
        (_) async => [
          const SessionRecoveryInfo(
            sessionId: 's1',
            sessionPath: '/s1',
            imageCount: 1,
            metadataCount: 0,
            isIncomplete: true,
          ),
        ],
      );
      final result = await repo.recoverSession(sessionId: 's1');
      expect(result.getOrThrow().first.isIncomplete, isTrue);
    });
  });
}
