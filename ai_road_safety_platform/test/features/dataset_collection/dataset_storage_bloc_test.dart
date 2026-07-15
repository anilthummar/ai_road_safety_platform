import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_storage_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_storage_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSaveImage extends Mock implements SaveCapturedImageUseCase {}

class _MockSaveMeta extends Mock implements SaveFrameMetadataUseCase {}

class _MockLoadImage extends Mock implements LoadCapturedImageUseCase {}

class _MockLoadMeta extends Mock implements LoadFrameMetadataUseCase {}

class _MockDelete extends Mock implements DeleteDatasetSessionStorageUseCase {}

class _MockCalc extends Mock implements CalculateStorageUsageUseCase {}

class _MockClearCache extends Mock implements CleanupCacheUseCase {}

class _MockClearTemp extends Mock implements CleanupTemporaryFilesUseCase {}

class _MockRecover extends Mock implements RecoverRecordingSessionUseCase {}

class _MockRepo extends Mock implements DatasetStorageRepository {}

void main() {
  late _MockSaveImage saveImage;
  late _MockSaveMeta saveMeta;
  late _MockLoadImage loadImage;
  late _MockLoadMeta loadMeta;
  late _MockDelete delete;
  late _MockCalc calc;
  late _MockClearCache clearCache;
  late _MockClearTemp clearTemp;
  late _MockRecover recover;
  late _MockRepo repo;

  final usage = const StorageUsage(
    datasetRoot: '/tmp/dataset',
    usedBytes: 100,
    freeBytes: 0,
    totalBytes: 0,
    softLimitBytes: 1000,
    isLowStorage: false,
  );

  final meta = FrameMetadata(
    location: LocationMetadata.missing(DateTime.utc(2026, 7, 14)),
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
      frameNumber: 1,
      captureReason: 'm',
      captureType: CaptureType.manual,
      capturedAt: DateTime.utc(2026, 7, 14),
      frameId: 'f1',
    ),
    validation: const MetadataValidation(
      hasGps: false,
      hasImu: false,
      hasAi: false,
      hasSession: true,
      hasTimestamp: true,
    ),
    synchronizedAt: DateTime.utc(2026, 7, 14),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      SaveImageParams(
        sessionId: 's',
        frameNumber: 1,
        bytes: Uint8List.fromList([1]),
      ),
    );
    registerFallbackValue(SaveMetadataParams(meta));
    registerFallbackValue(
      const SessionFrameParams(sessionId: 's', frameNumber: 1),
    );
  });

  setUp(() {
    saveImage = _MockSaveImage();
    saveMeta = _MockSaveMeta();
    loadImage = _MockLoadImage();
    loadMeta = _MockLoadMeta();
    delete = _MockDelete();
    calc = _MockCalc();
    clearCache = _MockClearCache();
    clearTemp = _MockClearTemp();
    recover = _MockRecover();
    repo = _MockRepo();

    when(() => calc(any())).thenAnswer((_) async => Ok(usage));
    when(repo.listFolderInfo).thenAnswer((_) async => const Ok([]));
    when(() => repo.listRecentFiles(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Ok([]));
  });

  DatasetStorageBloc build() {
    return DatasetStorageBloc(
      saveCapturedImage: saveImage,
      saveFrameMetadata: saveMeta,
      loadCapturedImage: loadImage,
      loadFrameMetadata: loadMeta,
      deleteDatasetSession: delete,
      calculateStorageUsage: calc,
      cleanupCache: clearCache,
      cleanupTemporaryFiles: clearTemp,
      recoverRecordingSession: recover,
      repository: repo,
      logger: AppLogger(),
    );
  }

  blocTest<DatasetStorageBloc, DatasetStorageState>(
    'CalculateStorage → Calculated',
    build: build,
    act: (bloc) => bloc.add(const DatasetStorageCalculateStorage()),
    expect: () => [
      isA<DatasetStorageLoading>(),
      isA<DatasetStorageCalculated>(),
    ],
  );

  blocTest<DatasetStorageBloc, DatasetStorageState>(
    'SaveMetadata → Saved then Calculated',
    build: () {
      when(() => saveMeta(any())).thenAnswer((_) async => const Ok('/m.json'));
      return build();
    },
    act: (bloc) => bloc.add(DatasetStorageSaveMetadata(meta)),
    expect: () => [
      isA<DatasetStorageSaving>(),
      isA<DatasetStorageSaved>(),
      isA<DatasetStorageCalculated>(),
    ],
  );

  blocTest<DatasetStorageBloc, DatasetStorageState>(
    'SaveMetadata error → Error',
    build: () {
      when(() => saveMeta(any())).thenAnswer(
        (_) async => const Err(CacheFailure(message: 'full')),
      );
      return build();
    },
    act: (bloc) => bloc.add(DatasetStorageSaveMetadata(meta)),
    expect: () => [
      isA<DatasetStorageSaving>(),
      isA<DatasetStorageError>(),
    ],
  );

  blocTest<DatasetStorageBloc, DatasetStorageState>(
    'RecoverSession → Recovered then Calculated',
    build: () {
      when(() => recover(any())).thenAnswer(
        (_) async => const Ok([
          SessionRecoveryInfo(
            sessionId: 's1',
            sessionPath: '/s1',
            imageCount: 0,
            metadataCount: 0,
            isIncomplete: true,
          ),
        ]),
      );
      return build();
    },
    act: (bloc) => bloc.add(const DatasetStorageRecoverSession()),
    expect: () => [
      isA<DatasetStorageLoading>(),
      isA<DatasetStorageRecovered>(),
      isA<DatasetStorageCalculated>(),
    ],
  );
}
