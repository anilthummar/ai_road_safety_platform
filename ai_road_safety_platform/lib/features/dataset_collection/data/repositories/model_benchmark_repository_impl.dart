import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_benchmark_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_benchmark_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_benchmark_engine.dart';
import 'package:uuid/uuid.dart';

class ModelBenchmarkRepositoryImpl implements ModelBenchmarkRepository {
  final ModelBenchmarkLocalDataSource _local;
  final ModelBenchmarkEngine _engine;
  final AnnotationRepository _annotations;
  final DatasetCollectionRepository _sessions;
  final ModelRegistryRepository _models;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  ModelBenchmarkRepositoryImpl({
    required ModelBenchmarkLocalDataSource localDataSource,
    required ModelBenchmarkEngine engine,
    required AnnotationRepository annotationRepository,
    required DatasetCollectionRepository collectionRepository,
    required ModelRegistryRepository modelRegistryRepository,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _local = localDataSource,
        _engine = engine,
        _annotations = annotationRepository,
        _sessions = collectionRepository,
        _models = modelRegistryRepository,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<BenchmarkSnapshot>> loadSnapshot() {
    return _guard(() async {
      final reports = await _local.loadReports();
      return BenchmarkSnapshot(
        reports: reports,
        generatedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<Result<BenchmarkReport>> getReport(String reportId) {
    return _guard(() async {
      final reports = await _local.loadReports();
      final match = reports.where((r) => r.id == reportId);
      if (match.isEmpty) {
        throw const CacheException(message: 'Benchmark report not found');
      }
      return match.first;
    });
  }

  @override
  Future<Result<BenchmarkReport>> runBenchmark({
    required String modelId,
    List<String> sessionIds = const [],
    String? experimentRunId,
    double iouThreshold = 0.5,
    String? modelVersion,
  }) {
    return _guard(() async {
      if (iouThreshold <= 0 || iouThreshold > 1) {
        throw const CacheException(
          message: 'IoU threshold must be in (0, 1]',
        );
      }

      final modelResult = await _models.getModel(modelId);
      final resolvedVersion = modelVersion ??
          modelResult.fold(
            onOk: (m) => m.version,
            onErr: (_) => null,
          );

      var ids = sessionIds.where((s) => s.trim().isNotEmpty).toList();
      if (ids.isEmpty) {
        final all = await _sessions.getSessions();
        ids = all.fold(
          onOk: (list) => list.map((s) => s.id).toList(),
          onErr: (f) => throw CacheException(message: f.message),
        );
      }
      if (ids.isEmpty) {
        throw const CacheException(
          message: 'No sessions available to benchmark',
        );
      }

      final frameResults = <FrameMatchResult>[];
      var framesScored = 0;
      var gtBoxes = 0;
      var predBoxes = 0;
      var usedSynthetic = false;
      var framesWithGt = 0;

      for (final sessionId in ids) {
        final gtResult =
            await _annotations.loadSessionGroundTruth(sessionId);
        final frames = gtResult.fold(
          onOk: (v) => v,
          onErr: (_) => const <GroundTruth>[],
        );
        for (final frame in frames) {
          final split = _engine.splitAiVsHuman(frame);
          final gt = split.gt;
          if (gt.isEmpty && split.pred.isEmpty) continue;
          framesWithGt++;
          if (gt.isEmpty) {
            // No human boxes — skip (cannot score vs GT).
            continue;
          }
          final usedSyn = split.pred.isEmpty;
          final pred = usedSyn
              ? _engine.synthesizePredictions(gt)
              : split.pred;
          if (usedSyn) usedSynthetic = true;
          framesScored++;
          gtBoxes += gt.length;
          predBoxes += pred.length;
          frameResults.add(
            _engine.matchFrame(
              groundTruth: gt,
              predictions: pred,
              iouThreshold: iouThreshold,
            ),
          );
        }
      }

      if (frameResults.isEmpty) {
        throw CacheException(
          message: framesWithGt == 0
              ? 'No annotated frames with boxes found'
              : 'No human ground-truth boxes to score against',
        );
      }

      final agg = _engine.aggregate(frameResults);
      final mode = usedSynthetic
          ? BenchmarkPredictionMode.synthetic
          : BenchmarkPredictionMode.aiVsHuman;

      final report = BenchmarkReport(
        id: _uuid.v4(),
        modelId: modelId,
        modelVersion: resolvedVersion,
        experimentRunId: experimentRunId,
        sessionIds: ids,
        iouThreshold: iouThreshold,
        mode: mode,
        metrics: agg.metrics,
        perClass: agg.perClass,
        framesScored: framesScored,
        groundTruthBoxes: gtBoxes,
        predictionBoxes: predBoxes,
        notes: usedSynthetic
            ? 'Some frames lacked AI boxes; synthetic preds used'
            : 'Scored AI (fromAi) vs human GT boxes',
        createdAt: DateTime.now().toUtc(),
      );

      final existing = await _local.loadReports();
      await _local.saveReports([report, ...existing]);
      _logger.info(
        'Benchmark ${report.id} mapProxy=${report.metrics.mapProxy.toStringAsFixed(3)} '
        'mode=${mode.name}',
        tag: 'Benchmark',
      );
      return report;
    });
  }

  @override
  Future<Result<void>> deleteReport(String reportId) {
    return _guard(() async {
      final reports = await _local.loadReports();
      if (!reports.any((r) => r.id == reportId)) {
        throw const CacheException(message: 'Benchmark report not found');
      }
      await _local.saveReports(
        reports.where((r) => r.id != reportId).toList(),
      );
      _logger.info('Benchmark deleted $reportId', tag: 'Benchmark');
    });
  }

  @override
  Future<Result<BenchmarkReport>> createDemoReport({
    String modelId = 'bundled-yolov8n',
    String? modelVersion,
    String? experimentRunId,
  }) {
    return _guard(() async {
      const iouThreshold = 0.5;
      final gt = [
        const BenchmarkDetection(
          id: 'gt1',
          labelId: 'pothole',
          x: 0.1,
          y: 0.2,
          width: 0.25,
          height: 0.2,
        ),
        const BenchmarkDetection(
          id: 'gt2',
          labelId: 'flooded_road',
          x: 0.5,
          y: 0.4,
          width: 0.3,
          height: 0.25,
        ),
        const BenchmarkDetection(
          id: 'gt3',
          labelId: 'obstacle',
          x: 0.2,
          y: 0.6,
          width: 0.15,
          height: 0.15,
        ),
      ];
      final pred = [
        ..._engine.synthesizePredictions(gt.take(2).toList()),
        const BenchmarkDetection(
          id: 'fp1',
          labelId: 'crack',
          x: 0.7,
          y: 0.1,
          width: 0.1,
          height: 0.1,
          confidence: 0.4,
        ),
      ];
      final match = _engine.matchFrame(
        groundTruth: gt,
        predictions: pred,
        iouThreshold: iouThreshold,
      );
      final agg = _engine.aggregate([match]);
      final report = BenchmarkReport(
        id: _uuid.v4(),
        modelId: modelId,
        modelVersion: modelVersion ?? '1.0.0',
        experimentRunId: experimentRunId,
        sessionIds: const ['demo-session'],
        iouThreshold: iouThreshold,
        mode: BenchmarkPredictionMode.demo,
        metrics: agg.metrics,
        perClass: agg.perClass,
        framesScored: 1,
        groundTruthBoxes: gt.length,
        predictionBoxes: pred.length,
        notes: 'Demo offline scoring vs synthetic GT',
        createdAt: DateTime.now().toUtc(),
      );
      final existing = await _local.loadReports();
      await _local.saveReports([report, ...existing]);
      _logger.info('Demo benchmark ${report.id}', tag: 'Benchmark');
      return report;
    });
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
