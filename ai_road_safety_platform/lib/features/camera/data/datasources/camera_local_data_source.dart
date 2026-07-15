import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Low-level camera access — owns [CameraController] lifecycle.
///
/// Presentation obtains the controller via [activeController] for preview only.
abstract class CameraLocalDataSource {
  /// Active plugin controller when a session is initialized; otherwise null.
  CameraController? get activeController;

  /// Current domain session snapshot, if any.
  CameraSession? get currentSession;

  Future<CameraPermissionStatus> checkPermission();

  Future<CameraPermissionStatus> requestPermission();

  Future<bool> openPermissionSettings();

  Future<CameraSession> initialize({
    CameraLensPreference lens = CameraLensPreference.rear,
  });

  Future<CameraSession> pause();

  Future<CameraSession> resume();

  Future<CameraSession> startFrameStreaming({int targetFps = 8});

  Future<CameraSession> stopFrameStreaming();

  Future<void> disposeCamera();

  Future<CameraSession> handleOrientationChanged(int degrees);

  Stream<CameraSession> get sessionStream;

  Stream<CameraFrameMeta> get frameStream;

  /// Pixel-plane copies for on-device AI (throttled with [frameStream]).
  Stream<CameraRawFrame> get rawFrameStream;
}

/// Production [CameraLocalDataSource] backed by the `camera` plugin.
class CameraLocalDataSourceImpl implements CameraLocalDataSource {
  final AppLogger _logger;

  CameraController? _controller;
  CameraSession? _session;
  List<CameraDescription> _cameras = const [];

  final StreamController<CameraSession> _sessionController =
      StreamController<CameraSession>.broadcast();
  final StreamController<CameraFrameMeta> _frameController =
      StreamController<CameraFrameMeta>.broadcast();
  final StreamController<CameraRawFrame> _rawFrameController =
      StreamController<CameraRawFrame>.broadcast();

  int _frameSequence = 0;
  int _targetFps = 8;
  DateTime? _lastEmittedFrameAt;
  bool _isProcessingFrame = false;
  bool _isStreaming = false;
  bool _isPaused = false;

  /// Active page/bloc consumers of the shared camera singleton.
  int _ownerCount = 0;

  /// Creates [CameraLocalDataSourceImpl].
  CameraLocalDataSourceImpl({required AppLogger logger}) : _logger = logger;

  @override
  CameraController? get activeController => _controller;

  @override
  CameraSession? get currentSession => _session;

  @override
  Stream<CameraSession> get sessionStream => _sessionController.stream;

  @override
  Stream<CameraFrameMeta> get frameStream => _frameController.stream;

  @override
  Stream<CameraRawFrame> get rawFrameStream => _rawFrameController.stream;

  @override
  Future<CameraPermissionStatus> checkPermission() async {
    final status = await ph.Permission.camera.status;
    return _mapPermission(status);
  }

  @override
  Future<CameraPermissionStatus> requestPermission() async {
    final status = await ph.Permission.camera.request();
    return _mapPermission(status);
  }

  @override
  Future<bool> openPermissionSettings() {
    return ph.openAppSettings();
  }

