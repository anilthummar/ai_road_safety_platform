import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';

/// Strategy for creating / validating a geometry type (Phase 12.9).
abstract class AnnotationGeometryStrategy {
  AnnotationType get type;

  /// Whether geometry fields on [annotation] are structurally complete.
  bool hasGeometry(Annotation annotation);

  /// Validate against image bounds \[0–1\] and domain rules.
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  });
}

class BoundingBoxStrategy implements AnnotationGeometryStrategy {
  const BoundingBoxStrategy();

  @override
  AnnotationType get type => AnnotationType.boundingBox;

  @override
  bool hasGeometry(Annotation annotation) => annotation.box != null;

  @override
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  }) {
    final issues = <AnnotationValidationIssue>[];
    final box = annotation.box;
    if (box == null) {
      issues.add(
        AnnotationValidationIssue(
          code: 'missing_box',
          message: 'Bounding box geometry missing',
          annotationId: annotation.id,
        ),
      );
      return issues;
    }
    if (box.x < 0 ||
        box.y < 0 ||
        box.right > 1.0001 ||
        box.bottom > 1.0001) {
      issues.add(
        AnnotationValidationIssue(
          code: 'box_out_of_bounds',
          message: 'Bounding box must stay inside the image',
          annotationId: annotation.id,
        ),
      );
    }
    if (box.width < 0.005 || box.height < 0.005) {
      issues.add(
        AnnotationValidationIssue(
          code: 'box_too_small',
          message: 'Bounding box below minimum size',
          annotationId: annotation.id,
        ),
      );
    }
    return issues;
  }
}

class PolygonStrategy implements AnnotationGeometryStrategy {
  const PolygonStrategy();

  @override
  AnnotationType get type => AnnotationType.polygon;

  @override
  bool hasGeometry(Annotation annotation) =>
      annotation.polygon != null && annotation.polygon!.points.length >= 3;

  @override
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  }) {
    final issues = <AnnotationValidationIssue>[];
    final poly = annotation.polygon;
    if (poly == null || poly.points.length < 3) {
      issues.add(
        AnnotationValidationIssue(
          code: 'polygon_incomplete',
          message: 'Polygon requires at least 3 points',
          annotationId: annotation.id,
        ),
      );
      return issues;
    }
    if (!poly.closed) {
      issues.add(
        AnnotationValidationIssue(
          code: 'polygon_not_closed',
          message: 'Polygon must be closed',
          annotationId: annotation.id,
        ),
      );
    }
    for (final p in poly.points) {
      if (p.x < 0 || p.x > 1.0001 || p.y < 0 || p.y > 1.0001) {
        issues.add(
          AnnotationValidationIssue(
            code: 'polygon_out_of_bounds',
            message: 'Polygon vertex outside image',
            annotationId: annotation.id,
          ),
        );
        break;
      }
    }
    return issues;
  }
}

class PolylineStrategy implements AnnotationGeometryStrategy {
  const PolylineStrategy();

  @override
  AnnotationType get type => AnnotationType.polyline;

  @override
  bool hasGeometry(Annotation annotation) =>
      annotation.polygon != null && annotation.polygon!.points.length >= 2;

  @override
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  }) {
    final poly = annotation.polygon;
    if (poly == null || poly.points.length < 2) {
      return [
        AnnotationValidationIssue(
          code: 'polyline_incomplete',
          message: 'Polyline requires at least 2 points',
          annotationId: annotation.id,
        ),
      ];
    }
    return const [];
  }
}

class PointStrategy implements AnnotationGeometryStrategy {
  const PointStrategy();

  @override
  AnnotationType get type => AnnotationType.point;

  @override
  bool hasGeometry(Annotation annotation) => annotation.point != null;

  @override
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  }) {
    final p = annotation.point;
    if (p == null) {
      return [
        AnnotationValidationIssue(
          code: 'missing_point',
          message: 'Point geometry missing',
          annotationId: annotation.id,
        ),
      ];
    }
    if (p.x < 0 || p.x > 1 || p.y < 0 || p.y > 1) {
      return [
        AnnotationValidationIssue(
          code: 'point_out_of_bounds',
          message: 'Point outside image',
          annotationId: annotation.id,
        ),
      ];
    }
    return const [];
  }
}

class ClassificationStrategy implements AnnotationGeometryStrategy {
  const ClassificationStrategy();

