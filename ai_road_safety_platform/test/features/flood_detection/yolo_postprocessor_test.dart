import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/flood_detection/data/processors/yolo_postprocessor.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/processors/yolo_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labels = ['flooded_road', 'person', 'car'];

  final preprocess = PreprocessOutput(
    input: Float32List(1),
    gain: 1,
    padX: 0,
    padY: 0,
    sourceWidth: 640,
    sourceHeight: 640,
  );

  test('filters low-confidence boxes', () {
    const post = YoloPostprocessor(
      labels: labels,
      confidenceThreshold: 0.5,
      iouThreshold: 0.5,
    );

    final output = [
      [
        [320.0, 320.0, 100.0, 100.0, 0.9, 0.1, 0.05],
        [320.0, 320.0, 100.0, 100.0, 0.2, 0.1, 0.05],
      ],
    ];

    final detections = post.process(output: output, preprocess: preprocess);
    expect(detections.length, 1);
    expect(detections.first.label, 'flooded_road');
    expect(detections.first.confidence, greaterThan(0.5));
  });

  test('applies NMS for overlapping same-class boxes', () {
    const post = YoloPostprocessor(
      labels: labels,
      confidenceThreshold: 0.4,
      iouThreshold: 0.5,
    );

    final output = [
      [
        [320.0, 320.0, 120.0, 120.0, 0.95, 0.0, 0.0],
        [325.0, 325.0, 120.0, 120.0, 0.90, 0.0, 0.0],
      ],
    ];

    final detections = post.process(output: output, preprocess: preprocess);
    expect(detections.length, 1);
  });
}
