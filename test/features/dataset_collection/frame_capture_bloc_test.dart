import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/frame_capture_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/frame_capture_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStart extends Mock implements StartFrameCaptureUseCase {}

class _MockStop extends Mock implements StopFrameCaptureUseCase {}

class _MockPause extends Mock implements PauseFrameCaptureUseCase {}

class _MockResume extends Mock implements ResumeFrameCaptureUseCase {}

class _MockManual extends Mock implements CaptureSingleFrameUseCase {}

class _MockClear extends Mock implements ClearFrameQueueUseCase {}

class _MockRepo extends Mock implements FrameCaptureRepository {}

void main() {
  late _MockStart start;
  late _MockStop stop;
  late _MockPause pause;
  late _MockResume resume;
  late _MockManual manual;
  late _MockClear clear;
  late _MockRepo repo;
  late StreamController<FrameQueueSnapshot> queueCtrl;
  late StreamController<CapturedFrame> frameCtrl;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const StartFrameCaptureParams(sessionId: 's'),
    );
  });

  setUp(() {
    start = _MockStart();
    stop = _MockStop();
    pause = _MockPause();
    resume = _MockResume();
    manual = _MockManual();
    clear = _MockClear();
    repo = _MockRepo();
    queueCtrl = StreamController<FrameQueueSnapshot>.broadcast();
    frameCtrl = StreamController<CapturedFrame>.broadcast();
    when(repo.watchQueue).thenAnswer((_) => queueCtrl.stream);
    when(repo.watchCapturedFrames).thenAnswer((_) => frameCtrl.stream);
    when(() => repo.isCapturing).thenReturn(true);
    when(() => repo.isPaused).thenReturn(false);
  });

  tearDown(() async {
    await queueCtrl.close();
    await frameCtrl.close();
  });

  FrameCaptureBloc build() {
    return FrameCaptureBloc(
      startCapture: start,
      stopCapture: stop,
      pauseCapture: pause,
      resumeCapture: resume,
      captureSingleFrame: manual,
      clearFrameQueue: clear,
      repository: repo,
      logger: AppLogger(),
    );
  }

  blocTest<FrameCaptureBloc, FrameCaptureState>(
    'StartCapture → Capturing',
    build: () {
      when(() => start(any())).thenAnswer((_) async => const Ok(null));
      return build();
    },
    act: (bloc) => bloc.add(
      const FrameCaptureStartCapture(StartFrameCaptureParams(sessionId: 's1')),
    ),
    expect: () => [isA<FrameCaptureCapturing>()],
  );

  blocTest<FrameCaptureBloc, FrameCaptureState>(
    'StartCapture error → Error',
    build: () {
      when(() => start(any())).thenAnswer(
        (_) async => const Err(ValidationFailure(message: 'no session')),
      );
      return build();
    },
    act: (bloc) => bloc.add(
      const FrameCaptureStartCapture(StartFrameCaptureParams(sessionId: '')),
    ),
    expect: () => [isA<FrameCaptureError>()],
  );

  blocTest<FrameCaptureBloc, FrameCaptureState>(
    'PauseCapture → Paused',
    build: () {
      when(() => pause(any())).thenAnswer((_) async => const Ok(null));
      when(() => repo.isPaused).thenReturn(true);
      return build();
    },
    seed: () => const FrameCaptureCapturing(
      sessionId: 's1',
      queue: FrameQueueSnapshot.empty(),
    ),
    act: (bloc) => bloc.add(const FrameCapturePauseCapture()),
    expect: () => [isA<FrameCapturePaused>()],
  );

  blocTest<FrameCaptureBloc, FrameCaptureState>(
    'StopCapture → Stopped',
    build: () {
      when(() => stop(any())).thenAnswer((_) async => const Ok(null));
      return build();
    },
    seed: () => const FrameCaptureCapturing(
      sessionId: 's1',
      queue: FrameQueueSnapshot.empty(),
    ),
    act: (bloc) => bloc.add(const FrameCaptureStopCapture()),
    expect: () => [isA<FrameCaptureStopped>()],
  );
}