  @override
  Future<CameraSession> initialize({
    CameraLensPreference lens = CameraLensPreference.rear,
  }) async {
    final permission = await checkPermission();
    if (permission != CameraPermissionStatus.granted &&
        permission != CameraPermissionStatus.limited) {
      throw const PermissionException(
        message: 'Camera permission is required to start the preview.',
      );
    }

    // Shared singleton: additional consumers retain instead of re-init.
    if (_controller != null &&
        _session != null &&
        _controller!.value.isInitialized) {
      _ownerCount++;
      if (_isPaused) {
        return resume();
      }
      return _session!;
    }

    try {
      await _hardDisposeController();

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw const DeviceCameraException(
          message: 'No cameras are available on this device.',
        );
      }

      final description = _selectCamera(_cameras, lens);
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      // Lock capture orientation so preview + future AI frames stay stable.
      await controller.lockCaptureOrientation();

      _controller = controller;
      _isPaused = false;
      _isStreaming = false;
      _frameSequence = 0;
      _ownerCount = 1;

      final value = controller.value;
      final size = value.previewSize;
      _session = CameraSession(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        cameraName: description.name,
        lens: lens,
        previewWidth: size?.width.toInt() ?? 0,
        previewHeight: size?.height.toInt() ?? 0,
        sensorOrientation: description.sensorOrientation,
        isPaused: false,
        isStreamingFrames: false,
      );

      _emitSession();
      _logger.info(
        'Camera initialized: ${_session!.cameraName} '
        '(${_session!.previewWidth}x${_session!.previewHeight})',
        tag: 'CameraDataSource',
      );
      return _session!;
    } on CameraException catch (e, st) {
      throw DeviceCameraException(
        message: e.description ?? e.code,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is PermissionException || e is DeviceCameraException) rethrow;
      throw DeviceCameraException(
        message: 'Failed to initialize camera: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<CameraSession> pause() async {
    final controller = _requireController();
    final session = _requireSession();

    if (_isStreaming) {
      await _stopImageStreamSafe(controller);
      _isStreaming = false;
    }

    try {
      if (controller.value.isInitialized && controller.value.isPreviewPaused == false) {
        await controller.pausePreview();
      }
    } on CameraException catch (e, st) {
      throw DeviceCameraException(
        message: e.description ?? 'Failed to pause camera preview.',
        cause: e,
        stackTrace: st,
      );
    }

    _isPaused = true;
    _session = session.copyWith(isPaused: true, isStreamingFrames: false);
    _emitSession();
    _logger.debug('Camera paused', tag: 'CameraDataSource');
    return _session!;
  }

  @override
  Future<CameraSession> resume() async {
    final controller = _requireController();
    final session = _requireSession();

    try {
      if (controller.value.isInitialized && controller.value.isPreviewPaused) {
        await controller.resumePreview();
      }
    } on CameraException catch (e, st) {
      throw DeviceCameraException(
        message: e.description ?? 'Failed to resume camera preview.',
        cause: e,
        stackTrace: st,
      );
    }

    _isPaused = false;
    _session = session.copyWith(isPaused: false);
    _emitSession();
    _logger.debug('Camera resumed', tag: 'CameraDataSource');
    return _session!;
  }

  @override
  Future<CameraSession> startFrameStreaming({int targetFps = 8}) async {
    final controller = _requireController();
    final session = _requireSession();

    if (_isPaused) {
      throw const DeviceCameraException(
        message: 'Cannot stream frames while the camera is paused.',
      );
    }

    if (_isStreaming) {
      if (controller.value.isStreamingImages) {
        // Hot-update throttle without restarting the image stream (flood/YOLO FPS).
        _targetFps = targetFps.clamp(1, 30);
        _lastEmittedFrameAt = null;
        _logger.info(
          'Frame streaming FPS updated → ${_targetFps}fps',
          tag: 'CameraDataSource',
        );
        return session.copyWith(isStreamingFrames: true);
      }
      // Flag drifted (e.g. after takePicture) — fall through and restart.
      _isStreaming = false;
    }

    _targetFps = targetFps.clamp(1, 30);
    _lastEmittedFrameAt = null;
    _isProcessingFrame = false;

    try {
      await controller.startImageStream(_onCameraImage);
      _isStreaming = true;
      _session = session.copyWith(isStreamingFrames: true);
      _emitSession();
      _logger.info(
        'Frame streaming started @ ${_targetFps}fps (metadata only)',
        tag: 'CameraDataSource',
      );
      return _session!;
    } on CameraException catch (e, st) {
      throw DeviceCameraException(
        message: e.description ?? 'Failed to start frame streaming.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<CameraSession> stopFrameStreaming() async {
    final controller = _controller;
    final session = _session;
    if (controller == null || session == null) {
      throw const DeviceCameraException(message: 'Camera is not initialized.');
    }

    if (_isStreaming) {
      await _stopImageStreamSafe(controller);
      _isStreaming = false;
    }

    _session = session.copyWith(isStreamingFrames: false);
    _emitSession();
    _logger.debug('Frame streaming stopped', tag: 'CameraDataSource');
    return _session!;
  }

  @override
  Future<void> disposeCamera() async {
    if (_ownerCount > 0) {
      _ownerCount--;
    }
    // Other consumers still hold the shared session — soft release only.
    if (_ownerCount > 0) {
      if (_isStreaming) {
        await stopFrameStreaming();
      }
      _logger.debug(
        'Camera soft-released (owners=$_ownerCount)',
        tag: 'CameraDataSource',
      );
      return;
    }
    await _hardDisposeController();
  }

  Future<void> _hardDisposeController() async {
    final controller = _controller;
    if (controller == null) {
      _session = null;
      _ownerCount = 0;
      return;
    }

    try {
      if (_isStreaming) {
        await _stopImageStreamSafe(controller);
        _isStreaming = false;
      }
      await controller.dispose();
    } catch (e, st) {
      _logger.warning(
        'Error disposing camera controller',
        tag: 'CameraDataSource',
        error: e,
        stackTrace: st,
      );
    } finally {
      _controller = null;
      _session = null;
      _isPaused = false;
      _isProcessingFrame = false;
      _ownerCount = 0;
      _logger.debug('Camera disposed', tag: 'CameraDataSource');
    }
  }

  @override
  Future<CameraSession> handleOrientationChanged(int degrees) async {
    final session = _requireSession();
    // Capture orientation is locked for stable road-facing frames; we still
    // record device degrees on the session for UI chrome rotations.
    _session = session.copyWith(sensorOrientation: degrees);
    _emitSession();
    return _session!;
  }

  /// Releases stream controllers — call when unregistering from DI / app exit.
  Future<void> close() async {
    await disposeCamera();
    await _sessionController.close();
    await _frameController.close();
    await _rawFrameController.close();
  }

  void _onCameraImage(CameraImage image) {
    // Never block the camera callback with inference — only throttle + copy.
    if (_isPaused) return;

    final needsMeta = _frameController.hasListener;
    final needsRaw = _rawFrameController.hasListener;
    if (!needsMeta && !needsRaw) return;

    final now = DateTime.now();
    final minIntervalMs = (1000 / _targetFps).round();
    if (_lastEmittedFrameAt != null) {
      final elapsed = now.difference(_lastEmittedFrameAt!).inMilliseconds;
      if (elapsed < minIntervalMs) {
        return;
      }
    }

    // Guard concurrent copies without holding the camera image beyond this call.
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;
    try {
      final session = _session;
      if (session == null) return;

      _frameSequence += 1;
      _lastEmittedFrameAt = now;

      if (needsMeta) {
        _frameController.add(
          CameraFrameMeta(
            sessionId: session.sessionId,
            sequence: _frameSequence,
            timestamp: now,
            width: image.width,
            height: image.height,
          ),
        );
      }

      if (needsRaw) {
        // Typed copies — cheaper than List<int>.from on large YUV planes.
        final planes = <Uint8List>[
          for (final plane in image.planes) Uint8List.fromList(plane.bytes),
        ];
        final bytesPerRow = <int>[
          for (final plane in image.planes) plane.bytesPerRow,
        ];

        final format = switch (image.format.group) {
          ImageFormatGroup.bgra8888 => 'bgra8888',
          ImageFormatGroup.yuv420 => 'yuv420',
          ImageFormatGroup.nv21 => 'yuv420',
          _ => 'yuv420',
        };

        _rawFrameController.add(
          CameraRawFrame(
            sequence: _frameSequence,
            width: image.width,
            height: image.height,
            planes: planes,
            bytesPerRow: bytesPerRow,
            rotationDegrees: session.sensorOrientation,
            format: format,
          ),
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _stopImageStreamSafe(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e, st) {
      _logger.warning(
        'stopImageStream failed',
        tag: 'CameraDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }

  CameraDescription _selectCamera(
    List<CameraDescription> cameras,
    CameraLensPreference lens,
  ) {
    final desired = lens == CameraLensPreference.rear
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    CameraDescription? match;
    for (final camera in cameras) {
      if (camera.lensDirection == desired) {
        match = camera;
        break;
      }
    }

    if (match != null) {
      return match;
    }

    if (lens == CameraLensPreference.rear) {
      _logger.warning(
        'Rear camera not found — falling back to first available camera',
        tag: 'CameraDataSource',
      );
    }

    return cameras.first;
  }

  CameraPermissionStatus _mapPermission(ph.PermissionStatus status) {
    if (status.isGranted) return CameraPermissionStatus.granted;
    if (status.isLimited) return CameraPermissionStatus.limited;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    if (status.isDenied) return CameraPermissionStatus.denied;
    return CameraPermissionStatus.denied;
  }

  CameraController _requireController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const DeviceCameraException(message: 'Camera is not initialized.');
    }
    return controller;
  }

  CameraSession _requireSession() {
    final session = _session;
    if (session == null) {
      throw const DeviceCameraException(message: 'Camera session is missing.');
    }
    return session;
  }

  void _emitSession() {
    final session = _session;
    if (session != null && !_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }

  /// Debug helper — whether web/desktop may lack cameras.
  @visibleForTesting
  bool get isStreamingForTest => _isStreaming;
}
