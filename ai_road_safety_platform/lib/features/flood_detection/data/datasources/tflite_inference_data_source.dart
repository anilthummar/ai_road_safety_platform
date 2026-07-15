import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/processors/yolo_postprocessor.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/processors/yolo_preprocessor.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/inference_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Low-level TFLite YOLOv8 inference + camera frame consumption.
abstract class InferenceLocalDataSource {
  Future<InferenceSession> initialize();

  Future<InferenceSession> start();

  Future<InferenceSession> stop();

  Future<void> disposeEngine();

  Future<InferenceResult> detect(CameraRawFrame frame);

  Stream<InferenceResult> get resultStream;

  Stream<InferenceSession> get sessionStream;

  InferenceSession get currentSession;
}

/// Production TFLite data source with GPU → NNAPI → CPU delegate cascade.
class TfliteInferenceDataSource implements InferenceLocalDataSource {
  final AppLogger _logger;
  final CameraRepository _cameraRepository;
  final String modelAssetPath;
  final String labelsAssetPath;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  YoloPostprocessor? _postprocessor;
  List<String> _labels = const [];
  InferenceDelegateKind _delegate = InferenceDelegateKind.unknown;
  InferenceSession _session = const InferenceSession.idle();
  List<int> _outputShape = const [];

  /// True when [modelAssetPath] is absent — streams empty detections.
  bool _stubMode = false;

  final StreamController<InferenceResult> _resultController =
      StreamController<InferenceResult>.broadcast();
  final StreamController<InferenceSession> _sessionController =
      StreamController<InferenceSession>.broadcast();

  StreamSubscription<CameraRawFrame>? _frameSub;
  bool _busy = false;
  bool _streaming = false;
  double _latencyEma = 0;
  int _processed = 0;
  int _skipped = 0;

  List<List<List<List<double>>>>? _cachedInput;
  Object? _cachedOutput;
  final List<double> _flatScratch = <double>[];

  /// Creates [TfliteInferenceDataSource].
  TfliteInferenceDataSource({
    required AppLogger logger,
    required CameraRepository cameraRepository,
    this.modelAssetPath = InferenceConfig.modelAssetPath,
    this.labelsAssetPath = InferenceConfig.labelsAssetPath,
  })  : _logger = logger,
        _cameraRepository = cameraRepository;

  @override
  InferenceSession get currentSession => _session;

  @override
  Stream<InferenceResult> get resultStream => _resultController.stream;

  @override
  Stream<InferenceSession> get sessionStream => _sessionController.stream;

