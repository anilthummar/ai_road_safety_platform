import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/frame_capture_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/capture_rule.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/placeholder_capture_rules.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/time_interval_and_manual_rules.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_background_processor.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_queue_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_validator.dart';
import 'package:uuid/uuid.dart';

/// Camera → validate → rules → memory queue acquisition engine (Phase 12.3).
class FrameCaptureRepositoryImpl implements FrameCaptureRepository {
  final CameraRepository _camera;
  final FrameCaptureLocalDataSource _local;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final FrameBackgroundProcessor _background;
  final FrameCaptureConfig _config;
  final FrameValidator _validator;
  final Uuid _uuid;
  final ManualCaptureRule _manualRule;
  final TimeIntervalRule _intervalRule;
  final List<CaptureRule> _rules;

  final StreamController<FrameQueueSnapshot> _queueController =
      StreamController<FrameQueueSnapshot>.broadcast();
  final StreamController<CapturedFrame> _frameController =
      StreamController<CapturedFrame>.broadcast();

  StreamSubscription<CameraFrameMeta>? _frameSub;
  String? _sessionId;
  String _lensDirection = 'rear';
  int _rotationDegrees = 0;
  bool _capturing = false;
  bool _paused = false;
  bool _processing = false;
  final Set<int> _seenSequences = <int>{};
  final List<DateTime> _captureTimestamps = <DateTime>[];

  /// Creates [FrameCaptureRepositoryImpl].
  FrameCaptureRepositoryImpl({
    required CameraRepository cameraRepository,
    required FrameCaptureLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    FrameBackgroundProcessor? backgroundProcessor,
    FrameCaptureConfig config = const FrameCaptureConfig(),
    FrameValidator? validator,
    Uuid? uuid,
    ManualCaptureRule? manualRule,
    TimeIntervalRule? intervalRule,
    List<CaptureRule>? additionalRules,
  })  : _camera = cameraRepository,
        _local = localDataSource,
        _errorHandler = errorHandler,
        _logger = logger,
        _background = backgroundProcessor ?? FrameBackgroundProcessorImpl(),
        _config = config,
        _validator = validator ?? FrameValidator(config: config),
        _uuid = uuid ?? const Uuid(),
        _manualRule = manualRule ?? ManualCaptureRule(),
        _intervalRule = intervalRule ??
            TimeIntervalRule(interval: config.captureInterval),
        _rules = [] {
    _rules.addAll([
      _manualRule,
      _intervalRule,
      ...?additionalRules,
      const FloodConfidenceRule(),
      const WaterCoverageChangeRule(),
      const MotionRule(),
      const ImuEventRule(),
    ]);
  }

  @override
  bool get isCapturing => _capturing && !_paused;

  @override
  bool get isPaused => _paused;

  @override
  Stream<FrameQueueSnapshot> watchQueue() => _queueController.stream;

  @override
  Stream<CapturedFrame> watchCapturedFrames() => _frameController.stream;

  @override
  Future<Result<void>> startCapture(StartFrameCaptureParams params) {
    return _guard(() async {
      if (params.sessionId.trim().isEmpty) {
        throw const CacheException(
          message: 'Capture requires an active session.',
        );
      }
      if (_capturing) {
        throw const CacheException(
          message: 'Capture is already running. Stop it before starting again.',
        );
      }

      _sessionId = params.sessionId;
      _lensDirection = params.lensDirection;
      _rotationDegrees = params.rotationDegrees;
      _paused = false;
      _seenSequences.clear();
      _captureTimestamps.clear();
      _local.resetCounters();
      for (final rule in _rules) {
        rule.reset();
      }

      final init = await _camera.initialize();
      if (init.isErr) {
        throw DeviceCameraException(
          message: init.fold(onOk: (_) => '', onErr: (f) => f.message),
        );
      }

      final stream = await _camera.startFrameStreaming(
        targetFps: _config.streamTargetFps,
      );
      if (stream.isErr) {
        throw DeviceCameraException(
          message: stream.fold(onOk: (_) => '', onErr: (f) => f.message),
        );
      }

      await _frameSub?.cancel();
      _frameSub = _camera.watchFrames().listen(
        (meta) {
          unawaited(
            _background.runAsync(() async => _onCameraFrame(meta)),
          );
        },
        onError: (Object e, StackTrace st) {
          _logger.warning(
            'Frame stream error: $e',
            tag: 'FrameCapture',
            error: e,
            stackTrace: st,
          );
        },
      );

      _capturing = true;
      _emitQueue();
      _logger.info(
        'Capture Started session=${params.sessionId}',
        tag: 'FrameCapture',
      );
    });
  }

