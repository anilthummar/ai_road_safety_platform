import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/annotation_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AnnotationRepository {}

class _MockLabels extends Mock implements LabelRepository {}

class _MockCreate extends Mock implements CreateAnnotationUseCase {}

class _MockUpdate extends Mock implements UpdateAnnotationUseCase {}

class _MockDelete extends Mock implements DeleteAnnotationUseCase {}

class _MockUndo extends Mock implements UndoAnnotationUseCase {}

class _MockRedo extends Mock implements RedoAnnotationUseCase {}

class _MockApprove extends Mock implements ApproveAnnotationUseCase {}

class _MockReject extends Mock implements RejectAnnotationUseCase {}

class _MockLoadGt extends Mock implements LoadGroundTruthUseCase {}

void main() {
  late _MockRepo repo;
  late _MockLabels labels;
  late _MockCreate create;
  late _MockUpdate update;
  late _MockDelete delete;
  late _MockUndo undo;
  late _MockRedo redo;
  late _MockApprove approve;
  late _MockReject reject;
  late _MockLoadGt loadGt;

  final frame = const AnnotatableFrame(
    sessionId: 's1',
    frameNumber: 1,
    status: AnnotationStatus.unannotated,
    annotationCount: 0,
  );

  final gt = GroundTruth(
    sessionId: 's1',
    frameNumber: 1,
    annotations: const [],
    history: const [],
    frameStatus: AnnotationStatus.unannotated,
    updatedAt: DateTime.utc(2026, 7, 14),
  );

  final quality = const AnnotationQualityMetrics.empty();

  setUpAll(() {
    registerFallbackValue(
      Annotation(
        id: 'x',
        sessionId: 's1',
        frameNumber: 1,
        type: AnnotationType.boundingBox,
        labelId: 'flooded_road',
        status: AnnotationStatus.draft,
        createdBy: 't',
        createdAt: DateTime.utc(2026, 7, 14),
        updatedAt: DateTime.utc(2026, 7, 14),
        box: const BoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
      ),
    );
    registerFallbackValue(
      const FrameKeyParams(sessionId: 's1', frameNumber: 1),
    );
    registerFallbackValue(
      const DeleteAnnotationParams(
        sessionId: 's1',
        frameNumber: 1,
        annotationId: 'a',
      ),
    );
    registerFallbackValue(
      const ReviewAnnotationParams(
        sessionId: 's1',
        frameNumber: 1,
        annotationId: 'a',
      ),
    );
  });

  setUp(() {
    repo = _MockRepo();
    labels = _MockLabels();
    create = _MockCreate();
    update = _MockUpdate();
    delete = _MockDelete();
    undo = _MockUndo();
    redo = _MockRedo();
    approve = _MockApprove();
    reject = _MockReject();
    loadGt = _MockLoadGt();

    when(() => labels.getLabels())
        .thenAnswer((_) async => const Ok(DefaultHazardLabels.all));
    when(() => repo.listFrames(any())).thenAnswer((_) async => Ok([frame]));
    when(() => repo.qualityMetrics(any())).thenAnswer((_) async => Ok(quality));
    when(() => loadGt(any())).thenAnswer((_) async => Ok(gt));
    when(() => repo.canUndo(sessionId: any(named: 'sessionId'), frameNumber: any(named: 'frameNumber')))
        .thenAnswer((_) async => const Ok(false));
    when(() => repo.canRedo(sessionId: any(named: 'sessionId'), frameNumber: any(named: 'frameNumber')))
        .thenAnswer((_) async => const Ok(false));
  });

  AnnotationBloc build() => AnnotationBloc(
        repository: repo,
        labelRepository: labels,
        createAnnotation: create,
        updateAnnotation: update,
        deleteAnnotation: delete,
        undoAnnotation: undo,
        redoAnnotation: redo,
        approveAnnotation: approve,
        rejectAnnotation: reject,
        loadGroundTruth: loadGt,
        logger: AppLogger(),
      );

  blocTest<AnnotationBloc, AnnotationState>(
    'loads session into editing',
    build: build,
    act: (b) => b.add(const AnnotationLoadSession('s1')),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<AnnotationLoading>(),
      isA<AnnotationEditing>().having((e) => e.sessionId, 'session', 's1'),
    ],
  );

  blocTest<AnnotationBloc, AnnotationState>(
    'tool / zoom / label selection',
    build: build,
    seed: () => AnnotationEditing(
      sessionId: 's1',
      frames: [frame],
      groundTruth: gt,
      labels: DefaultHazardLabels.all,
      tool: AnnotationTool.select,
      selectedLabelId: DefaultHazardLabels.all.first.id,
      zoom: 1,
      panX: 0,
      panY: 0,
      undoAvailable: false,
      redoAvailable: false,
      quality: quality,
    ),
    act: (b) {
      b.add(const AnnotationSelectTool(AnnotationTool.boundingBox));
      b.add(AnnotationSelectLabel(DefaultHazardLabels.all[1].id));
      b.add(const AnnotationSetZoom(2));
      b.add(const AnnotationFitToScreen());
    },
    expect: () => [
      isA<AnnotationEditing>()
          .having((e) => e.tool, 'tool', AnnotationTool.boundingBox),
      isA<AnnotationEditing>().having(
        (e) => e.selectedLabelId,
        'label',
        DefaultHazardLabels.all[1].id,
      ),
      isA<AnnotationEditing>().having((e) => e.zoom, 'zoom', 2.0),
      isA<AnnotationEditing>().having((e) => e.zoom, 'fit', 1.0),
    ],
  );

  blocTest<AnnotationBloc, AnnotationState>(
    'create annotation saves and reloads',
    build: build,
    seed: () => AnnotationEditing(
      sessionId: 's1',
      frames: [frame],
      groundTruth: gt,
      labels: DefaultHazardLabels.all,
      tool: AnnotationTool.boundingBox,
      selectedLabelId: DefaultHazardLabels.all.first.id,
      zoom: 1,
      panX: 0,
      panY: 0,
      undoAvailable: false,
      redoAvailable: false,
      quality: quality,
    ),
    setUp: () {
      final now = DateTime.utc(2026, 7, 14);
      final ann = Annotation(
        id: 'a1',
        sessionId: 's1',
        frameNumber: 1,
        type: AnnotationType.boundingBox,
        labelId: 'flooded_road',
        status: AnnotationStatus.draft,
        box: const BoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        createdBy: 't',
        createdAt: now,
        updatedAt: now,
      );
      when(() => create(any())).thenAnswer((_) async => Ok(ann));
      when(() => loadGt(any())).thenAnswer(
        (_) async => Ok(
          gt.copyWith(annotations: [ann], frameStatus: AnnotationStatus.draft),
        ),
      );
      when(() => repo.canUndo(sessionId: any(named: 'sessionId'), frameNumber: any(named: 'frameNumber')))
          .thenAnswer((_) async => const Ok(true));
    },
    act: (b) {
      final now = DateTime.utc(2026, 7, 14);
      b.add(
        AnnotationCreate(
          Annotation(
            id: 'a1',
            sessionId: 's1',
            frameNumber: 1,
            type: AnnotationType.boundingBox,
            labelId: 'flooded_road',
            status: AnnotationStatus.draft,
            box: const BoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            createdBy: 't',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    },
    expect: () => [
      isA<AnnotationSaving>(),
      isA<AnnotationEditing>()
          .having((e) => e.groundTruth.annotations.length, 'anns', 1)
          .having((e) => e.undoAvailable, 'undo', true)
          .having((e) => e.statusMessage, 'msg', 'Saved'),
    ],
  );

  blocTest<AnnotationBloc, AnnotationState>(
    'undo restores previous ground truth',
    build: build,
    seed: () => AnnotationEditing(
      sessionId: 's1',
      frames: [frame],
      groundTruth: gt.copyWith(
        annotations: [
          Annotation(
            id: 'a1',
            sessionId: 's1',
            frameNumber: 1,
            type: AnnotationType.boundingBox,
            labelId: 'flooded_road',
            status: AnnotationStatus.draft,
            box: const BoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            createdBy: 't',
            createdAt: DateTime.utc(2026, 7, 14),
            updatedAt: DateTime.utc(2026, 7, 14),
          ),
        ],
      ),
      labels: DefaultHazardLabels.all,
      tool: AnnotationTool.select,
      selectedLabelId: DefaultHazardLabels.all.first.id,
      zoom: 1,
      panX: 0,
      panY: 0,
      undoAvailable: true,
      redoAvailable: false,
      quality: quality,
    ),
    setUp: () {
      when(() => undo(any())).thenAnswer((_) async => Ok(gt));
      when(() => repo.canUndo(sessionId: any(named: 'sessionId'), frameNumber: any(named: 'frameNumber')))
          .thenAnswer((_) async => const Ok(false));
      when(() => repo.canRedo(sessionId: any(named: 'sessionId'), frameNumber: any(named: 'frameNumber')))
          .thenAnswer((_) async => const Ok(true));
    },
    act: (b) => b.add(const AnnotationUndo()),
    expect: () => [
      isA<AnnotationEditing>()
          .having((e) => e.groundTruth.annotations, 'empty', isEmpty)
          .having((e) => e.redoAvailable, 'redo', true),
    ],
  );
}
