import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_benchmark_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ModelBenchmarkEngine();

  test('iou is 1 for identical boxes', () {
    const a = BenchmarkDetection(
      id: 'a',
      labelId: 'pothole',
      x: 0.1,
      y: 0.1,
      width: 0.2,
      height: 0.2,
    );
    expect(engine.iou(a, a), closeTo(1, 1e-9));
  });

  test('iou is 0 for non-overlapping boxes', () {
    const a = BenchmarkDetection(
      id: 'a',
      labelId: 'pothole',
      x: 0,
      y: 0,
      width: 0.1,
      height: 0.1,
    );
    const b = BenchmarkDetection(
      id: 'b',
      labelId: 'pothole',
      x: 0.5,
      y: 0.5,
      width: 0.1,
      height: 0.1,
    );
    expect(engine.iou(a, b), 0);
  });

  test('greedy match counts TP FP FN at IoU threshold', () {
    const gt = [
      BenchmarkDetection(
        id: 'g1',
        labelId: 'pothole',
        x: 0.1,
        y: 0.1,
        width: 0.2,
        height: 0.2,
      ),
      BenchmarkDetection(
        id: 'g2',
        labelId: 'obstacle',
        x: 0.6,
        y: 0.6,
        width: 0.2,
        height: 0.2,
      ),
    ];
    const pred = [
      BenchmarkDetection(
        id: 'p1',
        labelId: 'pothole',
        x: 0.12,
        y: 0.12,
        width: 0.18,
        height: 0.18,
        confidence: 0.9,
      ),
      BenchmarkDetection(
        id: 'fp',
        labelId: 'crack',
        x: 0.4,
        y: 0.1,
        width: 0.1,
        height: 0.1,
      ),
    ];
    final match = engine.matchFrame(
      groundTruth: gt,
      predictions: pred,
      iouThreshold: 0.5,
    );
    expect(match.truePositives, 1);
    expect(match.falsePositives, 1);
    expect(match.falseNegatives, 1);

    final agg = engine.aggregate([match]);
    expect(agg.metrics.precision, closeTo(0.5, 1e-9));
    expect(agg.metrics.recall, closeTo(0.5, 1e-9));
    expect(agg.perClass.any((c) => c.labelId == 'pothole'), isTrue);
  });

  test('requireSameLabel blocks cross-class matches', () {
    const gt = [
      BenchmarkDetection(
        id: 'g1',
        labelId: 'pothole',
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      ),
    ];
    const pred = [
      BenchmarkDetection(
        id: 'p1',
        labelId: 'obstacle',
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      ),
    ];
    final match = engine.matchFrame(
      groundTruth: gt,
      predictions: pred,
      iouThreshold: 0.5,
    );
    expect(match.truePositives, 0);
    expect(match.falsePositives, 1);
    expect(match.falseNegatives, 1);
  });

  test('BenchmarkReport json round-trip', () {
    final report = BenchmarkReport(
      id: 'b1',
      modelId: 'bundled-yolov8n',
      createdAt: DateTime.utc(2026, 7, 14),
      metrics: const BenchmarkMetrics(
        truePositives: 2,
        falsePositives: 1,
        falseNegatives: 1,
        precision: 0.666,
        recall: 0.666,
        f1: 0.666,
        meanIou: 0.7,
        mapProxy: 0.5,
      ),
      perClass: const [
        ClassBenchmarkMetrics(
          labelId: 'pothole',
          truePositives: 2,
          falsePositives: 0,
          falseNegatives: 0,
          precision: 1,
          recall: 1,
          f1: 1,
          meanIou: 0.8,
        ),
      ],
    );
    expect(BenchmarkReport.fromJson(report.toJson()), report);
  });
}