  @override
  Future<InferenceSession> initialize() async {
    _emitSession(
      _session.copyWith(status: InferenceEngineStatus.loading),
    );

    try {
      _labels = await _loadLabels(labelsAssetPath);
      if (_labels.isEmpty) {
        throw const InferenceException(
          message: 'Label file is empty. Check assets/labels/.',
        );
      }

      final modelPresent = await _isModelAssetPresent();
      if (!modelPresent) {
        return _enterStubMode();
      }

      _stubMode = false;
      _interpreter = await _createInterpreterWithDelegates();
      _outputShape = List<int>.from(_interpreter!.getOutputTensor(0).shape);

      try {
        _isolateInterpreter = await IsolateInterpreter.create(
          address: _interpreter!.address,
          debugName: 'YoloInferenceIsolate',
        );
      } catch (e, st) {
        _logger.warning(
          'IsolateInterpreter unavailable — using in-process invoke',
          tag: 'InferenceDS',
          error: e,
          stackTrace: st,
        );
        _isolateInterpreter = null;
      }

      _postprocessor = YoloPostprocessor(labels: _labels);

      _emitSession(
        InferenceSession(
          status: InferenceEngineStatus.ready,
          delegate: _delegate,
          labels: _labels,
        ),
      );

      _logger.info(
        'YOLOv8 ready · delegate=${_delegate.name} · '
        'out=$_outputShape · classes=${_labels.length}',
        tag: 'InferenceDS',
      );
      return _session;
    } catch (e, st) {
      _emitSession(
        _session.copyWith(status: InferenceEngineStatus.failed),
      );
      if (e is InferenceException) rethrow;
      throw InferenceException(
        message: 'Inference initialize failed: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<InferenceSession> start() async {
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
      targetFps: InferenceConfig.targetInferenceFps,
    );
    streamResult.fold(
      onOk: (_) {},
      onErr: (failure) => _logger.warning(
        'Camera frame streaming unavailable: ${failure.message}',
        tag: 'InferenceDS',
      ),
    );

    _frameSub = _cameraRepository.watchRawFrames().listen(
      _onRawFrame,
      onError: (Object e, StackTrace st) {
        _logger.error(
          'Raw frame stream error',
          tag: 'InferenceDS',
          error: e,
          stackTrace: st,
        );
      },
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
  Future<InferenceSession> stop() async {
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
    // Soft dispose for shared singleton — keep interpreter warm.
    await stop();
    _emitSession(
      _session.copyWith(
        status: InferenceEngineStatus.paused,
        isStreaming: false,
      ),
    );
  }

  @override
  Future<InferenceResult> detect(CameraRawFrame frame) {
    return _runPipeline(frame);
  }

  Future<void> _onRawFrame(CameraRawFrame frame) async {
    if (!_streaming) return;

    // Busy-guard: skip backlog instead of queuing — preview never stalls.
    if (_busy) {
      _skipped += 1;
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
        'Inference frame failed',
        tag: 'InferenceDS',
        error: e,
        stackTrace: st,
      );
    } finally {
      _busy = false;
    }
  }

  Future<InferenceResult> _runPipeline(CameraRawFrame frame) async {
    if (_stubMode) {
      return _stubResult(frame);
    }

    final interpreter = _interpreter;
    final post = _postprocessor;
    if (interpreter == null || post == null) {
      throw const InferenceException(message: 'Engine not initialized.');
    }

    final sw = Stopwatch()..start();

    final preprocess =
        await Isolate.run(() => preprocessCameraFrameIsolate(frame));

    final input = _buildInputTensor(preprocess.input);
    final output = _allocateOutputBuffer(_outputShape);

    final isolate = _isolateInterpreter;
    if (isolate != null) {
      await isolate.run(input, output);
    } else {
      interpreter.run(input, output);
    }

    final flat = _flattenOutput(output);
    final detections = post.processShaped(
      flat: flat,
      shape: _outputShape,
      preprocess: preprocess,
    );

    sw.stop();
    _processed += 1;
    final ms = sw.elapsedMilliseconds.toDouble();
    _latencyEma = _latencyEma == 0 ? ms : (_latencyEma * 0.8 + ms * 0.2);

    // Throttle session metric emissions to reduce Bloc rebuild pressure.
    if (_processed % 3 == 0) {
      _emitSession(
        _session.copyWith(
          processedFrames: _processed,
          averageLatencyMs: _latencyEma,
          status: InferenceEngineStatus.running,
          isStreaming: _streaming,
        ),
      );
    }

    return InferenceResult(
      frameSequence: frame.sequence,
      inferenceDuration: sw.elapsed,
      detections: detections,
      delegate: _delegate,
      inputSize: InferenceConfig.inputSize,
    );
  }

  Future<Interpreter> _createInterpreterWithDelegates() async {
    // Try GPU → NNAPI → CPU cascade without failing the whole load.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final options = InterpreterOptions()
          ..threads = InferenceConfig.cpuThreads
          ..addDelegate(
            GpuDelegateV2(
              options: GpuDelegateOptionsV2(
                isPrecisionLossAllowed: true,
              ),
            ),
          );
        final interpreter = await Interpreter.fromAsset(
          modelAssetPath,
          options: options,
        );
        _delegate = InferenceDelegateKind.gpu;
        _logger.info('Using Android GPU delegate (GpuDelegateV2)', tag: 'InferenceDS');
        return interpreter;
      } catch (e) {
        _logger.debug('GPU unavailable, trying NNAPI: $e', tag: 'InferenceDS');
      }

      try {
        final options = InterpreterOptions()
          ..threads = InferenceConfig.cpuThreads
          ..useNnApiForAndroid = true;
        final interpreter = await Interpreter.fromAsset(
          modelAssetPath,
          options: options,
        );
        _delegate = InferenceDelegateKind.nnapi;
        _logger.info('Using Android NNAPI delegate', tag: 'InferenceDS');
        return interpreter;
      } catch (e) {
        _logger.debug('NNAPI unavailable, trying CPU: $e', tag: 'InferenceDS');
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      try {
        final options = InterpreterOptions()
          ..threads = InferenceConfig.cpuThreads
          ..addDelegate(GpuDelegate());
        final interpreter = await Interpreter.fromAsset(
          modelAssetPath,
          options: options,
        );
        _delegate = InferenceDelegateKind.metal;
        _logger.info('Using iOS Metal GPU delegate', tag: 'InferenceDS');
        return interpreter;
      } catch (e) {
        _logger.debug('Metal unavailable, trying CPU: $e', tag: 'InferenceDS');
      }
    }

    final options = InterpreterOptions()..threads = InferenceConfig.cpuThreads;
    try {
      options.addDelegate(XNNPackDelegate());
    } catch (_) {}
    final interpreter = await Interpreter.fromAsset(
      modelAssetPath,
      options: options,
    );
    _delegate = InferenceDelegateKind.cpu;
    _logger.info(
      'Using CPU / XNNPACK threads=${InferenceConfig.cpuThreads}',
      tag: 'InferenceDS',
    );
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

  InferenceSession _enterStubMode() {
    _stubMode = true;
    _interpreter = null;
    _isolateInterpreter = null;
    _outputShape = const [];
    _postprocessor = YoloPostprocessor(labels: _labels);
    _delegate = InferenceDelegateKind.unknown;

    _emitSession(
      InferenceSession(
        status: InferenceEngineStatus.ready,
        delegate: _delegate,
        labels: _labels,
      ),
    );
    _logger.warning(
      'YOLO model missing at $modelAssetPath — stub mode (no detections). '
      'Export yolov8n.tflite into assets/models/. See assets/models/README.txt.',
      tag: 'InferenceDS',
    );
    return _session;
  }

  InferenceResult _stubResult(CameraRawFrame frame) {
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
    return InferenceResult.empty(
      frameSequence: frame.sequence,
      delegate: InferenceDelegateKind.unknown,
      inputSize: InferenceConfig.inputSize,
    );
  }

  Object _buildInputTensor(Float32List flat) {
    final size = InferenceConfig.inputSize;
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
    if (_cachedOutput != null) return _cachedOutput!;
    if (shape.length == 3) {
      _cachedOutput = [
        List.generate(
          shape[1],
          (_) => List<double>.filled(shape[2], 0),
        ),
      ];
    } else if (shape.length == 2) {
      _cachedOutput = [
        List.generate(
          shape[0],
          (_) => List<double>.filled(shape[1], 0),
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

  void _emitSession(InferenceSession session) {
    _session = session;
    if (!_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }
}