  @override
  AnnotationType get type => AnnotationType.classification;

  @override
  bool hasGeometry(Annotation annotation) => annotation.labelId.isNotEmpty;

  @override
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (annotation.labelId.isEmpty) {
      return [
        AnnotationValidationIssue(
          code: 'missing_label',
          message: 'Classification requires a label',
          annotationId: annotation.id,
        ),
      ];
    }
    return const [];
  }
}

/// Placeholder strategy for future mask / keypoints types.
class PlaceholderGeometryStrategy implements AnnotationGeometryStrategy {
  @override
  final AnnotationType type;

  const PlaceholderGeometryStrategy(this.type);

  @override
  bool hasGeometry(Annotation annotation) => false;

  @override
  List<AnnotationValidationIssue> validate(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
  }) {
    return [
      AnnotationValidationIssue(
        code: 'placeholder_type',
        message: '${type.label} is a placeholder geometry',
        annotationId: annotation.id,
      ),
    ];
  }
}

/// Factory for geometry strategies (Open/Closed).
class AnnotationGeometryFactory {
  final Map<AnnotationType, AnnotationGeometryStrategy> _cache = {};

  AnnotationGeometryStrategy create(AnnotationType type) {
    return _cache.putIfAbsent(type, () => _build(type));
  }

  AnnotationGeometryStrategy _build(AnnotationType type) {
    return switch (type) {
      AnnotationType.boundingBox => const BoundingBoxStrategy(),
      AnnotationType.polygon => const PolygonStrategy(),
      AnnotationType.polyline => const PolylineStrategy(),
      AnnotationType.point => const PointStrategy(),
      AnnotationType.classification => const ClassificationStrategy(),
      AnnotationType.segmentationMask =>
        const PlaceholderGeometryStrategy(AnnotationType.segmentationMask),
      AnnotationType.keypoints =>
        const PlaceholderGeometryStrategy(AnnotationType.keypoints),
    };
  }
}

/// Cross-cutting annotation validator.
class AnnotationValidator {
  final AnnotationGeometryFactory _factory;

  const AnnotationValidator(this._factory);

  List<AnnotationValidationIssue> validateAnnotation(
    Annotation annotation, {
    required double imageWidth,
    required double imageHeight,
    required List<Annotation> siblings,
    required Set<String> enabledLabelIds,
  }) {
    final issues = <AnnotationValidationIssue>[];
    if (annotation.labelId.isEmpty ||
        !enabledLabelIds.contains(annotation.labelId)) {
      issues.add(
        AnnotationValidationIssue(
          code: 'missing_label',
          message: 'Missing or disabled label',
          annotationId: annotation.id,
        ),
      );
    }
    issues.addAll(
      _factory.create(annotation.type).validate(
            annotation,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
          ),
    );

    // Duplicate identical boxes.
    if (annotation.box != null) {
      for (final other in siblings) {
        if (other.id == annotation.id || other.box == null) continue;
        if (other.box == annotation.box && other.labelId == annotation.labelId) {
          issues.add(
            AnnotationValidationIssue(
              code: 'duplicate_annotation',
              message: 'Duplicate bounding box / label',
              annotationId: annotation.id,
            ),
          );
          break;
        }
      }
    }

    // Rough overlap warning for boxes (>70% IoU).
    if (annotation.box != null) {
      for (final other in siblings) {
        if (other.id == annotation.id || other.box == null) continue;
        final iou = _iou(annotation.box!, other.box!);
        if (iou > 0.7) {
          issues.add(
            AnnotationValidationIssue(
              code: 'overlapping_objects',
              message: 'High overlap with another box (IoU ${iou.toStringAsFixed(2)})',
              annotationId: annotation.id,
            ),
          );
          break;
        }
      }
    }

    return issues;
  }

  double _iou(BoundingBox a, BoundingBox b) {
    final x1 = a.x > b.x ? a.x : b.x;
    final y1 = a.y > b.y ? a.y : b.y;
    final x2 = a.right < b.right ? a.right : b.right;
    final y2 = a.bottom < b.bottom ? a.bottom : b.bottom;
    final iw = x2 - x1;
    final ih = y2 - y1;
    if (iw <= 0 || ih <= 0) return 0;
    final inter = iw * ih;
    final union = a.area + b.area - inter;
    if (union <= 0) return 0;
    return inter / union;
  }
}
