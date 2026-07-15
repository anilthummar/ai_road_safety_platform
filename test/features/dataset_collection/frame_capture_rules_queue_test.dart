import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/capture_rule.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/time_interval_and_manual_rules.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_queue_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_validator.dart';
import 'package:flutter_test/flutter_test.dart';

CameraFrameMeta _meta({
  int sequence = 1,
  int width = 640,
  int height = 480,
}) {
  return CameraFrameMeta(
    sessionId: 'cam',
    sequence: sequence,
    timestamp: DateTime.utc(2026, 7, 14),
    width: width,
    height: height,
  );
}

void main() {
  group('FrameQueueManager', () {
    test('FIFO enqueue dequeue', () {
      final q = FrameQueueManager(maxSize: 3);
      final a = _frame('a', 1);
      final b = _frame('b', 2);
      expect(q.enqueue(a), FrameEnqueueResult.enqueued);
      expect(q.enqueue(b), FrameEnqueueResult.enqueued);
      expect(q.dequeue()?.frameId, 'a');
      expect(q.size, 1);
    });

    test('discards oldest when full', () {
      final q = FrameQueueManager(maxSize: 2);
      q.enqueue(_frame('a', 1));
      q.enqueue(_frame('b', 2));
      final result = q.enqueue(_frame('c', 3));
      expect(result, FrameEnqueueResult.enqueuedDroppedOldest);
      expect(q.frames.map((f) => f.frameId), ['b', 'c']);
    });

    test('rejects duplicate frame ids', () {
      final q = FrameQueueManager(maxSize: 5);
      q.enqueue(_frame('a', 1));
      expect(q.enqueue(_frame('a', 2)), FrameEnqueueResult.duplicateId);
    });

    test('rejects duplicate sequences', () {
      final q = FrameQueueManager(maxSize: 5);
      q.enqueue(_frame('a', 7));
      expect(q.enqueue(_frame('b', 7)), FrameEnqueueResult.duplicateSequence);
    });
  });

  group('Capture rules', () {
    test('TimeIntervalRule admits after interval', () {
      final rule = TimeIntervalRule(interval: const Duration(seconds: 1));
      final ctx = _ctx(now: DateTime.utc(2026, 7, 14, 10));
      final first = rule.evaluate(ctx);
      expect(first.shouldCapture, isTrue);
      rule.onCaptured(ctx);

      final tooSoon = rule.evaluate(
        _ctx(now: DateTime.utc(2026, 7, 14, 10, 0, 0, 500)),
      );
      expect(tooSoon.shouldCapture, isFalse);

      final later = rule.evaluate(
        _ctx(now: DateTime.utc(2026, 7, 14, 10, 0, 2)),
      );
      expect(later.shouldCapture, isTrue);
    });

    test('TimeIntervalRule skips when paused', () {
      final rule = TimeIntervalRule();
      final decision = rule.evaluate(
        _ctx(isSessionPaused: true),
      );
      expect(decision.shouldCapture, isFalse);
    });

    test('ManualCaptureRule requires arm / manualRequested', () {
      final rule = ManualCaptureRule();
      expect(rule.evaluate(_ctx()).shouldCapture, isFalse);
      rule.arm();
      expect(rule.evaluate(_ctx()).shouldCapture, isTrue);
      rule.onCaptured(_ctx());
      expect(rule.isArmed, isFalse);
    });
  });

  group('FrameValidator', () {
    const validator = FrameValidator();

    test('rejects null / low res / inactive', () {
      expect(
        validator
            .validate(
              frame: null,
              isSessionActive: true,
              isSessionPaused: false,
              isCaptureActive: true,
              isCapturePaused: false,
              isDuplicateSequence: (_) => false,
            )
            .reason,
        FrameRejectReason.nullFrame,
      );
      expect(
        validator
            .validate(
              frame: _meta(width: 10, height: 10),
              isSessionActive: true,
              isSessionPaused: false,
              isCaptureActive: true,
              isCapturePaused: false,
              isDuplicateSequence: (_) => false,
            )
            .reason,
        FrameRejectReason.lowResolution,
      );
      expect(
        validator
            .validate(
              frame: _meta(),
              isSessionActive: false,
              isSessionPaused: false,
              isCaptureActive: true,
              isCapturePaused: false,
              isDuplicateSequence: (_) => false,
            )
            .reason,
        FrameRejectReason.sessionInactive,
      );
    });

    test('accepts valid frame', () {
      expect(
        validator
            .validate(
              frame: _meta(),
              isSessionActive: true,
              isSessionPaused: false,
              isCaptureActive: true,
              isCapturePaused: false,
              isDuplicateSequence: (_) => false,
            )
            .isValid,
        isTrue,
      );
    });
  });

  group('performance budget', () {
    test('queue overflow stays within maxSize', () {
      final q = FrameQueueManager(maxSize: 30);
      for (var i = 0; i < 1000; i++) {
        q.enqueue(_frame('id-$i', i));
      }
      expect(q.size, 30);
    });
  });
}

CapturedFrame _frame(String id, int sequence) {
  return CapturedFrame(
    frameId: id,
    timestamp: DateTime.utc(2026, 7, 14),
    width: 640,
    height: 480,
    rotation: 0,
    sessionId: 's1',
    captureReason: const CaptureReason(
      ruleId: 't',
      message: 'test',
      type: CaptureType.automatic,
    ),
    captureType: CaptureType.automatic,
    cameraLensDirection: 'rear',
    cameraSequence: sequence,
  );
}

FrameCaptureContext _ctx({
  DateTime? now,
  bool isSessionPaused = false,
  bool isCapturePaused = false,
  bool manualRequested = false,
}) {
  return FrameCaptureContext(
    frame: _meta(),
    sessionId: 's1',
    isSessionActive: true,
    isSessionPaused: isSessionPaused,
    isCapturePaused: isCapturePaused,
    manualRequested: manualRequested,
    now: now ?? DateTime.utc(2026, 7, 14),
    lensDirection: 'rear',
    rotationDegrees: 0,
  );
}
