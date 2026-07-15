import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/active_learning_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/active_learning_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/active_learning_engine.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

class _MockAnnotations extends Mock implements AnnotationRepository {}

class _MockSessions extends Mock implements DatasetCollectionRepository {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late _MockAnnotations annotations;
  late _MockSessions sessions;
  late ActiveLearningRepositoryImpl repo;

  final now = DateTime.utc(2026, 7, 14);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('al_');
    files = _MockFiles();
    annotations = _MockAnnotations();
    sessions = _MockSessions();
    final paths = DatasetPaths(root: temp.path);
    when(() => files.paths).thenReturn(paths);
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory(paths.activeLearning).create(recursive: true);
    });

    repo = ActiveLearningRepositoryImpl(
      localDataSource: ActiveLearningLocalDataSourceImpl(
        fileManager: files,
        logger: AppLogger(),
      ),
      engine: const ActiveLearningEngine(),
      annotationRepository: annotations,
      collectionRepository: sessions,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('runSelection ranks unlabeled over approved', () async {
    when(() => annotations.loadSessionGroundTruth('s1')).thenAnswer(
      (_) async => Ok([
        GroundTruth(
          sessionId: 's1',
          frameNumber: 1,
          annotations: const [],
          history: const [],
          frameStatus: AnnotationStatus.unannotated,
          updatedAt: now,
        ),
        GroundTruth(
          sessionId: 's1',
          frameNumber: 2,
          annotations: [
            Annotation(
              id: 'a',
              sessionId: 's1',
              frameNumber: 2,
              type: AnnotationType.boundingBox,
              labelId: 'pothole',
              status: AnnotationStatus.approved,
              createdBy: 'human',
              createdAt: now,
              updatedAt: now,
              box: const BoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            ),
          ],
          history: const [],
          frameStatus: AnnotationStatus.approved,
          updatedAt: now,
        ),
      ]),
    );

    final result = await repo.runSelection(sessionIds: const ['s1']);
    expect(result.isOk, isTrue);
    final sel = result.fold(
      onOk: (v) => v,
      onErr: (_) => throw StateError('expected ok'),
    );
    expect(sel.candidates.first.frameNumber, 1);
    expect(sel.framesConsidered, 2);

    final snap = await repo.loadSnapshot();
    expect(snap.fold(onOk: (s) => s.totalSelections, onErr: (_) => 0), 1);
  });

  test('createDemoSelection persists candidates', () async {
    final result = await repo.createDemoSelection();
    expect(result.isOk, isTrue);
    expect(
      result.fold(onOk: (s) => s.isDemo, onErr: (_) => false),
      isTrue,
    );
    expect(
      result.fold(onOk: (s) => s.selectedCount, onErr: (_) => 0),
      greaterThan(0),
    );
  });

  test('deleteSelection removes entry', () async {
    final created = await repo.createDemoSelection();
    final id = created.fold(onOk: (s) => s.id, onErr: (_) => '');
    expect((await repo.deleteSelection(id)).isOk, isTrue);
    final snap = await repo.loadSnapshot();
    expect(snap.fold(onOk: (s) => s.totalSelections, onErr: (_) => -1), 0);
  });
}
