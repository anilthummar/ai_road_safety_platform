import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/annotation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnnotationToolbar selects box tool', (tester) async {
    AnnotationTool? selected = AnnotationTool.select;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnnotationToolbar(
            tool: selected,
            onTool: (t) => selected = t,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Box'));
    await tester.pump();
    expect(selected, AnnotationTool.boundingBox);
  });

  testWidgets('LabelSelector shows hazard labels', (tester) async {
    String? id = DefaultHazardLabels.all.first.id;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelSelector(
            labels: DefaultHazardLabels.all,
            selectedId: id,
            onSelected: (v) => id = v,
          ),
        ),
      ),
    );
    expect(find.text('Flooded Road'), findsOneWidget);
  });

  testWidgets('GroundTruthPanel shows quality', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroundTruthPanel(
            groundTruth: GroundTruth(
              sessionId: 's1',
              frameNumber: 3,
              annotations: const [],
              history: const [],
              frameStatus: AnnotationStatus.draft,
              updatedAt: DateTime.utc(2026, 7, 14),
            ),
            quality: const AnnotationQualityMetrics(
              totalFrames: 10,
              annotatedFrames: 4,
              approvedFrames: 2,
              missingLabelCount: 0,
              completeness: 0.4,
              approvalPercentage: 20,
              qualityScore: 32,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Completeness 40%'), findsOneWidget);
    expect(find.textContaining('Frame #3'), findsOneWidget);
  });

  testWidgets('AnnotationCanvas paints without crash', (tester) async {
    final now = DateTime.utc(2026, 7, 14);
    final editing = AnnotationEditing(
      sessionId: 's1',
      frames: const [
        AnnotatableFrame(
          sessionId: 's1',
          frameNumber: 1,
          status: AnnotationStatus.draft,
          annotationCount: 1,
        ),
      ],
      groundTruth: GroundTruth(
        sessionId: 's1',
        frameNumber: 1,
        annotations: [
          Annotation(
            id: 'a1',
            sessionId: 's1',
            frameNumber: 1,
            type: AnnotationType.boundingBox,
            labelId: DefaultHazardLabels.all.first.id,
            status: AnnotationStatus.draft,
            box: const BoundingBox(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
            createdBy: 't',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        history: const [],
        frameStatus: AnnotationStatus.draft,
        updatedAt: now,
      ),
      labels: DefaultHazardLabels.all,
      tool: AnnotationTool.boundingBox,
      selectedLabelId: DefaultHazardLabels.all.first.id,
      zoom: 1,
      panX: 0,
      panY: 0,
      undoAvailable: false,
      redoAvailable: false,
      quality: const AnnotationQualityMetrics.empty(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: AnnotationCanvas(
              state: editing,
              onCreate: (_) {},
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AnnotationCanvas), findsOneWidget);
    expect(find.textContaining('No image'), findsOneWidget);
  });

  testWidgets('UndoRedoBar disables when unavailable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UndoRedoBar(canUndo: false, canRedo: false),
        ),
      ),
    );
    final undo = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo),
    );
    expect(undo.onPressed, isNull);
  });
}
