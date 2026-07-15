import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/processors/segmentation_postprocessor.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/processors/yolo_preprocessor.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_detection_config.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Low-level TFLite semantic segmentation for flood detection.
abstract class FloodSegmentationDataSource {
  Future<FloodDetectionSession> initialize();

  Future<FloodDetectionSession> start();

  Future<FloodDetectionSession> stop();

  Future<void> disposeEngine();

  Future<FloodSegmentationResult> segment(CameraRawFrame frame);

  Stream<FloodSegmentationResult> get resultStream;

  Stream<FloodDetectionSession> get sessionStream;

  FloodDetectionSession get currentSession;

  /// Latest RGBA overlay bytes (maskW * maskH * 4) for painters.
  Uint8List? get latestOverlayRgba;

  int get latestOverlayWidth;

  int get latestOverlayHeight;
}

/// Production segmentation data source (GPU → NNAPI → CPU).
class TfliteFloodSegmentationDataSource implements FloodSegmentationDataSource {
  final AppLogger _logger;
  final CameraRepository _cameraRepository;
  final String modelAssetPath;
  final String labelsAssetPath;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  SegmentationPostprocessor? _postprocessor;
  List<String> _labels = const [];
  InferenceDelegateKind _delegate = InferenceDelegateKind.unknown;
  FloodDetectionSession _session = const FloodDetectionSession.idle();
  List<int> _outputShape = const [];

  /// True when [modelAssetPath] is absent — emits empty masks so the camera
  /// pipeline stays live until a research model is dropped in.
  bool _stubMode = false;

  final StreamController<FloodSegmentationResult> _resultController =
      StreamController<FloodSegmentationResult>.broadcast();
  final StreamController<FloodDetectionSession> _sessionController =
      StreamController<FloodDetectionSession>.broadcast();

  StreamSubscription<CameraRawFrame>? _frameSub;
  bool _busy = false;
  bool _streaming = false;
  double _latencyEma = 0;
  int _processed = 0;
  int _skipped = 0;

  Uint8List? _latestOverlayRgba;
  int _overlayW = 0;
  int _overlayH = 0;

  /// Reused 4D input nest [1][H][W][3] — refilled each frame (GC relief).
  List<List<List<List<double>>>>? _cachedInput;

  /// Reused nested output buffer matching [_outputShape].
  Object? _cachedOutput;

  /// Flat destination for walk — grown once.
  final List<double> _flatScratch = <double>[];

  /// Creates [TfliteFloodSegmentationDataSource].
  TfliteFloodSegmentationDataSource({
    required AppLogger logger,
    required CameraRepository cameraRepository,
    this.modelAssetPath = FloodDetectionConfig.modelAssetPath,
    this.labelsAssetPath = FloodDetectionConfig.labelsAssetPath,
  })  : _logger = logger,
        _cameraRepository = cameraRepository;

  @override
  FloodDetectionSession get currentSession => _session;

  @override
  Stream<FloodSegmentationResult> get resultStream => _resultController.stream;

  @override
  Stream<FloodDetectionSession> get sessionStream => _sessionController.stream;

  @override
  Uint8List? get latestOverlayRgba => _latestOverlayRgba;

  @override
  int get latestOverlayWidth => _overlayW;

  @override
  int get latestOverlayHeight => _overlayH;