  @override
  Future<Result<void>> stopCapture() {
    return _guard(() async {
      await _frameSub?.cancel();
      _frameSub = null;
      _capturing = false;
      _paused = false;
      _sessionId = null;
      _processing = false;
      for (final rule in _rules) {
        rule.reset();
      }
      _emitQueue();
      _logger.info('Capture Stopped', tag: 'FrameCapture');
    });
  }

  @override
  Future<Result<void>> pauseCapture() {
    return _guard(() async {
      if (!_capturing) {
        throw const CacheException(message: 'Capture is not running.');
      }
      _paused = true;
      _emitQueue();
      _logger.info('Capture Paused', tag: 'FrameCapture');
    });
  }

  @override
  Future<Result<void>> resumeCapture() {
    return _guard(() async {
      if (!_capturing) {
        throw const CacheException(message: 'Capture is not running.');
      }
      if (!_paused) return;
      _paused = false;
      _emitQueue();
      _logger.info('Capture Resumed', tag: 'FrameCapture');
    });
  }

  @override
  Future<Result<CapturedFrame>> captureFrame() {
    return _guard(() async {
      _ensureCanCapture();
      _manualRule.arm();
      final synthetic = CameraFrameMeta(
        sessionId: _sessionId!,
        sequence: -DateTime.now().microsecondsSinceEpoch,
        timestamp: DateTime.now(),
        width: _config.minWidth,
        height: _config.minHeight,
      );
      final frame = await _admitFromRules(
        meta: synthetic,
        manualRequested: true,
      );
      if (frame == null) {
        throw const CacheException(
          message: 'Manual capture was rejected (paused or invalid state).',
        );
      }
      return frame;
    });
  }

  @override
  Future<Result<CapturedFrame>> enqueueFrame(CapturedFrame frame) {
    return _guard(() async {
      final result = _local.enqueue(frame);
      if (result == FrameEnqueueResult.duplicateId ||
          result == FrameEnqueueResult.duplicateSequence) {
        _local.recordDrop();
        _emitQueue();
        throw const CacheException(message: 'Duplicate frame rejected.');
      }
      if (result == FrameEnqueueResult.enqueuedDroppedOldest) {
        _local.recordDrop();
        _logger.warning(
          'Queue Full — dropped oldest frame',
          tag: 'FrameCapture',
        );
      }
      _local.recordCapture();
      _noteCaptureTime(DateTime.now());
      _emitQueue();
      if (!_frameController.isClosed) {
        _frameController.add(frame);
      }
      _logger.info('Frame Captured id=${frame.frameId}', tag: 'FrameCapture');
      return frame;
    });
  }

  @override
  Future<Result<CapturedFrame?>> dequeueFrame() {
    return _guard(() async {
      final frame = _local.dequeue();
      _emitQueue();
      return frame;
    });
  }

  @override
  Future<Result<void>> clearQueue() {
    return _guard(() async {
      _local.clear();
      _seenSequences.clear();
      _emitQueue();
    });
  }

  @override
  Future<Result<int>> queueSize() {
    return _guard(() async => _local.size);
  }

  Future<void> _onCameraFrame(CameraFrameMeta meta) async {
    if (!_capturing || _paused || _sessionId == null) return;
    if (_processing) return;
    _processing = true;
    try {
      await _admitFromRules(meta: meta, manualRequested: false);
    } finally {
      _processing = false;
    }
  }

