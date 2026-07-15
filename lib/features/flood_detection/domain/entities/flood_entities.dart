import 'package:equatable/equatable.dart';

import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';

/// Semantic classes for flooded-road research segmentation.
enum FloodSegmentClass {
  /// Non-road / ignore class.
  background,

  /// Drivable or visible road surface.
  road,

  /// Standing / flowing water on or near the road.
  water,

  /// Vehicle occupying the scene.
  vehicle,

  /// Static or dynamic obstacle (debris, barrier, etc.).
  obstacle,
}

/// Extension helpers for [FloodSegmentClass].
extension FloodSegmentClassX on FloodSegmentClass {
  /// Stable wire / label name.
  String get labelName => name;

  /// Parses a label string into a class (case-insensitive).
  static FloodSegmentClass fromLabel(String label) {
    final key = label.trim().toLowerCase();
    return switch (key) {
      'road' => FloodSegmentClass.road,
      'water' || 'standing_water' || 'flooded_road' => FloodSegmentClass.water,
      'vehicle' || 'car' || 'truck' || 'bus' => FloodSegmentClass.vehicle,
      'obstacle' || 'debris' || 'pothole' || 'hidden_hazard' =>
        FloodSegmentClass.obstacle,
      _ => FloodSegmentClass.background,
    };
  }
}

/// Per-class pixel coverage statistics for one frame.
class FloodCoverageStats extends Equatable {
  /// Water pixels as percent of valid (non-pad) scene area \[0–100\].
  final double waterCoveragePercent;

  /// Road pixels as percent of valid scene area \[0–100\].
  final double roadCoveragePercent;

  /// Vehicle pixels as percent of valid scene area \[0–100\].
  final double vehicleCoveragePercent;

  /// Obstacle pixels as percent of valid scene area \[0–100\].
  final double obstacleCoveragePercent;

  /// Background percent of valid scene area \[0–100\].
  final double backgroundCoveragePercent;

  /// Mean max-class confidence across pixels \[0–1\].
  final double meanConfidence;

  /// Creates [FloodCoverageStats].
  const FloodCoverageStats({
    required this.waterCoveragePercent,
    required this.roadCoveragePercent,
    required this.vehicleCoveragePercent,
    required this.obstacleCoveragePercent,
    required this.backgroundCoveragePercent,
    required this.meanConfidence,
  });

  /// Zeroed stats.
  const FloodCoverageStats.zero()
      : waterCoveragePercent = 0,
        roadCoveragePercent = 0,
        vehicleCoveragePercent = 0,
        obstacleCoveragePercent = 0,
        backgroundCoveragePercent = 100,
        meanConfidence = 0;

  /// True when water coverage suggests a flood / hazard condition.
  bool get isFloodLikely => waterCoveragePercent >= 8;

  @override
  List<Object?> get props => [
        waterCoveragePercent,
        roadCoveragePercent,
        vehicleCoveragePercent,
        obstacleCoveragePercent,
        backgroundCoveragePercent,
        meanConfidence,
      ];
}

/// One segmentation inference result (mask + coverage).
class FloodSegmentationResult extends Equatable {
  /// Correlated camera frame sequence.
  final int frameSequence;

  /// Mask width (model output spatial).
  final int maskWidth;

  /// Mask height (model output spatial).
  final int maskHeight;

  /// Per-pixel class indices (length = maskWidth * maskHeight).
  final List<int> classIndices;

  /// Optional per-pixel max confidence (same length); empty if unavailable.
  final List<double> confidences;

  /// Aggregated coverage + confidence metrics.
  final FloodCoverageStats stats;

  /// Inference wall time.
  final Duration inferenceDuration;

  /// Active TFLite delegate.
  final InferenceDelegateKind delegate;

  /// Creates [FloodSegmentationResult].
  const FloodSegmentationResult({
    required this.frameSequence,
    required this.maskWidth,
    required this.maskHeight,
    required this.classIndices,
    required this.confidences,
    required this.stats,
    required this.inferenceDuration,
    required this.delegate,
  });

  @override
  List<Object?> get props => [
        frameSequence,
        maskWidth,
        maskHeight,
        classIndices,
        confidences,
        stats,
        inferenceDuration,
        delegate,
      ];
}

/// Flood detection engine session snapshot for Bloc / HUD.
class FloodDetectionSession extends Equatable {
  /// Engine lifecycle (reuses inference status enum).
  final InferenceEngineStatus status;

  /// Selected delegate.
  final InferenceDelegateKind delegate;

  /// Class labels loaded from assets.
  final List<String> labels;

  /// Whether the live pipe is active.
  final bool isStreaming;

  /// Rolling average latency (ms).
  final double averageLatencyMs;

  /// Frames processed.
  final int processedFrames;

  /// Frames skipped by busy-guard.
  final int skippedFrames;

  /// Creates [FloodDetectionSession].
  const FloodDetectionSession({
    required this.status,
    required this.delegate,
    required this.labels,
    this.isStreaming = false,
    this.averageLatencyMs = 0,
    this.processedFrames = 0,
    this.skippedFrames = 0,
  });

  /// Idle factory.
  const FloodDetectionSession.idle()
      : status = InferenceEngineStatus.idle,
        delegate = InferenceDelegateKind.unknown,
        labels = const [],
        isStreaming = false,
        averageLatencyMs = 0,
        processedFrames = 0,
        skippedFrames = 0;

  /// Copy helper.
  FloodDetectionSession copyWith({
    InferenceEngineStatus? status,
    InferenceDelegateKind? delegate,
    List<String>? labels,
    bool? isStreaming,
    double? averageLatencyMs,
    int? processedFrames,
    int? skippedFrames,
  }) {
    return FloodDetectionSession(
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