  @override
  Future<FloodDetectionSession> initialize() async {
    _emitSession(_session.copyWith(status: InferenceEngineStatus.loading));

    try {
      _labels = await _loadLabels(labelsAssetPath);
      if (_labels.isEmpty) {
        throw const InferenceException(
          message: 'Flood segmentation labels are empty.',
        );
      }

      final modelPresent = await _isModelAssetPresent();
      if (!modelPresent) {
        return _enterStubMode();
      }

      _stubMode = false;
      _interpreter = await _createInterpreterWithDelegates();
      _outputShape = List<int>.from(_interpreter!.getOutputTensor(0).shape);
      _postprocessor = SegmentationPostprocessor(labels: _labels);

      try {
        _isolateInterpreter = await IsolateInterpreter.create(
          address: _interpreter!.address,
          debugName: 'FloodSegIsolate',
        );
      } catch (e, st) {
        _logger.warning(
          'IsolateInterpreter unavailable for flood seg',
          tag: 'FloodSegDS',
          error: e,
          stackTrace: st,
        );
        _isolateInterpreter = null;
      }

      _emitSession(
        FloodDetectionSession(
          status: InferenceEngineStatus.ready,
          delegate: _delegate,
          labels: _labels,
        ),
      );
      _logger.info(
        'Flood segmentation ready · ${_delegate.name} · out=$_outputShape',
        tag: 'FloodSegDS',
      );
      return _session;
    } catch (e, st) {
      _emitSession(_session.copyWith(status: InferenceEngineStatus.failed));
      if (e is InferenceException) rethrow;
      throw InferenceException(
        message: 'Flood segmentation initialize failed: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<FloodDetectionSession> start() async {
    final needsInit = (!_stubMode && _interpreter == null) ||
        _session.status == InferenceEngineStatus.idle ||
        _session.status == InferenceEngineStatus.failed;
    if (needsInit) {
      await initialize();
    }

    await _frameSub?.cancel();
    _streaming = true;
    _busy = false;

    // A failure here is non-fatal: the raw-frame subscription below still
    // attaches, and frames flow once the camera (re)starts its image stream.
    final streamResult = await _cameraRepository.startFrameStreaming(
      targetFps: FloodDetectionConfig.targetFps,
    );
    streamResult.fold(
      onOk: (_) {},
      onErr: (failure) => _logger.warning(
        'Camera frame streaming unavailable: ${failure.message}',
        tag: 'FloodSegDS',
      ),
    );

    _frameSub = _cameraRepository.watchRawFrames().listen(
      _onRawFrame,
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning(
          'Raw frame stream error: $error',
          tag: 'FloodSegDS',
          error: error,
          stackTrace: stackTrace,
        );
      },
      cancelOnError: false,
    );
    _emitSession(
      _session.copyWith(
        status: InferenceEngineStatus.running,
        isStreaming: true,
      ),
    );
    return _session;
  }

  @override
  Future<FloodDetectionSession> stop() async {
    _streaming = false;
    await _frameSub?.cancel();
    _frameSub = null;
    _busy = false;
    _emitSession(
      _session.copyWith(
        status: InferenceEngineStatus.paused,
        isStreaming: false,
      ),
    );
    return _session;
  }

  @override
  Future<void> disposeEngine() async {
    // Soft dispose: stop streaming but keep the TFLite interpreter warm.
    // The data source is a GetIt singleton shared by dashboard + feature pages.
    await stop();
    _latestOverlayRgba = null;
    _emitSession(
      _session.copyWith(
        status: InferenceEngineStatus.paused,
        isStreaming: false,
      ),
    );
  }

  @override
  Future<FloodSegmentationResult> segment(CameraRawFrame frame) {
    return _runPipeline(frame);
  }

  Future<void> _onRawFrame(CameraRawFrame frame) async {
    if (!_streaming) return;
    if (_busy) {
      _skipped += 1;
      // Throttle skip telemetry — avoids HUD/bloc rebuild storms.
      if (_skipped % 8 == 0) {
        _emitSession(_session.copyWith(skippedFrames: _skipped));
      }
      return;
    }

    _busy = true;
    try {
      final result = await _runPipeline(frame);
      if (!_resultController.isClosed) {
        _resultController.add(result);
      }
    } catch (e, st) {
      _logger.warning(
        'Flood seg frame failed',
        tag: 'FloodSegDS',
        error: e,
        stackTrace: st,
      );
    } finally {
      _busy = false;
    }
  }

  Future<FloodSegmentationResult> _runPipeline(CameraRawFrame frame) async {
    if (_stubMode) {
      return _stubResult(frame);
    }

    final interpreter = _interpreter;
    final post = _postprocessor;
    if (interpreter == null || post == null) {
      throw const InferenceException(message: 'Flood seg engine not ready.');
    }

    final sw = Stopwatch()..start();
    final size = FloodDetectionConfig.inputSize;
    final preprocess = await Isolate.run(
      () => YoloPreprocessor(inputSize: size).process(frame),
    );

    final input = _buildInputTensor(preprocess.input, size);
    final output = _allocateOutputBuffer(_outputShape);

    final isolate = _isolateInterpreter;
    if (isolate != null) {
      await isolate.run(input, output);
    } else {
      interpreter.run(input, output);
    }

    final flat = _flattenOutput(output);
    final decoded = post.process(flat: flat, shape: _outputShape);

    _latestOverlayRgba = post.buildRgbaOverlay(
      classIndices: decoded.classIndices,
      width: decoded.width,
      height: decoded.height,
    );
    _overlayW = decoded.width;
    _overlayH = decoded.height;

    sw.stop();
    _processed += 1;
    final ms = sw.elapsedMilliseconds.toDouble();
    _latencyEma = _latencyEma == 0 ? ms : (_latencyEma * 0.8 + ms * 0.2);

    if (_processed % 2 == 0) {
      _emitSession(
        _session.copyWith(
          processedFrames: _processed,
          averageLatencyMs: _latencyEma,
          status: InferenceEngineStatus.running,
          isStreaming: _streaming,
        ),
      );
    }

    return FloodSegmentationResult(
      frameSequence: frame.sequence,
      maskWidth: decoded.width,
      maskHeight: decoded.height,
      classIndices: decoded.classIndices,
      confidences: decoded.confidences,
      stats: decoded.stats,
      inferenceDuration: sw.elapsed,
      delegate: _delegate,
    );
  }

  Future<Interpreter> _createInterpreterWithDelegates() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final options = InterpreterOptions()
          ..threads = FloodDetectionConfig.cpuThreads
          ..addDelegate(
            GpuDelegateV2(
              options: GpuDelegateOptionsV2(isPrecisionLossAllowed: true),
            ),
          );
        final interpreter = await Interpreter.fromAsset(
          modelAssetPath,
          options: options,
        );
        _delegate = InferenceDelegateKind.gpu;
        return interpreter;
      } catch (e) {
        _logger.debug('Flood seg GPU unavailable, trying next: $e', tag: 'FloodSegDS');
      }

