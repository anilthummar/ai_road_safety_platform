import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';

/// Result of scoring one frame (or a GT/pred pair batch).
class FrameMatchResult {
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final List<double> matchedIous;
  final Map<String, int> tpByLabel;
  final Map<String, int> fpByLabel;
  final Map<String, int> fnByLabel;
  final Map<String, List<double>> iousByLabel;

  const FrameMatchResult({
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.matchedIous,
    required this.tpByLabel,
    required this.fpByLabel,
    required this.fnByLabel,
    required this.iousByLabel,
  });
}

/// Offline bounding-box scoring vs ground truth (Phase 13.4).
///
/// Uses greedy IoU matching at a fixed threshold (COCO-style simplified:
/// one-to-one matches, same-label required).
class ModelBenchmarkEngine {
  const ModelBenchmarkEngine();

  /// Intersection-over-union for normalized AABBs.
  double iou(BenchmarkDetection a, BenchmarkDetection b) {
    final x1 = a.x > b.x ? a.x : b.x;
    final y1 = a.y > b.y ? a.y : b.y;
    final x2 = a.right < b.right ? a.right : b.right;
    final y2 = a.bottom < b.bottom ? a.bottom : b.bottom;
    final iw = x2 - x1;
    final ih = y2 - y1;
    if (iw <= 0 || ih <= 0) return 0;
    final inter = iw * ih;
    final union = a.area + b.area - inter;
    if (union <= 0) return 0;
    return inter / union;
  }

  BenchmarkDetection? fromAnnotation(Annotation a) {
    final box = a.box;
    if (box == null || a.type != AnnotationType.boundingBox) return null;
    if (box.width <= 0 || box.height <= 0) return null;
    return BenchmarkDetection(
      id: a.id,
      labelId: a.labelId,
      x: box.x,
      y: box.y,
      width: box.width,
      height: box.height,
      confidence: a.aiConfidence ?? (a.fromAi ? 0.5 : 1),
    );
  }

  /// Human GT boxes vs AI prediction boxes on a [GroundTruth] frame.
  ({List<BenchmarkDetection> gt, List<BenchmarkDetection> pred})
      splitAiVsHuman(GroundTruth frame) {
    final gt = <BenchmarkDetection>[];
    final pred = <BenchmarkDetection>[];
    for (final a in frame.annotations) {
      final d = fromAnnotation(a);
      if (d == null) continue;
      if (a.fromAi) {
        pred.add(d);
      } else {
        gt.add(d);
      }
    }
    return (gt: gt, pred: pred);
  }

  /// Slightly shifted / scaled copies of [gt] for synthetic offline demo.
  List<BenchmarkDetection> synthesizePredictions(
    List<BenchmarkDetection> gt, {
    double shift = 0.02,
    double scale = 0.95,
  }) {
    return [
      for (var i = 0; i < gt.length; i++)
        BenchmarkDetection(
          id: 'syn-${gt[i].id}',
          labelId: gt[i].labelId,
          x: (gt[i].x + shift).clamp(0.0, 0.98),
          y: (gt[i].y + shift * 0.5).clamp(0.0, 0.98),
          width: (gt[i].width * scale).clamp(0.01, 1.0),
          height: (gt[i].height * scale).clamp(0.01, 1.0),
          confidence: 0.7,
        ),
    ];
  }

