import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/experiment_tracking_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/experiment_tracking_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/experiment_tracking_validator.dart';
import 'package:uuid/uuid.dart';

class ExperimentTrackingRepositoryImpl implements ExperimentTrackingRepository {
  final ExperimentTrackingLocalDataSource _local;
  final ExperimentTrackingValidator _validator;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  ExperimentTrackingRepositoryImpl({
    required ExperimentTrackingLocalDataSource localDataSource,
    required ExperimentTrackingValidator validator,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _local = localDataSource,
        _validator = validator,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<ExperimentTrackerSnapshot>> loadTracker() {
    return _guard(() async {
      final runs = await _local.loadRuns();
      return ExperimentTrackerSnapshot(
        runs: runs,
        generatedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<Result<ExperimentRun>> getRun(String runId) {
    return _guard(() async => _requireRun(await _local.loadRuns(), runId));
  }

  @override
  Future<Result<ExperimentRun>> createRun({
    required String name,
    String experimentName = 'default',
    String? modelId,
    String? modelVersion,
    List<String> datasetSessionIds = const [],
    Map<String, String> params = const {},
    Map<String, String> tags = const {},
    String notes = '',
    ExperimentRunSource source = ExperimentRunSource.manual,
  }) {
    return _guard(() async {
      final now = DateTime.now().toUtc();
      final run = ExperimentRun(
        id: _uuid.v4(),
        name: name.trim(),
        experimentName: experimentName.trim().isEmpty
            ? 'default'
            : experimentName.trim(),
        status: ExperimentRunStatus.draft,
        source: source,
        modelId: modelId,
        modelVersion: modelVersion,
        datasetSessionIds: datasetSessionIds,
        params: params,
        tags: tags,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );
      final issues = _validator.validateRun(run);
      if (issues.isNotEmpty) {
        throw CacheException(message: issues.first.message);
      }
      final runs = await _local.loadRuns();
      await _local.saveRuns([...runs, run]);
      _logger.info('Experiment run created ${run.id}', tag: 'Experiments');
      return run;
    });
  }

  @override
  Future<Result<ExperimentRun>> startRun(String runId) {
    return _guard(() async {
      final runs = await _local.loadRuns();
      final idx = _indexOf(runs, runId);
      final current = runs[idx];
      if (current.status == ExperimentRunStatus.completed ||
          current.status == ExperimentRunStatus.cancelled) {
        throw const CacheException(
          message: 'Cannot start a completed or cancelled run',
        );
      }
      final now = DateTime.now().toUtc();
      final updated = current.copyWith(
        status: ExperimentRunStatus.running,
        startedAt: current.startedAt ?? now,
        updatedAt: now,
        clearEndedAt: true,
      );
      final next = [...runs]..[idx] = updated;
      await _local.saveRuns(next);
      _logger.info('Experiment run started $runId', tag: 'Experiments');
      return updated;
    });
  }

  @override
  Future<Result<ExperimentRun>> logParams({
    required String runId,
    required Map<String, String> params,
  }) {
    return _guard(() async {
      final paramIssues = _validator.validateParams(params);
      if (paramIssues.isNotEmpty) {
        throw CacheException(message: paramIssues.first.message);
      }
      final runs = await _local.loadRuns();
      final idx = _indexOf(runs, runId);
      final current = runs[idx];
      if (current.status == ExperimentRunStatus.completed ||
          current.status == ExperimentRunStatus.cancelled) {
        throw const CacheException(
          message: 'Cannot log params on a finished run',
        );
      }
      final merged = {...current.params, ...params};
      final updated = current.copyWith(
        params: merged,
        updatedAt: DateTime.now().toUtc(),
      );
      final next = [...runs]..[idx] = updated;
      await _local.saveRuns(next);
      return updated;
    });
  }

  @override
  Future<Result<ExperimentRun>> logMetric({
    required String runId,
    required String key,
    required double value,
    int step = 0,
  }) {
    return _guard(() async {
      final metricIssues =
          _validator.validateMetric(key: key, value: value);
      if (metricIssues.isNotEmpty) {
        throw CacheException(message: metricIssues.first.message);
      }
      final runs = await _local.loadRuns();
      final idx = _indexOf(runs, runId);
      final current = runs[idx];
      if (current.status == ExperimentRunStatus.draft) {
        throw const CacheException(
          message: 'Start the run before logging metrics',
        );
      }
      if (current.status == ExperimentRunStatus.cancelled) {
        throw const CacheException(
          message: 'Cannot log metrics on a cancelled run',
        );
      }
      final now = DateTime.now().toUtc();
      final point = ExperimentMetricPoint(
        key: key.trim(),
        value: value,
        step: step,
        recordedAt: now,
      );
      final metrics = {...current.metrics, point.key: value};
      final updated = current.copyWith(
        metrics: metrics,
        metricHistory: [...current.metricHistory, point],
        updatedAt: now,
        status: current.status == ExperimentRunStatus.completed
            ? ExperimentRunStatus.completed
            : ExperimentRunStatus.running,
      );
      final next = [...runs]..[idx] = updated;
      await _local.saveRuns(next);
      return updated;
    });
  }

  @override
  Future<Result<ExperimentRun>> completeRun(String runId) {
    return _guard(() async {
      final runs = await _local.loadRuns();
      final idx = _indexOf(runs, runId);
      final current = runs[idx];
      if (current.status == ExperimentRunStatus.cancelled) {
        throw const CacheException(message: 'Cannot complete a cancelled run');
      }
      final now = DateTime.now().toUtc();
      final updated = current.copyWith(
        status: ExperimentRunStatus.completed,
        startedAt: current.startedAt ?? now,
        endedAt: now,
        updatedAt: now,
      );
      final next = [...runs]..[idx] = updated;
      await _local.saveRuns(next);
      _logger.info('Experiment run completed $runId', tag: 'Experiments');
      return updated;
    });
  }

  @override
  Future<Result<ExperimentRun>> failRun(String runId, {String? notes}) {
    return _guard(() async {
      final runs = await _local.loadRuns();
      final idx = _indexOf(runs, runId);
      final current = runs[idx];
      final now = DateTime.now().toUtc();
      final updated = current.copyWith(
        status: ExperimentRunStatus.failed,
        startedAt: current.startedAt ?? now,
        endedAt: now,
        updatedAt: now,
        notes: notes == null || notes.isEmpty
            ? current.notes
            : (current.notes.isEmpty ? notes : '${current.notes}\n$notes'),
      );
      final next = [...runs]..[idx] = updated;
      await _local.saveRuns(next);
      _logger.info('Experiment run failed $runId', tag: 'Experiments');
      return updated;
    });
  }

  @override
  Future<Result<ExperimentRun>> cancelRun(String runId) {
    return _guard(() async {
      final runs = await _local.loadRuns();
      final idx = _indexOf(runs, runId);
      final current = runs[idx];
      if (current.status == ExperimentRunStatus.completed) {
        throw const CacheException(message: 'Cannot cancel a completed run');
      }
      final now = DateTime.now().toUtc();
      final updated = current.copyWith(
        status: ExperimentRunStatus.cancelled,
        endedAt: now,
        updatedAt: now,
      );
      final next = [...runs]..[idx] = updated;
      await _local.saveRuns(next);
      return updated;
    });
  }

  @override
  Future<Result<void>> deleteRun(String runId) {
    return _guard(() async {
      final runs = await _local.loadRuns();
      if (!runs.any((r) => r.id == runId)) {
        throw const CacheException(message: 'Run not found');
      }
      await _local.saveRuns(runs.where((r) => r.id != runId).toList());
      _logger.info('Experiment run deleted $runId', tag: 'Experiments');
    });
  }

  @override
  Future<Result<ExperimentRun>> createDemoRun({
    String? modelId,
    String? modelVersion,
  }) {
    return _guard(() async {
      final now = DateTime.now().toUtc();
      final started = now.subtract(const Duration(minutes: 12));
      final run = ExperimentRun(
        id: _uuid.v4(),
        name: 'Demo finetune · YOLOv8n',
        experimentName: 'road-detection',
        status: ExperimentRunStatus.completed,
        source: ExperimentRunSource.demo,
        modelId: modelId ?? 'bundled-yolov8n',
        modelVersion: modelVersion ?? '1.0.0',
        params: const {
          'epochs': '10',
          'batch_size': '8',
          'lr': '0.001',
          'imgsz': '640',
          'optimizer': 'adam',
        },
        metrics: const {
          'mAP50': 0.62,
          'mAP50_95': 0.41,
          'precision': 0.71,
          'recall': 0.58,
          'loss': 0.34,
        },
        metricHistory: [
          ExperimentMetricPoint(
            key: 'loss',
            value: 0.82,
            step: 1,
            recordedAt: started.add(const Duration(minutes: 2)),
          ),
          ExperimentMetricPoint(
            key: 'loss',
            value: 0.51,
            step: 5,
            recordedAt: started.add(const Duration(minutes: 6)),
          ),
          ExperimentMetricPoint(
            key: 'loss',
            value: 0.34,
            step: 10,
            recordedAt: started.add(const Duration(minutes: 11)),
          ),
          ExperimentMetricPoint(
            key: 'mAP50',
            value: 0.62,
            step: 10,
            recordedAt: started.add(const Duration(minutes: 11)),
          ),
        ],
        tags: const {'demo': 'true', 'task': 'object_detection'},
        notes: 'Sample completed run for Experiment Tracking UI',
        createdAt: started,
        updatedAt: now,
        startedAt: started,
        endedAt: now,
      );
      final issues = _validator.validateRun(run);
      if (issues.isNotEmpty) {
        throw CacheException(message: issues.first.message);
      }
      final runs = await _local.loadRuns();
      await _local.saveRuns([...runs, run]);
      _logger.info('Demo experiment run created ${run.id}', tag: 'Experiments');
      return run;
    });
  }

  ExperimentRun _requireRun(List<ExperimentRun> runs, String runId) {
    final match = runs.where((r) => r.id == runId);
    if (match.isEmpty) {
      throw const CacheException(message: 'Run not found');
    }
    return match.first;
  }

  int _indexOf(List<ExperimentRun> runs, String runId) {
    final idx = runs.indexWhere((r) => r.id == runId);
    if (idx < 0) throw const CacheException(message: 'Run not found');
    return idx;
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
