import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/metadata_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/metadata_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/metadata_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenerate extends Mock implements GenerateFrameMetadataUseCase {}

class _MockClear extends Mock implements ClearMetadataUseCase {}

class _MockMetaRepo extends Mock implements MetadataRepository {}

class _MockFrameRepo extends Mock implements FrameCaptureRepository {}

void main() {
  late _MockGenerate generate;
  late _MockClear clear;
  late _MockMetaRepo metaRepo;
  late _MockFrameRepo frameRepo;
  late StreamController<CapturedFrame> frames;

  final frame = CapturedFrame(
    frameId: 'f1',
    timestamp: DateTime.utc(2026, 7, 14),
    width: 640,
    height: 480,
    rotation: 0,
    sessionId: 's1',
    captureReason: const CaptureReason(
      ruleId: 't',
      message: 'interval',
      type: CaptureType.automatic,
    ),
    captureType: CaptureType.automatic,
    cameraLensDirection: 'rear',
  );

  final metadata = FrameMetadata(
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
      captureReason: 'interval',
      captureType: CaptureType.automatic,
      capturedAt: DateTime.utc(2026, 7, 14),
      frameId: 'f1',
    ),
    validation: const MetadataValidation(
      hasGps: false,
      hasImu: false,
      hasAi: false,
      hasSession: true,
      hasTimestamp: true,
      warnings: ['Missing GPS'],
    ),
    synchronizedAt: DateTime.utc(2026, 7, 14),
  );

  setUpAll(() {
    registerFallbackValue(frame);
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    generate = _MockGenerate();
    clear = _MockClear();
    metaRepo = _MockMetaRepo();
    frameRepo = _MockFrameRepo();
    frames = StreamController<CapturedFrame>.broadcast();
    when(frameRepo.watchCapturedFrames).thenAnswer((_) => frames.stream);
    when(() => metaRepo.sensorStatus)
        .thenReturn(const SensorStatusSnapshot.cold());
  });

  tearDown(() async {
    await frames.close();
  });

  MetadataBloc build() {
    return MetadataBloc(
      generateFrameMetadata: generate,
      clearMetadata: clear,
      repository: metaRepo,
      frameCaptureRepository: frameRepo,
      logger: AppLogger(),
    );
  }

  blocTest<MetadataBloc, MetadataState>(
    'GenerateMetadata → Generated',
    build: () {
      when(() => generate(any())).thenAnswer((_) async => Ok(metadata));
      return build();
    },
    act: (bloc) => bloc.add(MetadataGenerateRequested(frame)),
    expect: () => [
      isA<MetadataGenerating>(),
      isA<MetadataGenerated>(),
    ],
  );

  blocTest<MetadataBloc, MetadataState>(
    'GenerateMetadata failure → Error',
    build: () {
      when(() => generate(any())).thenAnswer(
        (_) async => const Err(ValidationFailure(message: 'no session')),
      );
      return build();
    },
    act: (bloc) => bloc.add(MetadataGenerateRequested(frame)),
    expect: () => [
      isA<MetadataGenerating>(),
      isA<MetadataError>(),
    ],
  );

  blocTest<MetadataBloc, MetadataState>(
    'Clear → Initial',
    build: () {
      when(() => clear(any())).thenAnswer((_) async => const Ok(null));
      return build();
    },
    seed: () => MetadataGenerated(
      metadata: metadata,
      sensors: const SensorStatusSnapshot.cold(),
    ),
    act: (bloc) => bloc.add(const MetadataClearRequested()),
    expect: () => [isA<MetadataInitial>()],
  );
}
