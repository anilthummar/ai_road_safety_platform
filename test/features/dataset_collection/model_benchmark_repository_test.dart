import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_benchmark_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/model_benchmark_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_benchmark_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

class _MockAnnotations extends Mock implements AnnotationRepository {}

class _MockSessions extends Mock implements DatasetCollectionRepository {}

class _MockModels extends Mock implements ModelRegistryRepository {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late _MockAnnotations annotations;
  late _MockSessions sessions;
  late _MockModels models;
  late ModelBenchmarkRepositoryImpl repo;

  final now = DateTime.utc(2026, 7, 14);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('bench_');
    files = _MockFiles();
    annotations = _MockAnnotations();
    sessions = _MockSessions();
    models = _MockModels();
    final paths = DatasetPaths(root: temp.path);
    when(() => files.paths).thenReturn(paths);
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory(paths.benchmarks).create(recursive: true);
    });
    when(() => models.getModel(any())).thenAnswer(
      (_) async => Ok(
        RegisteredModel(
          id: 'bundled-yolov8n',
          name: 'YOLO',
          version: '1.0.0',
          taskType: ModelTaskType.objectDetection,
          status: ModelStatus.active,
          createdAt: now,
          updatedAt: now,
          artifacts: const [
            ModelArtifact(
              id: 'a',
              fileName: 'y.tflite',
              assetPath: 'assets/models/yolov8n.tflite',
              source: ModelArtifactSource.bundledAsset,
            ),
          ],
        ),
      ),
    );

    repo = ModelBenchmarkRepositoryImpl(
      localDataSource: ModelBenchmarkLocalDataSourceImpl(
        fileManager: files,
        logger: AppLogger(),
      ),
      engine: const ModelBenchmarkEngine(),
      annotationRepository: annotations,
      collectionRepository: sessions,
      modelRegistryRepository: models,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('runBenchmark scores AI vs human boxes', () async {
    when(() => annotations.loadSessionGroundTruth('s1')).thenAnswer(
      (_) async => Ok([
        GroundTruth(
          sessionId: 's1',
          frameNumber: 1,
          imageWidth: 100,
          imageHeight: 100,
          annotations: [
            Annotation(
              id: 'h1',
              sessionId: 's1',
              frameNumber: 1,
              type: AnnotationType.boundingBox,
              labelId: 'pothole',
              status: AnnotationStatus.approved,
              createdBy: 'human',
              createdAt: now,
              updatedAt: now,
              box: const BoundingBox(
                x: 0.1,
                y: 0.1,
                width: 0.2,
                height: 0.2,
              ),
            ),
            Annotation(
              id: 'a1',
              sessionId: 's1',
              frameNumber: 1,
              type: AnnotationType.boundingBox,
              labelId: 'pothole',
              status: AnnotationStatus.draft,
              createdBy: 'ai',
              createdAt: now,
              updatedAt: now,
              fromAi: true,
              aiConfidence: 0.9,
              box: const BoundingBox(
                x: 0.11,
                y: 0.11,
                width: 0.19,
                height: 0.19,
              ),
            ),
          ],
          history: const [],
          frameStatus: AnnotationStatus.approved,
          updatedAt: now,
        ),
      ]),
    );

    final result = await repo.runBenchmark(
      modelId: 'bundled-yolov8n',
      sessionIds: const ['s1'],
    );
    expect(result.isOk, isTrue);
    final report = result.fold(
      onOk: (r) => r,
      onErr: (_) => throw StateError('expected ok'),
    );
    expect(report.mode, BenchmarkPredictionMode.aiVsHuman);
    expect(report.metrics.truePositives, 1);
    expect(report.framesScored, 1);

    final snap = await repo.loadSnapshot();
    expect(snap.fold(onOk: (s) => s.totalCount, onErr: (_) => 0), 1);
  });

  test('createDemoReport persists metrics', () async {
    final result = await repo.createDemoReport();
    expect(result.isOk, isTrue);
    expect(
      result.fold(
        onOk: (r) => r.mode,
        onErr: (_) => BenchmarkPredictionMode.aiVsHuman,
      ),
      BenchmarkPredictionMode.demo,
    );
    expect(
      result.fold(onOk: (r) => r.metrics.truePositives, onErr: (_) => 0),
      greaterThan(0),
    );
  });

  test('deleteReport removes entry', () async {
    final created = await repo.createDemoReport();
    final id = created.fold(onOk: (r) => r.id, onErr: (_) => '');
    expect((await repo.deleteReport(id)).isOk, isTrue);
    final snap = await repo.loadSnapshot();
    expect(snap.fold(onOk: (s) => s.totalCount, onErr: (_) => -1), 0);
  });
}
