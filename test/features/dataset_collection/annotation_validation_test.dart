import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/annotation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

Annotation _box({
  required String id,
  BoundingBox? box,
  String labelId = 'flooded_road',
}) {
  final now = DateTime.utc(2026, 7, 14);
  return Annotation(
    id: id,
    sessionId: 's1',
    frameNumber: 1,
    type: AnnotationType.boundingBox,
    labelId: labelId,
    status: AnnotationStatus.draft,
    box: box ??
        const BoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
    createdBy: 't',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AnnotationGeometryFactory factory;
  late AnnotationValidator validator;

  setUp(() {
    factory = AnnotationGeometryFactory();
    validator = AnnotationValidator(factory);
  });

  test('factory returns strategies for all types', () {
    for (final type in AnnotationType.values) {
      expect(factory.create(type).type, type);
    }
  });

  test('bounding box inside image passes', () {
    final issues = factory.create(AnnotationType.boundingBox).validate(
          _box(id: 'a'),
          imageWidth: 640,
          imageHeight: 480,
        );
    expect(issues, isEmpty);
  });

  test('bounding box out of bounds fails', () {
    final issues = factory.create(AnnotationType.boundingBox).validate(
          _box(
            id: 'a',
            box: const BoundingBox(x: 0.9, y: 0.9, width: 0.3, height: 0.3),
          ),
          imageWidth: 1,
          imageHeight: 1,
        );
    expect(issues.any((i) => i.code == 'box_out_of_bounds'), isTrue);
  });

  test('bounding box minimum size fails', () {
    final issues = factory.create(AnnotationType.boundingBox).validate(
          _box(
            id: 'a',
            box: const BoundingBox(x: 0.1, y: 0.1, width: 0.001, height: 0.001),
          ),
          imageWidth: 1,
          imageHeight: 1,
        );
    expect(issues.any((i) => i.code == 'box_too_small'), isTrue);
  });

  test('polygon must be closed', () {
    final now = DateTime.utc(2026, 7, 14);
    final ann = Annotation(
      id: 'p',
      sessionId: 's1',
      frameNumber: 1,
      type: AnnotationType.polygon,
      labelId: 'flooded_road',
      status: AnnotationStatus.draft,
      polygon: const PolygonGeometry(
        closed: false,
        points: [
          AnnotationPoint(0.1, 0.1),
          AnnotationPoint(0.2, 0.1),
          AnnotationPoint(0.2, 0.2),
        ],
      ),
      createdBy: 't',
      createdAt: now,
      updatedAt: now,
    );
    final issues = factory.create(AnnotationType.polygon).validate(
          ann,
          imageWidth: 1,
          imageHeight: 1,
        );
    expect(issues.any((i) => i.code == 'polygon_not_closed'), isTrue);
  });

  test('duplicate and overlap detection', () {
    final a = _box(id: 'a');
    final issues = validator.validateAnnotation(
      _box(id: 'b'),
      imageWidth: 1,
      imageHeight: 1,
      siblings: [a],
      enabledLabelIds: {'flooded_road'},
    );
    expect(issues.any((i) => i.code == 'duplicate_annotation'), isTrue);
    expect(issues.any((i) => i.code == 'overlapping_objects'), isTrue);
  });

  test('missing label flagged', () {
    final issues = validator.validateAnnotation(
      _box(id: 'a', labelId: ''),
      imageWidth: 1,
      imageHeight: 1,
      siblings: const [],
      enabledLabelIds: {'flooded_road'},
    );
    expect(issues.any((i) => i.code == 'missing_label'), isTrue);
  });

  test('placeholder types report placeholder_type', () {
    final now = DateTime.utc(2026, 7, 14);
    final ann = Annotation(
      id: 'm',
      sessionId: 's1',
      frameNumber: 1,
      type: AnnotationType.segmentationMask,
      labelId: 'flooded_road',
      status: AnnotationStatus.draft,
      createdBy: 't',
      createdAt: now,
      updatedAt: now,
    );
    final issues = factory.create(AnnotationType.segmentationMask).validate(
          ann,
          imageWidth: 1,
          imageHeight: 1,
        );
    expect(issues.first.code, 'placeholder_type');
  });
}
