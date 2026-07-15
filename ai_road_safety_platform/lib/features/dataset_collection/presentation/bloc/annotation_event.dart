import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:equatable/equatable.dart';

sealed class AnnotationEvent extends Equatable {
  const AnnotationEvent();
  @override
  List<Object?> get props => [];
}

final class AnnotationLoadSession extends AnnotationEvent {
  final String sessionId;
  const AnnotationLoadSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

final class AnnotationLoadImage extends AnnotationEvent {
  final String sessionId;
  final int frameNumber;
  const AnnotationLoadImage({
    required this.sessionId,
    required this.frameNumber,
  });
  @override
  List<Object?> get props => [sessionId, frameNumber];
}

final class AnnotationCreate extends AnnotationEvent {
  final Annotation annotation;
  const AnnotationCreate(this.annotation);
  @override
  List<Object?> get props => [annotation];
}

final class AnnotationUpdate extends AnnotationEvent {
  final Annotation annotation;
  const AnnotationUpdate(this.annotation);
  @override
  List<Object?> get props => [annotation];
}

final class AnnotationDelete extends AnnotationEvent {
  final String annotationId;
  const AnnotationDelete(this.annotationId);
  @override
  List<Object?> get props => [annotationId];
}

final class AnnotationUndo extends AnnotationEvent {
  const AnnotationUndo();
}

final class AnnotationRedo extends AnnotationEvent {
  const AnnotationRedo();
}

final class AnnotationApprove extends AnnotationEvent {
  final String annotationId;
  final String? comment;
  const AnnotationApprove(this.annotationId, {this.comment});
  @override
  List<Object?> get props => [annotationId, comment];
}

final class AnnotationReject extends AnnotationEvent {
  final String annotationId;
  final String? reason;
  const AnnotationReject(this.annotationId, {this.reason});
  @override
  List<Object?> get props => [annotationId, reason];
}

final class AnnotationSelectTool extends AnnotationEvent {
  final AnnotationTool tool;
  const AnnotationSelectTool(this.tool);
  @override
  List<Object?> get props => [tool];
}

final class AnnotationSelectLabel extends AnnotationEvent {
  final String labelId;
  const AnnotationSelectLabel(this.labelId);
  @override
  List<Object?> get props => [labelId];
}

final class AnnotationSelectAnnotation extends AnnotationEvent {
  final String? annotationId;
  const AnnotationSelectAnnotation(this.annotationId);
  @override
  List<Object?> get props => [annotationId];
}

final class AnnotationSetZoom extends AnnotationEvent {
  final double zoom;
  const AnnotationSetZoom(this.zoom);
  @override
  List<Object?> get props => [zoom];
}

final class AnnotationSetPan extends AnnotationEvent {
  final double panX;
  final double panY;
  const AnnotationSetPan({required this.panX, required this.panY});
  @override
  List<Object?> get props => [panX, panY];
}

final class AnnotationFitToScreen extends AnnotationEvent {
  const AnnotationFitToScreen();
}

final class AnnotationAcceptAi extends AnnotationEvent {
  final Annotation suggestion;
  const AnnotationAcceptAi(this.suggestion);
  @override
  List<Object?> get props => [suggestion];
}

final class AnnotationDuplicate extends AnnotationEvent {
  final String annotationId;
  const AnnotationDuplicate(this.annotationId);
  @override
  List<Object?> get props => [annotationId];
}

final class AnnotationMerge extends AnnotationEvent {
  final String primaryId;
  final String secondaryId;
  const AnnotationMerge({required this.primaryId, required this.secondaryId});
  @override
  List<Object?> get props => [primaryId, secondaryId];
}

final class AnnotationSplit extends AnnotationEvent {
  final String annotationId;
  const AnnotationSplit(this.annotationId);
  @override
  List<Object?> get props => [annotationId];
}

final class AnnotationLoadLabels extends AnnotationEvent {
  const AnnotationLoadLabels();
}
