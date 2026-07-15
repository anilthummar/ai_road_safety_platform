import 'dart:math' as math;

import 'package:ai_road_safety_platform/features/flood_detection/data/processors/yolo_preprocessor.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/inference_config.dart';

/// Decodes YOLOv8 TFLite output tensors with confidence filtering + NMS.
///
/// Supports common Ultralytics export layouts:
/// - `[1, 4 + nc, numAnchors]` (channels-first scores)
/// - `[1, numAnchors, 4 + nc]` (channels-last)
class YoloPostprocessor {
  /// Class label list aligned with training indices.
  final List<String> labels;

  /// Confidence gate.
  final double confidenceThreshold;

  /// NMS IoU gate.
  final double iouThreshold;

  /// Max boxes after NMS.
  final int maxDetections;

  /// Creates a [YoloPostprocessor].
  const YoloPostprocessor({
    required this.labels,
    this.confidenceThreshold = InferenceConfig.confidenceThreshold,
    this.iouThreshold = InferenceConfig.iouThreshold,
    this.maxDetections = InferenceConfig.maxDetections,
  });

  /// Parses raw model output into preview-normalized [Detection]s.
  List<Detection> process({
    required List<List<List<double>>> output,
    required PreprocessOutput preprocess,
  }) {
    if (output.isEmpty || output.first.isEmpty) return const [];

    final batch = output.first;
    final candidates = <_Candidate>[];

    // Channels-first: [4+nc][anchors]
    if (batch.length == 4 + labels.length ||
        (batch.isNotEmpty &&
            batch.length < batch.first.length &&
            batch.length >= 5)) {
      candidates.addAll(_decodeChannelsFirst(batch, preprocess));
    } else {
      // Channels-last: [anchors][4+nc]
      candidates.addAll(_decodeChannelsLast(batch, preprocess));
    }

    final kept = _nms(candidates);
    return kept
        .take(maxDetections)
        .map(
          (c) => Detection(
            classIndex: c.classIndex,
            label: c.classIndex >= 0 && c.classIndex < labels.length
                ? labels[c.classIndex]
                : 'class_${c.classIndex}',
            confidence: c.score,
            box: c.box,
          ),
        )
        .toList(growable: false);
  }

  /// Convenience when the interpreter returns a flat buffer + shape.
  List<Detection> processShaped({
    required List<double> flat,
    required List<int> shape,
    required PreprocessOutput preprocess,
  }) {
    final nested = _reshape(flat, shape);
    return process(output: nested, preprocess: preprocess);
  }

  List<_Candidate> _decodeChannelsFirst(
    List<List<double>> channels,
    PreprocessOutput preprocess,
  ) {
    final numAnchors = channels.first.length;
    final numClasses = channels.length - 4;
    final out = <_Candidate>[];

    for (var i = 0; i < numAnchors; i++) {
      var bestScore = 0.0;
      var bestClass = -1;
      for (var c = 0; c < numClasses; c++) {
        final score = channels[4 + c][i];
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }
      if (bestScore < confidenceThreshold || bestClass < 0) continue;

      final cx = channels[0][i];
      final cy = channels[1][i];
      final w = channels[2][i];
      final h = channels[3][i];
      final box = _toPreviewBox(
        cx: cx,
        cy: cy,
        w: w,
        h: h,
        preprocess: preprocess,
      );
      out.add(_Candidate(classIndex: bestClass, score: bestScore, box: box));
    }
    return out;
  }

  List<_Candidate> _decodeChannelsLast(
    List<List<double>> anchors,
    PreprocessOutput preprocess,
  ) {
    final out = <_Candidate>[];
    for (final row in anchors) {
      if (row.length < 5) continue;
      final cx = row[0];
      final cy = row[1];
      final w = row[2];
      final h = row[3];

      var bestScore = 0.0;
      var bestClass = -1;
      for (var c = 4; c < row.length; c++) {
        final score = row[c];
        if (score > bestScore) {
          bestScore = score;
          bestClass = c - 4;
        }
      }
      if (bestScore < confidenceThreshold || bestClass < 0) continue;

      final box = _toPreviewBox(
        cx: cx,
        cy: cy,
        w: w,
        h: h,
        preprocess: preprocess,
      );
      out.add(_Candidate(classIndex: bestClass, score: bestScore, box: box));
    }
    return out;
  }

