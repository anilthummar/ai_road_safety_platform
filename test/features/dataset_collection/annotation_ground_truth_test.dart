import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GroundTruth json round-trip preserves annotations & history', () {
    final now = DateTime.utc(2026, 7, 14, 12);
    final ann = Annotation(
      id: 'a1',
      sessionId: 's1',
      frameNumber: 2,
      type: AnnotationType.point,
      labelId: 'crack',
      status: AnnotationStatus.reviewed,
      point: const AnnotationPoint(0.4, 0.5),
      fromAi: true,
      aiConfidence: 0.81,
      createdBy: 'researcher',
      createdAt: now,
      updatedAt: now,
      version: 3,
      reviewComment: 'ok',
    );
    final gt = GroundTruth(
      sessionId: 's1',
      frameNumber: 2,
      imagePath: '/tmp/frame.jpg',
      imageWidth: 1280,
      imageHeight: 720,
      annotations: [ann],
      history: [
        AnnotationHistoryEntry(
          id: 'h1',
          annotationId: 'a1',
          action: AnnotationHistoryAction.created,
          reviewer: 'researcher',
          timestamp: now,
          version: 1,
        ),
      ],
      frameStatus: AnnotationStatus.reviewed,
      reviewers: const ['researcher', 'qa'],
      reviewComment: 'looks good',
      updatedAt: now,
    );

    final restored = GroundTruth.fromJson(gt.toJson());
    expect(restored, gt);
    expect(restored.annotations.single.point, const AnnotationPoint(0.4, 0.5));
    expect(restored.reviewers, ['researcher', 'qa']);
  });

  test('DefaultHazardLabels covers required road hazard classes', () {
    final ids = DefaultHazardLabels.all.map((l) => l.id).toSet();
    expect(
      ids.containsAll({
        'flooded_road',
        'water_pool',
        'hidden_hazard',
        'pothole',
        'crack',
        'broken_road',
        'speed_breaker',
        'edge_damage',
        'construction',
        'obstacle',
        'unknown',
      }),
      isTrue,
    );
  });

  test('AnnotationStatus labels are human readable', () {
    expect(AnnotationStatus.needsReview.label, 'Needs review');
    expect(AnnotationStatus.approved.label, 'Approved');
  });
}
