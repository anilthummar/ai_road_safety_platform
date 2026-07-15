import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_detection_config.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';

/// Decodes segmentation TFLite outputs into class masks + coverage stats.
///
/// Supports:
/// - NHWC logits `[1, H, W, C]` or `[H, W, C]`
/// - NCHW logits `[1, C, H, W]`
/// - Class-index map `[1, H, W]` / `[H, W]`
class SegmentationPostprocessor {
  /// Labels in class-index order.
  final List<String> labels;

  /// Creates [SegmentationPostprocessor].
  const SegmentationPostprocessor({required this.labels});

  /// Parses flattened output + shape into a [FloodSegmentationResult] shell
  /// (caller fills frameSequence / duration / delegate).
  ({
    int width,
    int height,
    List<int> classIndices,
    List<double> confidences,
    FloodCoverageStats stats,
  }) process({
    required List<double> flat,
    required List<int> shape,
  }) {
    final parsed = _parseShape(shape);
    final height = parsed.height;
    final width = parsed.width;
    final channels = parsed.channels;
    final isNchw = parsed.isNchw;
    final isIndexMap = channels <= 1;

    final classIndices = List<int>.filled(height * width, 0);
    final confidences = List<double>.filled(height * width, 0);

    if (isIndexMap) {
      for (var i = 0; i < classIndices.length && i < flat.length; i++) {
        final idx = flat[i].round().clamp(0, math.max(0, labels.length - 1)).toInt();
        classIndices[i] = idx;
        confidences[i] = 1.0;
      }
    } else {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          var bestClass = 0;
          var bestScore = -double.infinity;
          var sumExp = 0.0;
          final scores = List<double>.filled(channels, 0);

          for (var c = 0; c < channels; c++) {
            final index = isNchw
                ? c * height * width + y * width + x
                : (y * width + x) * channels + c;
            final value = index < flat.length ? flat[index] : 0.0;
            scores[c] = value;
            if (value > bestScore) {
              bestScore = value;
              bestClass = c;
            }
          }

          // Softmax for calibrated confidence.
          final maxLogit = bestScore;
          for (var c = 0; c < channels; c++) {
            sumExp += math.exp(scores[c] - maxLogit);
          }
          final conf = sumExp <= 0 ? 0.0 : 1.0 / sumExp;
          // Actually softmax of best = exp(0)/sumExp = 1/sumExp only if we
          // subtracted max from best which is 0 → exp(0)=1. Correct.
          final pixel = y * width + x;
          classIndices[pixel] = bestClass.clamp(0, math.max(0, labels.length - 1));
          confidences[pixel] = conf.clamp(0.0, 1.0);
        }
      }
    }

    final stats = _computeStats(classIndices, confidences);
    return (
      width: width,
      height: height,
      classIndices: classIndices,
      confidences: confidences,
      stats: stats,
    );
  }

  /// Builds an RGBA overlay buffer for [CustomPainter] / [ui.Image].
  Uint8List buildRgbaOverlay({
    required List<int> classIndices,
    required int width,
    required int height,
    int alpha = FloodDetectionConfig.overlayAlpha,
  }) {
    final rgba = Uint8List(width * height * 4);
    for (var i = 0; i < classIndices.length; i++) {
      final cls = _toSegmentClass(classIndices[i]);
      final color = _colorFor(cls);
      final o = i * 4;
      if (cls == FloodSegmentClass.background) {
        rgba[o] = 0;
        rgba[o + 1] = 0;
        rgba[o + 2] = 0;
        rgba[o + 3] = 0;
      } else {
        rgba[o] = color.$1;
        rgba[o + 1] = color.$2;
        rgba[o + 2] = color.$3;
        rgba[o + 3] = alpha;
      }
    }
    return rgba;
  }

  FloodCoverageStats _computeStats(
    List<int> classIndices,
    List<double> confidences,
  ) {
    if (classIndices.isEmpty) return const FloodCoverageStats.zero();

    var road = 0;
    var water = 0;
    var vehicle = 0;
    var obstacle = 0;
    var background = 0;
    var confSum = 0.0;

    for (var i = 0; i < classIndices.length; i++) {
      final cls = _toSegmentClass(classIndices[i]);
      switch (cls) {
        case FloodSegmentClass.road:
          road++;
        case FloodSegmentClass.water:
          water++;
        case FloodSegmentClass.vehicle:
          vehicle++;
        case FloodSegmentClass.obstacle:
          obstacle++;
        case FloodSegmentClass.background:
          background++;
      }
      confSum += confidences.isNotEmpty ? confidences[i] : 0;
    }

    final total = classIndices.length.toDouble();
    final meanConf = confSum / total;

    return FloodCoverageStats(
      waterCoveragePercent: water / total * 100,
      roadCoveragePercent: road / total * 100,
      vehicleCoveragePercent: vehicle / total * 100,
      obstacleCoveragePercent: obstacle / total * 100,
      backgroundCoveragePercent: background / total * 100,
      meanConfidence: meanConf.clamp(0.0, 1.0),
    );
  }

  FloodSegmentClass _toSegmentClass(int index) {
    if (index < 0 || index >= labels.length) {
      return FloodSegmentClass.background;
    }
    return FloodSegmentClassX.fromLabel(labels[index]);
  }

  (int r, int g, int b) _colorFor(FloodSegmentClass cls) {
    return switch (cls) {
      FloodSegmentClass.road => (80, 80, 90),
      FloodSegmentClass.water => (20, 120, 220),
      FloodSegmentClass.vehicle => (8, 164, 189),
      FloodSegmentClass.obstacle => (193, 18, 31),
      FloodSegmentClass.background => (0, 0, 0),
    };
  }

  ({int height, int width, int channels, bool isNchw}) _parseShape(
    List<int> shape,
  ) {
    // [1, H, W, C] NHWC logits (preferred for TFLite Keras exports)
    if (shape.length == 4 && shape[0] == 1 && shape[3] <= 64) {
      return (
        height: shape[1],
        width: shape[2],
        channels: shape[3],
        isNchw: false,
      );
    }
    // [1, C, H, W] NCHW logits
    if (shape.length == 4 && shape[0] == 1 && shape[1] <= 64) {
      return (
        height: shape[2],
        width: shape[3],
        channels: shape[1],
        isNchw: true,
      );
    }
    // [1, H, W] class-index map
    if (shape.length == 3 && shape[0] == 1) {
      return (
        height: shape[1],
        width: shape[2],
        channels: 1,
        isNchw: false,
      );
    }
    // [H, W, C]
    if (shape.length == 3) {
      return (
        height: shape[0],
        width: shape[1],
        channels: shape[2],
        isNchw: false,
      );
    }
    // [H, W]
    if (shape.length == 2) {
      return (
        height: shape[0],
        width: shape[1],
        channels: 1,
        isNchw: false,
      );
    }

    final size = FloodDetectionConfig.inputSize;
    return (height: size, width: size, channels: labels.length, isNchw: false);
  }
}