  DetectionBox _toPreviewBox({
    required double cx,
    required double cy,
    required double w,
    required double h,
    required PreprocessOutput preprocess,
  }) {
    // Ultralytics export is typically absolute pixels in letterbox space.
    final inputSize = InferenceConfig.inputSize.toDouble();
    final isNormalized = cx <= 1.5 && cy <= 1.5 && w <= 1.5 && h <= 1.5;

    final absCx = isNormalized ? cx * inputSize : cx;
    final absCy = isNormalized ? cy * inputSize : cy;
    final absW = isNormalized ? w * inputSize : w;
    final absH = isNormalized ? h * inputSize : h;

    var x1 = absCx - absW / 2.0;
    var y1 = absCy - absH / 2.0;
    var x2 = absCx + absW / 2.0;
    var y2 = absCy + absH / 2.0;

    // Undo letterbox padding + gain → source pixels → normalize 0–1.
    x1 = (x1 - preprocess.padX) / preprocess.gain;
    y1 = (y1 - preprocess.padY) / preprocess.gain;
    x2 = (x2 - preprocess.padX) / preprocess.gain;
    y2 = (y2 - preprocess.padY) / preprocess.gain;

    final sw = preprocess.sourceWidth.toDouble();
    final sh = preprocess.sourceHeight.toDouble();

    return DetectionBox(
      left: (x1 / sw).clamp(0.0, 1.0),
      top: (y1 / sh).clamp(0.0, 1.0),
      right: (x2 / sw).clamp(0.0, 1.0),
      bottom: (y2 / sh).clamp(0.0, 1.0),
    );
  }

  List<_Candidate> _nms(List<_Candidate> boxes) {
    boxes.sort((a, b) => b.score.compareTo(a.score));
    final selected = <_Candidate>[];

    final used = List<bool>.filled(boxes.length, false);
    for (var i = 0; i < boxes.length; i++) {
      if (used[i]) continue;
      final a = boxes[i];
      selected.add(a);
      for (var j = i + 1; j < boxes.length; j++) {
        if (used[j]) continue;
        final b = boxes[j];
        if (a.classIndex != b.classIndex) continue;
        if (_iou(a.box, b.box) >= iouThreshold) {
          used[j] = true;
        }
      }
    }
    return selected;
  }

  double _iou(DetectionBox a, DetectionBox b) {
    final x1 = math.max(a.left, b.left);
    final y1 = math.max(a.top, b.top);
    final x2 = math.min(a.right, b.right);
    final y2 = math.min(a.bottom, b.bottom);
    final inter = math.max(0.0, x2 - x1) * math.max(0.0, y2 - y1);
    final union = a.width * a.height + b.width * b.height - inter;
    if (union <= 0) return 0;
    return inter / union;
  }

  List<List<List<double>>> _reshape(List<double> flat, List<int> shape) {
    // Expect [1, A, B]
    if (shape.length == 3) {
      final a = shape[1];
      final b = shape[2];
      final out = List.generate(
        a,
        (i) => List<double>.generate(b, (j) => flat[i * b + j]),
      );
      return [out];
    }
    if (shape.length == 2) {
      final a = shape[0];
      final b = shape[1];
      final out = List.generate(
        a,
        (i) => List<double>.generate(b, (j) => flat[i * b + j]),
      );
      return [out];
    }
    return const [];
  }
}

class _Candidate {
  final int classIndex;
  final double score;
  final DetectionBox box;

  const _Candidate({
    required this.classIndex,
    required this.score,
    required this.box,
  });
}
