import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_quality_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_analytics_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_quality_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_quality_assessment_engine.dart';

/// Aggregates 12.7/12.9 signals into a training quality gate.
class DatasetQualityRepositoryImpl implements DatasetQualityRepository {
  final DatasetCollectionRepository _collection;
  final DatasetStorageRepository _storage;
  final DatasetAnalyticsRepository _analytics;
  final AnnotationRepository _annotations;
  final LabelRepository _labels;
  final DatasetQualityAssessmentEngine _engine;
  final DatasetQualityLocalDataSource _local;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;

  DatasetQualityRepositoryImpl({
    required DatasetCollectionRepository collectionRepository,
    required DatasetStorageRepository storageRepository,
    required DatasetAnalyticsRepository analyticsRepository,
    required AnnotationRepository annotationRepository,
    required LabelRepository labelRepository,
    required DatasetQualityAssessmentEngine engine,
    required DatasetQualityLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
    required AppLogger logger,
  })  : _collection = collectionRepository,
        _storage = storageRepository,
        _analytics = analyticsRepository,
        _annotations = annotationRepository,
        _labels = labelRepository,
        _engine = engine,
        _local = localDataSource,
        _errorHandler = errorHandler,
        _logger = logger;

  @override
  Future<Result<DatasetQualityAssessmentReport>> assessDataset({
    QualityGateThresholds thresholds = QualityGateThresholds.defaults,
    String? sessionId,
  }) {
    return _guard(() async {
      _logger.info('Quality assessment started', tag: 'DatasetQuality');
      final sessionsResult = await _collection.getSessions();
      final sessions = sessionsResult.fold(
        onOk: (v) => v,
        onErr: (f) => throw CacheException(message: f.message),
      );
      final scoped = sessionId == null || sessionId.isEmpty
          ? sessions
          : sessions.where((s) => s.id == sessionId).toList();

      final recovery = await _storage.recoverSession();
      final recoveryList = recovery.fold(
        onOk: (v) => v,
        onErr: (_) => const <SessionRecoveryInfo>[],
      );
      final recoveryById = {
        for (final r in recoveryList) r.sessionId: r,
      };

      final labelsResult = await _labels.getLabels();
      final labels = labelsResult.fold(
        onOk: (v) => v,
        onErr: (_) => DefaultHazardLabels.all,
      );

      final analyticsResult = await _analytics.loadAnalytics();
      final captureMetrics = analyticsResult.fold(
        onOk: (r) => r.quality,
        onErr: (_) => const DatasetQualityMetrics.empty(),
      );

      final inputs = <QualitySessionInput>[];
      for (final session in scoped) {
        inputs.add(await _buildInput(session, recoveryById[session.id]));
      }

      final report = _engine.assess(
        sessions: inputs,
        labels: labels,
        captureMetrics: captureMetrics,
        thresholds: thresholds,
      );
      await _local.saveReport(report);
      _logger.info(
        'Quality assessment done decision=${report.decision.name} '
        'score=${report.overallScore.toStringAsFixed(1)}',
        tag: 'DatasetQuality',
      );
      return report;
    });
  }

  Future<QualitySessionInput> _buildInput(
    DatasetSession session,
    SessionRecoveryInfo? recovery,
  ) async {
    final framesResult = await _annotations.listFrames(session.id);
    final frames = framesResult.fold(
      onOk: (v) => v,
      onErr: (_) => const <AnnotatableFrame>[],
    );
    final annMetricsResult = await _annotations.qualityMetrics(session.id);
    final annMetrics = annMetricsResult.fold(
      onOk: (v) => v,
      onErr: (_) => const AnnotationQualityMetrics.empty(),
    );

    final labelCounts = <String, int>{};
    var missingLabels = annMetrics.missingLabelCount;
    for (final f in frames) {
      if (f.annotationCount == 0) continue;
      final gt = await _annotations.getGroundTruth(
        sessionId: session.id,
        frameNumber: f.frameNumber,
      );
      gt.fold(
        onOk: (g) {
          for (final a in g.annotations) {
            if (a.labelId.isEmpty) {
              missingLabels++;
            } else {
              labelCounts[a.labelId] = (labelCounts[a.labelId] ?? 0) + 1;
            }
          }
        },
        onErr: (_) {},
      );
    }

    final imageCount = recovery?.imageCount ??
        frames.where((f) => f.imagePath != null).length;
    final metadataCount = recovery?.metadataCount ?? frames.length;

    return QualitySessionInput(
      sessionId: session.id,
      sessionName: session.sessionName,
      frameCount: session.frameCount > 0
          ? session.frameCount
          : (frames.isNotEmpty ? frames.length : imageCount),
      imageCount: imageCount,
      metadataCount: metadataCount,
      annotatedFrames: annMetrics.annotatedFrames > 0
          ? annMetrics.annotatedFrames
          : frames.where((f) => f.annotationCount > 0).length,
      approvedFrames: annMetrics.approvedFrames,
      missingLabelCount: missingLabels,
      labelCounts: labelCounts,
    );
  }

  @override
  Future<Result<QualityGateDecision>> evaluateGate({
    required DatasetQualityAssessmentReport report,
    QualityGateThresholds? thresholds,
  }) {
    return _guard(() async {
      return _engine.evaluateGate(report, thresholds: thresholds);
    });
  }

  @override
  Future<Result<DatasetQualityAssessmentReport?>> loadLastReport() {
    return _guard(_local.loadLastReport);
  }

  @override
  Future<Result<void>> saveReport(DatasetQualityAssessmentReport report) {
    return _guard(() => _local.saveReport(report));
  }

  @override
  Future<Result<QualityGateThresholds>> getThresholds() {
    return _guard(_local.loadThresholds);
  }

  @override
  Future<Result<QualityGateThresholds>> updateThresholds(
    QualityGateThresholds thresholds,
  ) {
    return _guard(() async {
      await _local.saveThresholds(thresholds);
      return thresholds;
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