  Future<CapturedFrame?> _admitFromRules({
    required CameraFrameMeta meta,
    required bool manualRequested,
  }) async {
    final sessionId = _sessionId;
    if (sessionId == null) return null;

    final validation = _validator.validate(
      frame: meta,
      isSessionActive: true,
      isSessionPaused: false,
      isCaptureActive: _capturing,
      isCapturePaused: _paused,
      isDuplicateSequence: _seenSequences.contains,
    );

    final effectiveValidation = manualRequested &&
            validation.reason == FrameRejectReason.lowResolution
        ? FrameValidationResult.valid
        : validation;

    if (!effectiveValidation.isValid) {
      _local.recordDrop();
      _logger.debug(
        'Frame Dropped: ${effectiveValidation.reason?.name}',
        tag: 'FrameCapture',
      );
      _emitQueue();
      return null;
    }

    final context = FrameCaptureContext(
      frame: meta,
      sessionId: sessionId,
      isSessionActive: true,
      isSessionPaused: false,
      isCapturePaused: _paused,
      manualRequested: manualRequested || _manualRule.isArmed,
      now: DateTime.now(),
      lensDirection: _lensDirection,
      rotationDegrees: _rotationDegrees,
    );

    CaptureDecision? hit;
    CaptureRule? winningRule;
    for (final rule in _rules) {
      if (!rule.isEnabled) continue;
      final decision = rule.evaluate(context);
      if (decision.shouldCapture && decision.reason != null) {
        hit = decision;
        winningRule = rule;
        break;
      }
    }

    if (hit == null || winningRule == null) {
      return null;
    }

    final reason = hit.reason!;
    final frame = CapturedFrame(
      frameId: _uuid.v4(),
      timestamp: meta.timestamp,
      width: meta.width,
      height: meta.height,
      rotation: _rotationDegrees,
      sessionId: sessionId,
      captureReason: reason,
      captureType: reason.type,
      cameraLensDirection: _lensDirection,
      cameraSequence: meta.sequence < 0 ? null : meta.sequence,
    );

    final enqueueResult = _local.enqueue(frame);
    if (enqueueResult == FrameEnqueueResult.duplicateId ||
        enqueueResult == FrameEnqueueResult.duplicateSequence) {
      _local.recordDrop();
      _logger.debug('Frame Dropped: duplicate', tag: 'FrameCapture');
      _emitQueue();
      return null;
    }
    if (enqueueResult == FrameEnqueueResult.enqueuedDroppedOldest) {
      _local.recordDrop();
      _logger.warning(
        'Queue Full — dropped oldest frame',
        tag: 'FrameCapture',
      );
    }

    if (meta.sequence >= 0) {
      _seenSequences.add(meta.sequence);
    }
    winningRule.onCaptured(context);
    _local.recordCapture();
    _noteCaptureTime(DateTime.now());
    _emitQueue();
    if (!_frameController.isClosed) {
      _frameController.add(frame);
    }
    _logger.info(
      'Frame Captured id=${frame.frameId} reason=${reason.ruleId}',
      tag: 'FrameCapture',
    );
    return frame;
  }

  void _ensureCanCapture() {
    if (_sessionId == null || !_capturing) {
      throw const CacheException(
        message: 'Cannot capture without an active capture session.',
      );
    }
    if (_paused) {
      throw const CacheException(
        message: 'Cannot capture while capture is paused.',
      );
    }
  }

  void _noteCaptureTime(DateTime at) {
    _captureTimestamps.add(at);
    final cutoff = at.subtract(const Duration(seconds: 5));
    _captureTimestamps.removeWhere((t) => t.isBefore(cutoff));
  }

  double _rollingFps() {
    if (_captureTimestamps.length < 2) {
      return _captureTimestamps.isEmpty ? 0 : 1;
    }
    final span = _captureTimestamps.last
        .difference(_captureTimestamps.first)
        .inMilliseconds;
    if (span <= 0) return 0;
    return (_captureTimestamps.length - 1) * 1000 / span;
  }

  void _emitQueue() {
    if (_queueController.isClosed) return;
    _queueController.add(_local.snapshot(captureRateFps: _rollingFps()));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }

  /// Releases stream controllers (call from tests / DI reset).
  Future<void> dispose() async {
    await _frameSub?.cancel();
    _background.dispose();
    await _queueController.close();
    await _frameController.close();
  }
}
