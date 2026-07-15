import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/experiment_tracking_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/experiment_tracking_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/experiment_tracking_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late ExperimentTrackingRepositoryImpl repo;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('exp_track_');
    files = _MockFiles();
    final paths = DatasetPaths(root: temp.path);
    when(() => files.paths).thenReturn(paths);
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory(paths.experiments).create(recursive: true);
    });

    repo = ExperimentTrackingRepositoryImpl(
      localDataSource: ExperimentTrackingLocalDataSourceImpl(
        fileManager: files,
        logger: AppLogger(),
      ),
      validator: const ExperimentTrackingValidator(),
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('create start log complete lifecycle', () async {
    final created = await repo.createRun(
      name: 'Run A',
      experimentName: 'road-detection',
      modelId: 'bundled-yolov8n',
      params: const {'epochs': '3'},
    );
    expect(created.isOk, isTrue);
    final id = created.fold(onOk: (r) => r.id, onErr: (_) => '');

    expect((await repo.startRun(id)).isOk, isTrue);

    final logged = await repo.logMetric(
      runId: id,
      key: 'loss',
      value: 0.4,
      step: 1,
    );
    expect(logged.isOk, isTrue);
    expect(
      logged.fold(onOk: (r) => r.metrics['loss'], onErr: (_) => null),
      0.4,
    );

    final completed = await repo.completeRun(id);
    expect(completed.isOk, isTrue);
    expect(
      completed.fold(
        onOk: (r) => r.status,
        onErr: (_) => ExperimentRunStatus.failed,
      ),
      ExperimentRunStatus.completed,
    );

    final snap = await repo.loadTracker();
    expect(snap.fold(onOk: (s) => s.totalCount, onErr: (_) => 0), 1);
  });

  test('cannot log metrics before start', () async {
    final created = await repo.createRun(name: 'Draft');
    final id = created.fold(onOk: (r) => r.id, onErr: (_) => '');
    final result = await repo.logMetric(runId: id, key: 'loss', value: 1);
    expect(result.isErr, isTrue);
  });

  test('demo run is completed with params and metrics', () async {
    final demo = await repo.createDemoRun();
    expect(demo.isOk, isTrue);
    final run = demo.fold(
      onOk: (r) => r,
      onErr: (_) => throw StateError('expected ok'),
    );
    expect(run.status, ExperimentRunStatus.completed);
    expect(run.params.containsKey('epochs'), isTrue);
    expect(run.metrics.containsKey('mAP50'), isTrue);
    expect(run.metricHistory, isNotEmpty);
  });

  test('delete removes run', () async {
    final created = await repo.createRun(name: 'Temp');
    final id = created.fold(onOk: (r) => r.id, onErr: (_) => '');
    expect((await repo.deleteRun(id)).isOk, isTrue);
    final snap = await repo.loadTracker();
    expect(snap.fold(onOk: (s) => s.totalCount, onErr: (_) => -1), 0);
  });
}