  FrameMatchResult matchFrame({
    required List<BenchmarkDetection> groundTruth,
    required List<BenchmarkDetection> predictions,
    double iouThreshold = 0.5,
    bool requireSameLabel = true,
  }) {
    final pairs = <({int gi, int pi, double iou})>[];
    for (var gi = 0; gi < groundTruth.length; gi++) {
      for (var pi = 0; pi < predictions.length; pi++) {
        if (requireSameLabel &&
            groundTruth[gi].labelId != predictions[pi].labelId) {
          continue;
        }
        final score = iou(groundTruth[gi], predictions[pi]);
        if (score >= iouThreshold) {
          pairs.add((gi: gi, pi: pi, iou: score));
        }
      }
    }
    pairs.sort((a, b) => b.iou.compareTo(a.iou));

    final usedGt = <int>{};
    final usedPred = <int>{};
    final matchedIous = <double>[];
    final tpByLabel = <String, int>{};
    final iousByLabel = <String, List<double>>{};

    for (final p in pairs) {
      if (usedGt.contains(p.gi) || usedPred.contains(p.pi)) continue;
      usedGt.add(p.gi);
      usedPred.add(p.pi);
      matchedIous.add(p.iou);
      final label = groundTruth[p.gi].labelId;
      tpByLabel[label] = (tpByLabel[label] ?? 0) + 1;
      (iousByLabel[label] ??= []).add(p.iou);
    }

    final fpByLabel = <String, int>{};
    for (var pi = 0; pi < predictions.length; pi++) {
      if (usedPred.contains(pi)) continue;
      final label = predictions[pi].labelId;
      fpByLabel[label] = (fpByLabel[label] ?? 0) + 1;
    }

    final fnByLabel = <String, int>{};
    for (var gi = 0; gi < groundTruth.length; gi++) {
      if (usedGt.contains(gi)) continue;
      final label = groundTruth[gi].labelId;
      fnByLabel[label] = (fnByLabel[label] ?? 0) + 1;
    }

    return FrameMatchResult(
      truePositives: usedGt.length,
      falsePositives: predictions.length - usedPred.length,
      falseNegatives: groundTruth.length - usedGt.length,
      matchedIous: matchedIous,
      tpByLabel: tpByLabel,
      fpByLabel: fpByLabel,
      fnByLabel: fnByLabel,
      iousByLabel: iousByLabel,
    );
  }

  ({BenchmarkMetrics metrics, List<ClassBenchmarkMetrics> perClass})
      aggregate(List<FrameMatchResult> frames) {
    var tp = 0;
    var fp = 0;
    var fn = 0;
    final allIous = <double>[];
    final tpBy = <String, int>{};
    final fpBy = <String, int>{};
    final fnBy = <String, int>{};
    final iouBy = <String, List<double>>{};

    for (final f in frames) {
      tp += f.truePositives;
      fp += f.falsePositives;
      fn += f.falseNegatives;
      allIous.addAll(f.matchedIous);
      f.tpByLabel.forEach((k, v) => tpBy[k] = (tpBy[k] ?? 0) + v);
      f.fpByLabel.forEach((k, v) => fpBy[k] = (fpBy[k] ?? 0) + v);
      f.fnByLabel.forEach((k, v) => fnBy[k] = (fnBy[k] ?? 0) + v);
      f.iousByLabel.forEach((k, v) => (iouBy[k] ??= []).addAll(v));
    }

    final labels = {...tpBy.keys, ...fpBy.keys, ...fnBy.keys};
    final perClass = <ClassBenchmarkMetrics>[];
    for (final label in labels) {
      final cTp = tpBy[label] ?? 0;
      final cFp = fpBy[label] ?? 0;
      final cFn = fnBy[label] ?? 0;
      final rates = _rates(cTp, cFp, cFn);
      final ious = iouBy[label] ?? const <double>[];
      perClass.add(
        ClassBenchmarkMetrics(
          labelId: label,
          truePositives: cTp,
          falsePositives: cFp,
          falseNegatives: cFn,
          precision: rates.precision,
          recall: rates.recall,
          f1: rates.f1,
          meanIou: ious.isEmpty
              ? 0
              : ious.reduce((a, b) => a + b) / ious.length,
        ),
      );
    }
    perClass.sort((a, b) => a.labelId.compareTo(b.labelId));

    final overall = _rates(tp, fp, fn);
    final mapProxy = perClass.isEmpty
        ? overall.f1
        : perClass.map((c) => c.f1).reduce((a, b) => a + b) / perClass.length;

    return (
      metrics: BenchmarkMetrics(
        truePositives: tp,
        falsePositives: fp,
        falseNegatives: fn,
        precision: overall.precision,
        recall: overall.recall,
        f1: overall.f1,
        meanIou: allIous.isEmpty
            ? 0
            : allIous.reduce((a, b) => a + b) / allIous.length,
        mapProxy: mapProxy,
      ),
      perClass: perClass,
    );
  }

  ({double precision, double recall, double f1}) _rates(
    int tp,
    int fp,
    int fn,
  ) {
    final precision = (tp + fp) == 0 ? 0.0 : tp / (tp + fp);
    final recall = (tp + fn) == 0 ? 0.0 : tp / (tp + fn);
    final f1 = (precision + recall) == 0
        ? 0.0
        : 2 * precision * recall / (precision + recall);
    return (precision: precision, recall: recall, f1: f1);
  }
}
