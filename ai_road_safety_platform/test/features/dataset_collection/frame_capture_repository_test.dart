import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/memory_frame_capture_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/frame_capture_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/time_interval_and_manual_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCamera extends Mock implements CameraRepository {}

void main() {
  late _MockCamera camera;
  late MemoryFrameCaptureLocalDataSource local;
  late FrameCaptureRepositoryImpl repository;
  late StreamController<CameraFrameMeta> frames;

  setUp(() {
    camera = _MockCamera();
    local = MemoryFrameCaptureLocalDataSource(maxQueueSize: 5);
    frames = StreamController<CameraFrameMeta>.broadcast();

    when(camera.initialize).thenAnswer(
      (_) async => const Ok(
        CameraSession(
          sessionId: 'cam',
          cameraName: '0',
          lens: CameraLensPreference.rear,
          previewWidth: 640,
          previewHeight: 480,
          sensorOrientation: 90,
          isStreamingFrames: false,
        ),
      ),
    );
    when(() => camera.startFrameStreaming(targetFps: any(named: 'targetFps')))
        .thenAnswer(
      (_) async => const Ok(
        CameraSession(
          sessionId: 'cam',
          cameraName: '0',
          lens: CameraLensPreference.rear,
          previewWidth: 640,
          previewHeight: 480,
          sensorOrientation: 90,
          isStreamingFrames: true,
        ),
      ),
    );
    when(camera.watchFrames).thenAnswer((_) => frames.stream);
    when(camera.watchRawFrames).thenAnswer((_) => const Stream.empty());
    when(camera.watchSession).thenAnswer((_) => const Stream.empty());

    repository = FrameCaptureRepositoryImpl(
      cameraRepository: camera,
      localDataSource: local,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
      config: const FrameCaptureConfig(
        captureInterval: Duration(milliseconds: 1),
        maxQueueSize: 5,
        minWidth: 100,
        minHeight: 100,
        streamTargetFps: 5,
      ),
      intervalRule: TimeIntervalRule(interval: const Duration(milliseconds: 1)),
      manualRule: ManualCaptureRule(),
    );
  });

  tearDown(() async {
    await repository.stopCapture();
    await repository.dispose();
    await frames.close();
  });

  test('startCapture rejects empty session', () async {
    final result = await repository.startCapture(
      const StartFrameCaptureParams(sessionId: '  '),
    );
    expect(result.isErr, isTrue);
  });

  test('startCapture + auto interval enqueues frames', () async {
    final result = await repository.startCapture(
      const StartFrameCaptureParams(sessionId: 's1'),
    );
    expect(result.isOk, isTrue);

    frames.add(
      CameraFrameMeta(
        sessionId: 'cam',
        sequence: 1,
        timestamp: DateTime.now(),
        width: 640,
        height: 480,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(local.capturedCount, greaterThanOrEqualTo(1));
    expect(local.size, greaterThanOrEqualTo(1));
  });

  test('pauseCapture blocks further auto enqueue', () async {
    await repository.startCapture(
      const StartFrameCaptureParams(sessionId: 's1'),
    );
    await repository.pauseCapture();
    final before = local.capturedCount;
    frames.add(
      CameraFrameMeta(
        sessionId: 'cam',
        sequence: 99,
        timestamp: DateTime.now(),
        width: 640,
        height: 480,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(local.capturedCount, before);
  });

  test('manual captureFrame succeeds while capturing', () async {
    await repository.startCapture(
      const StartFrameCaptureParams(sessionId: 's1'),
    );
    final result = await repository.captureFrame();
    expect(result.isOk, isTrue);
    expect(result.getOrThrow().captureType, CaptureType.manual);
  });

  test('cannot start two captures', () async {
    await repository.startCapture(
      const StartFrameCaptureParams(sessionId: 's1'),
    );
    final second = await repository.startCapture(
      const StartFrameCaptureParams(sessionId: 's2'),
    );
    expect(second.isErr, isTrue);
  });
}
