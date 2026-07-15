import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:equatable/equatable.dart';

class FrameKeyParams extends Equatable {
  final String sessionId;
  final int frameNumber;

  const FrameKeyParams({required this.sessionId, required this.frameNumber});

  @override
  List<Object?> get props => [sessionId, frameNumber];
}

class CreateAnnotationUseCase
    extends UseCase<Result<Annotation>, Annotation> {
  final AnnotationRepository _repository;
  CreateAnnotationUseCase(this._repository);

  @override
  Future<Result<Annotation>> call(Annotation params) =>
      _repository.saveAnnotation(params);
}

class UpdateAnnotationUseCase
    extends UseCase<Result<Annotation>, Annotation> {
  final AnnotationRepository _repository;
  UpdateAnnotationUseCase(this._repository);

  @override
  Future<Result<Annotation>> call(Annotation params) =>
      _repository.updateAnnotation(params);
}

class DeleteAnnotationParams extends Equatable {
  final String sessionId;
  final int frameNumber;
  final String annotationId;

  const DeleteAnnotationParams({
    required this.sessionId,
    required this.frameNumber,
    required this.annotationId,
  });

  @override
  List<Object?> get props => [sessionId, frameNumber, annotationId];
}

class DeleteAnnotationUseCase
    extends UseCase<Result<void>, DeleteAnnotationParams> {
  final AnnotationRepository _repository;
  DeleteAnnotationUseCase(this._repository);

  @override
  Future<Result<void>> call(DeleteAnnotationParams params) =>
      _repository.deleteAnnotation(
        sessionId: params.sessionId,
        frameNumber: params.frameNumber,
        annotationId: params.annotationId,
      );
}

class UndoAnnotationUseCase
    extends UseCase<Result<GroundTruth>, FrameKeyParams> {
  final AnnotationRepository _repository;
  UndoAnnotationUseCase(this._repository);

  @override
  Future<Result<GroundTruth>> call(FrameKeyParams params) =>
      _repository.undo(
        sessionId: params.sessionId,
        frameNumber: params.frameNumber,
      );
}

class RedoAnnotationUseCase
    extends UseCase<Result<GroundTruth>, FrameKeyParams> {
  final AnnotationRepository _repository;
  RedoAnnotationUseCase(this._repository);

  @override
  Future<Result<GroundTruth>> call(FrameKeyParams params) =>
      _repository.redo(
        sessionId: params.sessionId,
        frameNumber: params.frameNumber,
      );
}

class ReviewAnnotationParams extends Equatable {
  final String sessionId;
  final int frameNumber;
  final String annotationId;
  final String reviewer;
  final String? comment;

  const ReviewAnnotationParams({
    required this.sessionId,
    required this.frameNumber,
    required this.annotationId,
    this.reviewer = 'researcher',
    this.comment,
  });

  @override
  List<Object?> get props =>
      [sessionId, frameNumber, annotationId, reviewer, comment];
}

class ApproveAnnotationUseCase
    extends UseCase<Result<Annotation>, ReviewAnnotationParams> {
  final AnnotationRepository _repository;
  ApproveAnnotationUseCase(this._repository);

  @override
  Future<Result<Annotation>> call(ReviewAnnotationParams params) =>
      _repository.approveAnnotation(
        sessionId: params.sessionId,
        frameNumber: params.frameNumber,
        annotationId: params.annotationId,
        reviewer: params.reviewer,
        comment: params.comment,
      );
}

class RejectAnnotationUseCase
    extends UseCase<Result<Annotation>, ReviewAnnotationParams> {
  final AnnotationRepository _repository;
  RejectAnnotationUseCase(this._repository);

  @override
  Future<Result<Annotation>> call(ReviewAnnotationParams params) =>
      _repository.rejectAnnotation(
        sessionId: params.sessionId,
        frameNumber: params.frameNumber,
        annotationId: params.annotationId,
        reviewer: params.reviewer,
        reason: params.comment,
      );
}

class LoadGroundTruthUseCase
    extends UseCase<Result<GroundTruth>, FrameKeyParams> {
  final AnnotationRepository _repository;
  LoadGroundTruthUseCase(this._repository);

  @override
  Future<Result<GroundTruth>> call(FrameKeyParams params) =>
      _repository.getGroundTruth(
        sessionId: params.sessionId,
        frameNumber: params.frameNumber,
      );
}
