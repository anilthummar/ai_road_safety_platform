import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';

/// Configurable label catalogue.
abstract class LabelRepository {
  Future<Result<List<AnnotationLabel>>> getLabels();
  Future<Result<AnnotationLabel>> addLabel(AnnotationLabel label);
  Future<Result<AnnotationLabel>> updateLabel(AnnotationLabel label);
  Future<Result<void>> deleteLabel(String id);
}

/// Ground-truth / annotation persistence + undo stack.
abstract class AnnotationRepository {
  /// Lists annotatable frames for a session (disk images + GT status).
  Future<Result<List<AnnotatableFrame>>> listFrames(String sessionId);

  Future<Result<GroundTruth>> loadAnnotations({
    required String sessionId,
    required int frameNumber,
  });

  Future<Result<GroundTruth>> getGroundTruth({
    required String sessionId,
    required int frameNumber,
  });

  Future<Result<Annotation>> saveAnnotation(Annotation annotation);

  Future<Result<Annotation>> updateAnnotation(Annotation annotation);

  Future<Result<void>> deleteAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  });

  Future<Result<GroundTruth>> undo({
    required String sessionId,
    required int frameNumber,
  });

  Future<Result<GroundTruth>> redo({
    required String sessionId,
    required int frameNumber,
  });

  Future<Result<Annotation>> approveAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
    String reviewer = 'researcher',
    String? comment,
  });

  Future<Result<Annotation>> rejectAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
    String reviewer = 'researcher',
    String? reason,
  });

  Future<Result<bool>> canUndo({
    required String sessionId,
    required int frameNumber,
  });

  Future<Result<bool>> canRedo({
    required String sessionId,
    required int frameNumber,
  });

  Future<Result<AnnotationQualityMetrics>> qualityMetrics(String sessionId);

  /// Seeds an editable AI suggestion (accept/reject/modify later).
  Future<Result<Annotation>> acceptAiDetection(Annotation suggestion);

  Future<Result<void>> rejectAiDetection({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  });

  /// Copies an annotation with a new id (manual / AI clone).
  Future<Result<Annotation>> duplicateAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  });

  /// Merges two bounding boxes into one AABB under [primaryId]'s label.
  Future<Result<Annotation>> mergeAnnotations({
    required String sessionId,
    required int frameNumber,
    required String primaryId,
    required String secondaryId,
  });

  /// Splits a bounding box into left / right halves.
  Future<Result<List<Annotation>>> splitAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  });

  /// All persisted ground-truth frames for a session (bulk offline eval).
  Future<Result<List<GroundTruth>>> loadSessionGroundTruth(String sessionId);
}
