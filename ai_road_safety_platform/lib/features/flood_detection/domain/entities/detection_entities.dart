import 'package:equatable/equatable.dart';

/// Hardware acceleration backend selected for TFLite.
enum InferenceDelegateKind {
  /// Android GPU delegate (GpuDelegateV2).
  gpu,

  /// Android NNAPI.
  nnapi,

  /// iOS Metal GPU delegate.
  metal,

  /// XNNPACK / multi-thread CPU fallback.
  cpu,

  /// Delegate not resolved yet.
  unknown,
}

/// Status of the inference engine lifecycle.
enum InferenceEngineStatus {
  /// Not loaded.
  idle,

  /// Loading model / labels / delegates.
  loading,

  /// Ready to accept frames.
  ready,

  /// Actively processing the live stream.
  running,

  /// Paused (camera paused / user stop).
  paused,

  /// Fatal load / runtime failure.
  failed,
}

/// Normalized axis-aligned bounding box in model/letterbox space (0–1).
class DetectionBox extends Equatable {
  /// Left edge (0–1 relative to letterboxed frame).
  final double left;

  /// Top edge (0–1).
  final double top;

  /// Right edge (0–1).
  final double right;

  /// Bottom edge (0–1).
  final double bottom;

  /// Creates a [DetectionBox].
  const DetectionBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Box width.
  double get width => right - left;

  /// Box height.
  double get height => bottom - top;

  @override
  List<Object?> get props => [left, top, right, bottom];
}

/// Single YOLOv8 detection after confidence filtering + NMS.
class Detection extends Equatable {
  /// Class index into the labels list.
  final int classIndex;

  /// Human-readable class label.
  final String label;

  /// Confidence score in \[0, 1\].
  final double confidence;

  /// Bounding box in preview-normalized coordinates (0–1).
  final DetectionBox box;

  /// Creates a [Detection].
  const Detection({
    required this.classIndex,
    required this.label,
    required this.confidence,
    required this.box,
  });

  @override
  List<Object?> get props => [classIndex, label, confidence, box];
}

/// Result of one inference pass on a camera frame.
class InferenceResult extends Equatable {
  /// Frame sequence correlated with the camera stream.
  final int frameSequence;

  /// Wall-clock inference duration.
  final Duration inferenceDuration;

  /// Filtered detections for overlay.
  final List<Detection> detections;

  /// Active delegate for HUD / diagnostics.
  final InferenceDelegateKind delegate;

  /// Input tensor size used for this model.
  final int inputSize;

  /// Creates an [InferenceResult].
  const InferenceResult({
    required this.frameSequence,
    required this.inferenceDuration,
    required this.detections,
    required this.delegate,
    required this.inputSize,
  });

  /// Empty result helper.
  const InferenceResult.empty({
    required this.frameSequence,
    required this.delegate,
    required this.inputSize,
  })  : inferenceDuration = Duration.zero,
        detections = const [];

  @override
  List<Object?> get props => [
        frameSequence,
        inferenceDuration,
        detections,
        delegate,
        inputSize,
      ];
}

/// Live engine snapshot for Bloc / HUD.
class InferenceSession extends Equatable {
  /// Engine lifecycle status.
  final InferenceEngineStatus status;

  /// Selected acceleration backend.
  final InferenceDelegateKind delegate;

  /// Loaded class labels.
  final List<String> labels;

  /// Whether the live frame pipe is accepting frames.
  final bool isStreaming;

  /// Rolling average inference latency (ms) for HUD.
  final double averageLatencyMs;

  /// Frames processed since start.
  final int processedFrames;

  /// Frames skipped by throttle / busy-guard (preview never blocked).
  final int skippedFrames;

  /// Creates an [InferenceSession].
  const InferenceSession({
    required this.status,
    required this.delegate,
    required this.labels,
    this.isStreaming = false,
    this.averageLatencyMs = 0,
    this.processedFrames = 0,
    this.skippedFrames = 0,
  });

  /// Initial idle session.
  const InferenceSession.idle()
      : status = InferenceEngineStatus.idle,
        delegate = InferenceDelegateKind.unknown,
        labels = const [],
        isStreaming = false,
        averageLatencyMs = 0,
        processedFrames = 0,
        skippedFrames = 0;

  /// Copy with overrides.
  InferenceSession copyWith({
    InferenceEngineStatus? status,
    InferenceDelegateKind? delegate,
    List<String>? labels,
    bool? isStreaming,
    double? averageLatencyMs,
    int? processedFrames,
    int? skippedFrames,
  }) {
    return InferenceSession(
      status: status ?? this.status,
      delegate: delegate ?? this.delegate,
      labels: labels ?? this.labels,
      isStreaming: isStreaming ?? this.isStreaming,
      averageLatencyMs: averageLatencyMs ?? this.averageLatencyMs,
      processedFrames: processedFrames ?? this.processedFrames,
      skippedFrames: skippedFrames ?? this.skippedFrames,
    );
  }

  @override
  List<Object?> get props => [
        status,
        delegate,
        labels,
        isStreaming,
        averageLatencyMs,
        processedFrames,
        skippedFrames,
      ];
}
