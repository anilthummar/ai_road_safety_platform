import 'package:equatable/equatable.dart';

/// How predictions were obtained for offline scoring (Phase 13.4).
enum BenchmarkPredictionMode {
  /// Human boxes (`!fromAi`) as GT vs AI boxes (`fromAi`) as predictions.
  aiVsHuman,

  /// Synthetic predictions jittered from GT (demo / empty AI path).
  synthetic,

  /// Pre-baked demo report without session GT.
  demo,
}

extension BenchmarkPredictionModeX on BenchmarkPredictionMode {
  String get label => switch (this) {
        BenchmarkPredictionMode.aiVsHuman => 'AI vs human GT',
        BenchmarkPredictionMode.synthetic => 'Synthetic vs GT',
        BenchmarkPredictionMode.demo => 'Demo',
      };
}

/// Single detection used by the matcher (normalized box).
class BenchmarkDetection extends Equatable {
  final String id;
  final String labelId;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  const BenchmarkDetection({
    required this.id,
    required this.labelId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 1,
  });

  double get right => x + width;
  double get bottom => y + height;
  double get area => width * height;

  Map<String, dynamic> toJson() => {
        'id': id,
        'labelId': labelId,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'confidence': confidence,
      };

  factory BenchmarkDetection.fromJson(Map<String, dynamic> json) {
    return BenchmarkDetection(
      id: json['id'] as String? ?? '',
      labelId: json['labelId'] as String? ?? 'unknown',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  List<Object?> get props =>
      [id, labelId, x, y, width, height, confidence];
}

/// Per-class TP/FP/FN stats at a fixed IoU threshold.
class ClassBenchmarkMetrics extends Equatable {
  final String labelId;
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final double precision;
  final double recall;
  final double f1;
  final double meanIou;

  const ClassBenchmarkMetrics({
    required this.labelId,
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.meanIou,
  });

  Map<String, dynamic> toJson() => {
        'labelId': labelId,
        'truePositives': truePositives,
        'falsePositives': falsePositives,
        'falseNegatives': falseNegatives,
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'meanIou': meanIou,
      };

  factory ClassBenchmarkMetrics.fromJson(Map<String, dynamic> json) {
    return ClassBenchmarkMetrics(
      labelId: json['labelId'] as String? ?? '',
      truePositives: (json['truePositives'] as num?)?.toInt() ?? 0,
      falsePositives: (json['falsePositives'] as num?)?.toInt() ?? 0,
      falseNegatives: (json['falseNegatives'] as num?)?.toInt() ?? 0,
      precision: (json['precision'] as num?)?.toDouble() ?? 0,
      recall: (json['recall'] as num?)?.toDouble() ?? 0,
      f1: (json['f1'] as num?)?.toDouble() ?? 0,
      meanIou: (json['meanIou'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        labelId,
        truePositives,
        falsePositives,
        falseNegatives,
        precision,
        recall,
        f1,
        meanIou,
      ];
}

/// Aggregate offline detection metrics.
class BenchmarkMetrics extends Equatable {
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final double precision;
  final double recall;
  final double f1;
  final double meanIou;

  /// Macro-average of per-class F1 (proxy until full COCO mAP).
  final double mapProxy;

  const BenchmarkMetrics({
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.meanIou,
    required this.mapProxy,
  });

  const BenchmarkMetrics.empty()
      : truePositives = 0,
        falsePositives = 0,
        falseNegatives = 0,
        precision = 0,
        recall = 0,
        f1 = 0,
        meanIou = 0,
        mapProxy = 0;

  Map<String, dynamic> toJson() => {
        'truePositives': truePositives,
        'falsePositives': falsePositives,
        'falseNegatives': falseNegatives,
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'meanIou': meanIou,
        'mapProxy': mapProxy,
      };

  factory BenchmarkMetrics.fromJson(Map<String, dynamic> json) {
    return BenchmarkMetrics(
      truePositives: (json['truePositives'] as num?)?.toInt() ?? 0,
      falsePositives: (json['falsePositives'] as num?)?.toInt() ?? 0,
      falseNegatives: (json['falseNegatives'] as num?)?.toInt() ?? 0,
      precision: (json['precision'] as num?)?.toDouble() ?? 0,
      recall: (json['recall'] as num?)?.toDouble() ?? 0,
      f1: (json['f1'] as num?)?.toDouble() ?? 0,
      meanIou: (json['meanIou'] as num?)?.toDouble() ?? 0,
      mapProxy: (json['mapProxy'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        truePositives,
        falsePositives,
        falseNegatives,
        precision,
        recall,
        f1,
        meanIou,
        mapProxy,
      ];
}

/// Persisted offline benchmark report vs ground truth.
class BenchmarkReport extends Equatable {
  final String id;
  final String modelId;
  final String? modelVersion;
  final String? experimentRunId;
  final List<String> sessionIds;
  final double iouThreshold;
  final BenchmarkPredictionMode mode;
  final BenchmarkMetrics metrics;
  final List<ClassBenchmarkMetrics> perClass;
  final int framesScored;
  final int groundTruthBoxes;
  final int predictionBoxes;
  final String notes;
  final DateTime createdAt;

  const BenchmarkReport({
    required this.id,
    required this.modelId,
    required this.metrics,
    required this.createdAt,
    this.modelVersion,
    this.experimentRunId,
    this.sessionIds = const [],
    this.iouThreshold = 0.5,
    this.mode = BenchmarkPredictionMode.aiVsHuman,
    this.perClass = const [],
    this.framesScored = 0,
    this.groundTruthBoxes = 0,
    this.predictionBoxes = 0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelId': modelId,
        'modelVersion': modelVersion,
        'experimentRunId': experimentRunId,
        'sessionIds': sessionIds,
        'iouThreshold': iouThreshold,
        'mode': mode.name,
        'metrics': metrics.toJson(),
        'perClass': [for (final c in perClass) c.toJson()],
        'framesScored': framesScored,
        'groundTruthBoxes': groundTruthBoxes,
        'predictionBoxes': predictionBoxes,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory BenchmarkReport.fromJson(Map<String, dynamic> json) {
    return BenchmarkReport(
      id: json['id'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      modelVersion: json['modelVersion'] as String?,
      experimentRunId: json['experimentRunId'] as String?,
      sessionIds: [
        for (final id in (json['sessionIds'] as List? ?? const []))
          id.toString(),
      ],
      iouThreshold: (json['iouThreshold'] as num?)?.toDouble() ?? 0.5,
      mode: BenchmarkPredictionMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => BenchmarkPredictionMode.aiVsHuman,
      ),
      metrics: json['metrics'] is Map
          ? BenchmarkMetrics.fromJson(
              Map<String, dynamic>.from(json['metrics'] as Map),
            )
          : const BenchmarkMetrics.empty(),
      perClass: [
        for (final c in (json['perClass'] as List? ?? const []))
          ClassBenchmarkMetrics.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      framesScored: (json['framesScored'] as num?)?.toInt() ?? 0,
      groundTruthBoxes: (json['groundTruthBoxes'] as num?)?.toInt() ?? 0,
      predictionBoxes: (json['predictionBoxes'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [
        id,
        modelId,
        modelVersion,
        experimentRunId,
        sessionIds,
        iouThreshold,
        mode,
        metrics,
        perClass,
        framesScored,
        groundTruthBoxes,
        predictionBoxes,
        notes,
        createdAt,
      ];
}

/// Dashboard aggregate for saved benchmarks.
class BenchmarkSnapshot extends Equatable {
  final List<BenchmarkReport> reports;
  final DateTime generatedAt;

  const BenchmarkSnapshot({
    required this.reports,
    required this.generatedAt,
  });

  int get totalCount => reports.length;

  BenchmarkReport? get latest {
    if (reports.isEmpty) return null;
    final sorted = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  double get averageMapProxy {
    if (reports.isEmpty) return 0;
    final sum = reports.fold<double>(0, (a, r) => a + r.metrics.mapProxy);
    return sum / reports.length;
  }

  @override
  List<Object?> get props => [reports, generatedAt];
}
