import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';

/// Offline model benchmark reports vs ground truth (Phase 13.4).
abstract class ModelBenchmarkRepository {
  Future<Result<BenchmarkSnapshot>> loadSnapshot();

  Future<Result<BenchmarkReport>> getReport(String reportId);

  /// Score AI (`fromAi`) boxes vs human GT for [sessionIds], persist report.
  ///
  /// When a session has GT boxes but no AI predictions, synthesizes preds
  /// from GT so offline eval still produces a report.
  Future<Result<BenchmarkReport>> runBenchmark({
    required String modelId,
    List<String> sessionIds = const [],
    String? experimentRunId,
    double iouThreshold = 0.5,
    String? modelVersion,
  });

  Future<Result<void>> deleteReport(String reportId);

  Future<Result<BenchmarkReport>> createDemoReport({
    String modelId = 'bundled-yolov8n',
    String? modelVersion,
    String? experimentRunId,
  });
}
