import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/annotation_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/annotation_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/annotation_geometry.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late AnnotationRepositoryImpl repo;
  late LabelRepositoryImpl labels;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ann_repo_');
    files = _MockFiles();
    when(() => files.paths).thenReturn(DatasetPaths(root: temp.path));
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory('${temp.path}/sessions').create(recursive: true);
      await Directory('${temp.path}/annotations').create(recursive: true);
    });
    when(() => files.exists(any())).thenAnswer((_) async => false);

    final local = AnnotationLocalDataSourceImpl(
      fileManager: files,
      logger: AppLogger(),
    );
    final factory = AnnotationGeometryFactory();
    repo = AnnotationRepositoryImpl(
      localDataSource: local,
      fileManager: files,
      validator: AnnotationValidator(factory),
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
    labels = LabelRepositoryImpl(
      localDataSource: local,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Annotation box(String id, {BoundingBox? geometry}) {
    final now = DateTime.utc(2026, 7, 14);
    return Annotation(
      id: id,
      sessionId: 'sess',
      frameNumber: 1,
      type: AnnotationType.boundingBox,
      labelId: 'flooded_road',
      status: AnnotationStatus.draft,
      box: geometry ??
          const BoundingBox(x: 0.1, y: 0.1, width: 0.25, height: 0.25),
      createdBy: 'researcher',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('default hazard labels seed', () async {
    final result = await labels.getLabels();
    expect(result.isOk, isTrue);
    final list = result.fold(onOk: (v) => v, onErr: (_) => <AnnotationLabel>[]);
    expect(list.length, DefaultHazardLabels.all.length);
    expect(list.any((l) => l.id == 'pothole'), isTrue);
  });

  test('save update delete ground truth', () async {
    final saved = await repo.saveAnnotation(box('a1'));
    expect(saved.isOk, isTrue);

    final gt = await repo.getGroundTruth(sessionId: 'sess', frameNumber: 1);
    expect(gt.isOk, isTrue);
    expect(
      gt.fold(onOk: (v) => v.annotations.length, onErr: (_) => 0),
      1,
    );

    final updated = box('a1').copyWith(
      box: const BoundingBox(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
    );
    expect((await repo.updateAnnotation(updated)).isOk, isTrue);

    expect(
      (await repo.deleteAnnotation(
        sessionId: 'sess',
        frameNumber: 1,
        annotationId: 'a1',
      ))
          .isOk,
      isTrue,
    );
    final empty = await repo.getGroundTruth(sessionId: 'sess', frameNumber: 1);
    expect(
      empty.fold(onOk: (v) => v.annotations, onErr: (_) => <Annotation>[]),
      isEmpty,
    );
  });

  test('approve reject and quality metrics', () async {
    await repo.saveAnnotation(box('a1'));
    expect(
      (await repo.approveAnnotation(
        sessionId: 'sess',
        frameNumber: 1,
        annotationId: 'a1',
      ))
          .isOk,
      isTrue,
    );
    final quality = await repo.qualityMetrics('sess');
    expect(quality.isOk, isTrue);
    expect(
      quality.fold(onOk: (v) => v.approvedFrames, onErr: (_) => 0),
      greaterThan(0),
    );

    await repo.saveAnnotation(
      box(
        'a2',
        geometry: const BoundingBox(x: 0.6, y: 0.6, width: 0.2, height: 0.2),
      ),
    );
    expect(
      (await repo.rejectAnnotation(
        sessionId: 'sess',
        frameNumber: 1,
        annotationId: 'a2',
        reason: 'bad',
      ))
          .isOk,
      isTrue,
    );
  });

  test('undo redo stack', () async {
    await repo.saveAnnotation(box('a1'));
    expect(
      (await repo.canUndo(sessionId: 'sess', frameNumber: 1))
          .fold(onOk: (v) => v, onErr: (_) => false),
      isTrue,
    );
    final undone = await repo.undo(sessionId: 'sess', frameNumber: 1);
    expect(undone.isOk, isTrue);
    expect(
      undone.fold(onOk: (v) => v.annotations, onErr: (_) => <Annotation>[]),
      isEmpty,
    );
    final redone = await repo.redo(sessionId: 'sess', frameNumber: 1);
    expect(
      redone.fold(onOk: (v) => v.annotations.length, onErr: (_) => 0),
      1,
    );
  });

  test('duplicate split merge', () async {
    await repo.saveAnnotation(box('a1'));
    final dup = await repo.duplicateAnnotation(
      sessionId: 'sess',
      frameNumber: 1,
      annotationId: 'a1',
    );
    expect(dup.isOk, isTrue);

    await repo.saveAnnotation(
      box(
        'b1',
        geometry: const BoundingBox(x: 0.5, y: 0.1, width: 0.2, height: 0.2),
      ),
    );
    final merged = await repo.mergeAnnotations(
      sessionId: 'sess',
      frameNumber: 1,
      primaryId: 'a1',
      secondaryId: 'b1',
    );
    expect(merged.isOk, isTrue);

    final split = await repo.splitAnnotation(
      sessionId: 'sess',
      frameNumber: 1,
      annotationId: 'a1',
    );
    expect(split.isOk, isTrue);
    expect(
      split.fold(onOk: (v) => v.length, onErr: (_) => 0),
      2,
    );
  });

  test('accept AI detection stays editable draft', () async {
    final suggestion = box('ai1').copyWith(fromAi: true, aiConfidence: 0.9);
    final result = await repo.acceptAiDetection(suggestion);
    expect(result.isOk, isTrue);
    final ann = result.fold(onOk: (v) => v, onErr: (_) => box('x'));
    expect(ann.fromAi, isTrue);
    expect(ann.status, AnnotationStatus.draft);
  });
}