      try {
        final options = InterpreterOptions()
          ..threads = FloodDetectionConfig.cpuThreads
          ..useNnApiForAndroid = true;
        final interpreter = await Interpreter.fromAsset(
          modelAssetPath,
          options: options,
        );
        _delegate = InferenceDelegateKind.nnapi;
        return interpreter;
      } catch (e) {
        _logger.debug('Flood seg NNAPI unavailable, trying CPU: $e', tag: 'FloodSegDS');
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      try {
        final options = InterpreterOptions()
          ..threads = FloodDetectionConfig.cpuThreads
          ..addDelegate(GpuDelegate());
        final interpreter = await Interpreter.fromAsset(
          modelAssetPath,
          options: options,
        );
        _delegate = InferenceDelegateKind.metal;
        return interpreter;
      } catch (e) {
        _logger.debug('Flood seg Metal unavailable, trying CPU: $e', tag: 'FloodSegDS');
      }
    }

    final options = InterpreterOptions()
      ..threads = FloodDetectionConfig.cpuThreads;
    try {
      options.addDelegate(XNNPackDelegate());
    } catch (_) {}
    final interpreter = await Interpreter.fromAsset(
      modelAssetPath,
      options: options,
    );
    _delegate = InferenceDelegateKind.cpu;
    return interpreter;
  }

  Future<bool> _isModelAssetPresent() async {
    try {
      final data = await rootBundle.load(modelAssetPath);
      return data.lengthInBytes > 0;
    } catch (_) {
      return false;
    }
  }

  FloodDetectionSession _enterStubMode() {
    _stubMode = true;
    _interpreter = null;
    _isolateInterpreter = null;
    _outputShape = const [1, 80, 80, 5];
    _postprocessor = SegmentationPostprocessor(labels: _labels);
    _delegate = InferenceDelegateKind.unknown;

    _emitSession(
      FloodDetectionSession(
        status: InferenceEngineStatus.ready,
        delegate: _delegate,
        labels: _labels,
      ),
    );
    _logger.warning(
      'Flood seg model missing at $modelAssetPath — stub mode (empty masks). '
      'Drop a 5-class TFLite model there to enable inference. '
      'See assets/models/FLOOD_SEG_README.txt.',
      tag: 'FloodSegDS',
    );
    return _session;
  }

  FloodSegmentationResult _stubResult(CameraRawFrame frame) {
    const width = 80;
    const height = 80;
    final classIndices = List<int>.filled(width * height, 0);
    final confidences = List<double>.filled(width * height, 0);
    final post = _postprocessor ?? SegmentationPostprocessor(labels: _labels);

    _latestOverlayRgba = post.buildRgbaOverlay(
      classIndices: classIndices,
      width: width,
      height: height,
    );
    _overlayW = width;
    _overlayH = height;

    _processed += 1;
    if (_processed % 8 == 0) {
      _emitSession(
        _session.copyWith(
          processedFrames: _processed,
          status: InferenceEngineStatus.running,
          isStreaming: _streaming,
        ),
      );
    }

    return FloodSegmentationResult(
      frameSequence: frame.sequence,
      maskWidth: width,
      maskHeight: height,
      classIndices: classIndices,
      confidences: confidences,
      stats: const FloodCoverageStats.zero(),
      inferenceDuration: Duration.zero,
      delegate: InferenceDelegateKind.unknown,
    );
  }

  Object _buildInputTensor(Float32List flat, int size) {
    _cachedInput ??= [
      List.generate(
        size,
        (_) => List.generate(
          size,
          (_) => List<double>.filled(3, 0),
        ),
      ),
    ];
    final batch = _cachedInput![0];
    for (var y = 0; y < size; y++) {
      final row = batch[y];
      for (var x = 0; x < size; x++) {
        final base = (y * size + x) * 3;
        final pixel = row[x];
        pixel[0] = flat[base];
        pixel[1] = flat[base + 1];
        pixel[2] = flat[base + 2];
      }
    }
    return _cachedInput!;
  }

  Object _allocateOutputBuffer(List<int> shape) {
    if (_cachedOutput != null) {
      return _cachedOutput!;
    }
    if (shape.length == 4) {
      _cachedOutput = [
        List.generate(
          shape[1],
          (_) => List.generate(
            shape[2],
            (_) => List<double>.filled(shape[3], 0),
          ),
        ),
      ];
    } else if (shape.length == 3) {
      _cachedOutput = [
        List.generate(
          shape[1],
          (_) => List<double>.filled(shape[2], 0),
        ),
      ];
    } else {
      final size = shape.fold<int>(1, (a, b) => a * b);
      _cachedOutput = List<double>.filled(size, 0).reshape(shape);
    }
    return _cachedOutput!;
  }

  List<double> _flattenOutput(Object output) {
    _flatScratch.clear();
    void walk(dynamic node) {
      if (node is num) {
        _flatScratch.add(node.toDouble());
      } else if (node is List) {
        for (final child in node) {
          walk(child);
        }
      }
    }

    walk(output);
    return List<double>.from(_flatScratch);
  }

  Future<List<String>> _loadLabels(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList(growable: false);
  }

  void _emitSession(FloodDetectionSession session) {
    _session = session;
    if (!_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }
}
