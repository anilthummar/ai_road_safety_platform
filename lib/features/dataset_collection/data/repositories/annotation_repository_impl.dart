import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/annotation_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/annotation_geometry.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:uuid/uuid.dart';

class LabelRepositoryImpl implements LabelRepository {
  final AnnotationLocalDataSource _local;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;

  LabelRepositoryImpl({
    required AnnotationLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
    required AppLogger logger,
  })  : _local = localDataSource,
        _errorHandler = errorHandler,
        _logger = logger;

  @override
  Future<Result<List<AnnotationLabel>>> getLabels() => _guard(_local.loadLabels);

  @override
  Future<Result<AnnotationLabel>> addLabel(AnnotationLabel label) {
    return _guard(() async {
      final labels = await _local.loadLabels();
      if (labels.any((l) => l.id == label.id)) {
        throw const CacheException(message: 'Label id already exists');
      }
      final next = [...labels, label];
      await _local.saveLabels(next);
      _logger.info('Label added ${label.id}', tag: 'Annotation');
      return label;
    });
  }

  @override
  Future<Result<AnnotationLabel>> updateLabel(AnnotationLabel label) {
    return _guard(() async {
      final labels = await _local.loadLabels();
      final idx = labels.indexWhere((l) => l.id == label.id);
      if (idx < 0) throw const CacheException(message: 'Label not found');
      final next = [...labels]..[idx] = label;
      await _local.saveLabels(next);
      return label;
    });
  }

  @override
  Future<Result<void>> deleteLabel(String id) {
    return _guard(() async {
      final labels = await _local.loadLabels();
      await _local.saveLabels(labels.where((l) => l.id != id).toList());
    });
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}

/// In-memory undo / redo stacks keyed by session+frame.
class AnnotationRepositoryImpl implements AnnotationRepository {
  final AnnotationLocalDataSource _local;
  final DatasetFileManager _files;
  final AnnotationValidator _validator;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  final Map<String, List<GroundTruth>> _undo = {};
  final Map<String, List<GroundTruth>> _redo = {};

  AnnotationRepositoryImpl({
    required AnnotationLocalDataSource localDataSource,
    required DatasetFileManager fileManager,
    required AnnotationValidator validator,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _local = localDataSource,
        _files = fileManager,
        _validator = validator,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  String _key(String sessionId, int frame) => '$sessionId#$frame';

  @override
  Future<Result<List<AnnotatableFrame>>> listFrames(String sessionId) {
    return _guard(() => _local.listFrames(sessionId));
  }

  @override
  Future<Result<GroundTruth>> loadAnnotations({
    required String sessionId,
    required int frameNumber,
  }) =>
      getGroundTruth(sessionId: sessionId, frameNumber: frameNumber);

  @override
  Future<Result<GroundTruth>> getGroundTruth({
    required String sessionId,
    required int frameNumber,
  }) {
    return _guard(() async {
      await _files.ensureRootLayout();
      final existing = await _local.loadGroundTruth(
        sessionId: sessionId,
        frameNumber: frameNumber,
      );
      if (existing != null) return existing;

      final imagePath =
          '${_files.paths.imagesOriginal(sessionId)}/${DatasetPaths.originalFileName(frameNumber)}';
      final hasImage = await _files.exists(imagePath);
      return GroundTruth(
        sessionId: sessionId,
        frameNumber: frameNumber,
        imagePath: hasImage ? imagePath : null,
        annotations: const [],
        history: const [],
        frameStatus: AnnotationStatus.unannotated,
        updatedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<Result<Annotation>> saveAnnotation(Annotation annotation) {
    return _guard(() async {
      final gt = await _requireGt(annotation.sessionId, annotation.frameNumber);
      _pushUndo(gt);
      await _validateOrThrow(annotation, gt);
      final now = DateTime.now().toUtc();
      final saved = annotation.copyWith(
        id: annotation.id.isEmpty ? _uuid.v4() : annotation.id,
        createdAt: annotation.createdAt.millisecondsSinceEpoch == 0
            ? now
            : annotation.createdAt,
        updatedAt: now,
        status: annotation.status == AnnotationStatus.unannotated
            ? AnnotationStatus.draft
            : annotation.status,
      );
      final history = [
        ...gt.history,
        AnnotationHistoryEntry(
          id: _uuid.v4(),
          annotationId: saved.id,
          action: AnnotationHistoryAction.created,
          reviewer: saved.createdBy,
          timestamp: now,
          version: saved.version,
          snapshot: saved.toJson(),
        ),
      ];
      final annotations = [...gt.annotations, saved];
      final next = gt.copyWith(
        annotations: annotations,
        history: history,
        frameStatus: _deriveFrameStatus(annotations),
        updatedAt: now,
        imagePath: gt.imagePath ??
            '${_files.paths.imagesOriginal(gt.sessionId)}/${DatasetPaths.originalFileName(gt.frameNumber)}',
      );
      await _local.saveGroundTruth(next);
      _clearRedo(gt.sessionId, gt.frameNumber);
      _logger.info('Annotation Created ${saved.id}', tag: 'Annotation');
      return saved;
    });
  }

  @override
  Future<Result<Annotation>> updateAnnotation(Annotation annotation) {
    return _guard(() async {
      final gt = await _requireGt(annotation.sessionId, annotation.frameNumber);
      _pushUndo(gt);
      await _validateOrThrow(annotation, gt);
      final now = DateTime.now().toUtc();
      final updated = annotation.copyWith(
        updatedAt: now,
        version: annotation.version + 1,
      );
      final annotations = [
        for (final a in gt.annotations)
          if (a.id == updated.id) updated else a,
      ];
      if (!annotations.any((a) => a.id == updated.id)) {
        throw const CacheException(message: 'Annotation not found');
      }
      final next = gt.copyWith(
        annotations: annotations,
        history: [
          ...gt.history,
          AnnotationHistoryEntry(
            id: _uuid.v4(),
            annotationId: updated.id,
            action: AnnotationHistoryAction.modified,
            reviewer: updated.createdBy,
            timestamp: now,
            version: updated.version,
            snapshot: updated.toJson(),
          ),
        ],
        frameStatus: _deriveFrameStatus(annotations),
        updatedAt: now,
      );
      await _local.saveGroundTruth(next);
      _clearRedo(gt.sessionId, gt.frameNumber);
      _logger.info('Annotation Updated ${updated.id}', tag: 'Annotation');
      return updated;
    });
  }

  @override
  Future<Result<void>> deleteAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  }) {
    return _guard(() async {
      final gt = await _requireGt(sessionId, frameNumber);
      _pushUndo(gt);
      final target = gt.annotations.where((a) => a.id == annotationId);
      if (target.isEmpty) {
        throw const CacheException(message: 'Annotation not found');
      }
      final now = DateTime.now().toUtc();
      final annotations =
          gt.annotations.where((a) => a.id != annotationId).toList();
      final next = gt.copyWith(
        annotations: annotations,
        history: [
          ...gt.history,
          AnnotationHistoryEntry(
            id: _uuid.v4(),
            annotationId: annotationId,
            action: AnnotationHistoryAction.deleted,
            reviewer: 'researcher',
            timestamp: now,
            version: target.first.version,
            snapshot: target.first.toJson(),
          ),
        ],
        frameStatus: _deriveFrameStatus(annotations),
        updatedAt: now,
      );
      await _local.saveGroundTruth(next);
      _clearRedo(sessionId, frameNumber);
      _logger.info('Annotation Deleted $annotationId', tag: 'Annotation');
    });
  }

  @override
  Future<Result<GroundTruth>> undo({
    required String sessionId,
    required int frameNumber,
  }) {
    return _guard(() async {
      final key = _key(sessionId, frameNumber);
      final stack = _undo[key];
      if (stack == null || stack.isEmpty) {
        throw const CacheException(message: 'Nothing to undo');
      }
      final current = await _requireGt(sessionId, frameNumber);
      (_redo[key] ??= []).add(current);
      final previous = stack.removeLast();
      await _local.saveGroundTruth(previous);
      _logger.info('Undo', tag: 'Annotation');
      return previous;
    });
  }

  @override
  Future<Result<GroundTruth>> redo({
    required String sessionId,
    required int frameNumber,
  }) {
    return _guard(() async {
      final key = _key(sessionId, frameNumber);
      final stack = _redo[key];
      if (stack == null || stack.isEmpty) {
        throw const CacheException(message: 'Nothing to redo');
      }
      final current = await _requireGt(sessionId, frameNumber);
      (_undo[key] ??= []).add(current);
      final next = stack.removeLast();
      await _local.saveGroundTruth(next);
      _logger.info('Redo', tag: 'Annotation');
      return next;
    });
  }

  @override
  Future<Result<Annotation>> approveAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
    String reviewer = 'researcher',
    String? comment,
  }) {
    return _guard(() async {
      final gt = await _requireGt(sessionId, frameNumber);
      _pushUndo(gt);
      final idx = gt.annotations.indexWhere((a) => a.id == annotationId);
      if (idx < 0) throw const CacheException(message: 'Annotation not found');
      final now = DateTime.now().toUtc();
      final approved = gt.annotations[idx].copyWith(
        status: AnnotationStatus.approved,
        updatedAt: now,
        version: gt.annotations[idx].version + 1,
        reviewComment: comment,
      );
      final annotations = [...gt.annotations]..[idx] = approved;
      final reviewers = {...gt.reviewers, reviewer}.toList();
      final next = gt.copyWith(
        annotations: annotations,
        reviewers: reviewers,
        history: [
          ...gt.history,
          AnnotationHistoryEntry(
            id: _uuid.v4(),
            annotationId: annotationId,
            action: AnnotationHistoryAction.approved,
            reviewer: reviewer,
            timestamp: now,
            version: approved.version,
            reason: comment,
          ),
        ],
        frameStatus: _deriveFrameStatus(annotations),
        updatedAt: now,
        reviewComment: comment,
      );
      await _local.saveGroundTruth(next);
      _clearRedo(sessionId, frameNumber);
      _logger.info('Approval $annotationId', tag: 'Annotation');
      return approved;
    });
  }

  @override
  Future<Result<Annotation>> rejectAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
    String reviewer = 'researcher',
    String? reason,
  }) {
    return _guard(() async {
      final gt = await _requireGt(sessionId, frameNumber);
      _pushUndo(gt);
      final idx = gt.annotations.indexWhere((a) => a.id == annotationId);
      if (idx < 0) throw const CacheException(message: 'Annotation not found');
      final now = DateTime.now().toUtc();
      final rejected = gt.annotations[idx].copyWith(
        status: AnnotationStatus.rejected,
        updatedAt: now,
        version: gt.annotations[idx].version + 1,
        reviewComment: reason,
      );
      final annotations = [...gt.annotations]..[idx] = rejected;
      final next = gt.copyWith(
        annotations: annotations,
        reviewers: {...gt.reviewers, reviewer}.toList(),
        history: [
          ...gt.history,
          AnnotationHistoryEntry(
            id: _uuid.v4(),
            annotationId: annotationId,
            action: AnnotationHistoryAction.rejected,
            reviewer: reviewer,
            timestamp: now,
            version: rejected.version,
            reason: reason,
          ),
        ],
        frameStatus: AnnotationStatus.needsReview,
        updatedAt: now,
      );
      await _local.saveGroundTruth(next);
      _clearRedo(sessionId, frameNumber);
      _logger.info('Rejection $annotationId', tag: 'Annotation');
      return rejected;
    });
  }

  @override
  Future<Result<bool>> canUndo({
    required String sessionId,
    required int frameNumber,
  }) async {
    final stack = _undo[_key(sessionId, frameNumber)];
    return Ok(stack != null && stack.isNotEmpty);
  }

  @override
  Future<Result<bool>> canRedo({
    required String sessionId,
    required int frameNumber,
  }) async {
    final stack = _redo[_key(sessionId, frameNumber)];
    return Ok(stack != null && stack.isNotEmpty);
  }

  @override
  Future<Result<AnnotationQualityMetrics>> qualityMetrics(String sessionId) {
    return _guard(() async {
      final frames = await _local.listFrames(sessionId);
      if (frames.isEmpty) return const AnnotationQualityMetrics.empty();
      final annotated =
          frames.where((f) => f.annotationCount > 0).length;
      final approved =
          frames.where((f) => f.status == AnnotationStatus.approved).length;
      var missing = 0;
      final allGt = await _local.loadAllGroundTruth(sessionId);
      for (final gt in allGt) {
        missing += gt.annotations.where((a) => a.labelId.isEmpty).length;
      }
      final completeness = annotated / frames.length;
      final approval = approved / frames.length;
      final quality =
          ((completeness * 0.6) + (approval * 0.4)) * 100 -
              (missing * 2);
      return AnnotationQualityMetrics(
        totalFrames: frames.length,
        annotatedFrames: annotated,
        approvedFrames: approved,
        missingLabelCount: missing,
        completeness: completeness,
        approvalPercentage: approval * 100,
        qualityScore: quality.clamp(0, 100),
      );
    });
  }

  @override
  Future<Result<Annotation>> acceptAiDetection(Annotation suggestion) {
    return saveAnnotation(
      suggestion.copyWith(
        fromAi: true,
        status: AnnotationStatus.draft,
      ),
    );
  }

  @override
  Future<Result<void>> rejectAiDetection({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  }) {
    return deleteAnnotation(
      sessionId: sessionId,
      frameNumber: frameNumber,
      annotationId: annotationId,
    );
  }

  @override
  Future<Result<Annotation>> duplicateAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  }) {
    return _guard(() async {
      final gt = await _requireGt(sessionId, frameNumber);
      final source = gt.annotations.where((a) => a.id == annotationId);
      if (source.isEmpty) {
        throw const CacheException(message: 'Annotation not found');
      }
      final now = DateTime.now().toUtc();
      var clone = source.first.copyWith(
        id: _uuid.v4(),
        status: AnnotationStatus.draft,
        fromAi: false,
        createdAt: now,
        updatedAt: now,
        version: 1,
        clearComment: true,
      );
      // Nudge geometry so duplicate validation does not reject a clone.
      if (clone.box != null) {
        final b = clone.box!;
        clone = clone.copyWith(
          box: BoundingBox(
            x: (b.x + 0.02).clamp(0.0, 0.95),
            y: (b.y + 0.02).clamp(0.0, 0.95),
            width: b.width,
            height: b.height,
          ),
        );
      }
      return (await saveAnnotation(clone)).fold(
        onOk: (v) => v,
        onErr: (f) => throw CacheException(message: f.message),
      );
    });
  }

  @override
  Future<Result<Annotation>> mergeAnnotations({
    required String sessionId,
    required int frameNumber,
    required String primaryId,
    required String secondaryId,
  }) {
    return _guard(() async {
      final gt = await _requireGt(sessionId, frameNumber);
      Annotation? a;
      Annotation? b;
      for (final item in gt.annotations) {
        if (item.id == primaryId) a = item;
        if (item.id == secondaryId) b = item;
      }
      if (a?.box == null || b?.box == null) {
        throw const CacheException(
          message: 'Merge requires two bounding boxes',
        );
      }
      final ax = a!.box!;
      final bx = b!.box!;
      final x0 = ax.x < bx.x ? ax.x : bx.x;
      final y0 = ax.y < bx.y ? ax.y : bx.y;
      final x1 = ax.right > bx.right ? ax.right : bx.right;
      final y1 = ax.bottom > bx.bottom ? ax.bottom : bx.bottom;
      final merged = a.copyWith(
        box: BoundingBox(
          x: x0,
          y: y0,
          width: x1 - x0,
          height: y1 - y0,
        ),
        updatedAt: DateTime.now().toUtc(),
        status: AnnotationStatus.draft,
      );
      await deleteAnnotation(
        sessionId: sessionId,
        frameNumber: frameNumber,
        annotationId: secondaryId,
      );
      return (await updateAnnotation(merged)).fold(
        onOk: (v) => v,
        onErr: (f) => throw CacheException(message: f.message),
      );
    });
  }

  @override
  Future<Result<List<Annotation>>> splitAnnotation({
    required String sessionId,
    required int frameNumber,
    required String annotationId,
  }) {
    return _guard(() async {
      final gt = await _requireGt(sessionId, frameNumber);
      final source = gt.annotations.where((a) => a.id == annotationId);
      if (source.isEmpty || source.first.box == null) {
        throw const CacheException(message: 'Split requires a bounding box');
      }
      final original = source.first;
      final box = original.box!;
      final half = box.width / 2;
      final now = DateTime.now().toUtc();
      final left = original.copyWith(
        id: _uuid.v4(),
        box: BoundingBox(x: box.x, y: box.y, width: half, height: box.height),
        status: AnnotationStatus.draft,
        createdAt: now,
        updatedAt: now,
        version: 1,
      );
      final right = original.copyWith(
        id: _uuid.v4(),
        box: BoundingBox(
          x: box.x + half,
          y: box.y,
          width: half,
          height: box.height,
        ),
        status: AnnotationStatus.draft,
        createdAt: now,
        updatedAt: now,
        version: 1,
      );
      await deleteAnnotation(
        sessionId: sessionId,
        frameNumber: frameNumber,
        annotationId: annotationId,
      );
      final a = await saveAnnotation(left);
      final b = await saveAnnotation(right);
      return [
        a.fold(
          onOk: (v) => v,
          onErr: (f) => throw CacheException(message: f.message),
        ),
        b.fold(
          onOk: (v) => v,
          onErr: (f) => throw CacheException(message: f.message),
        ),
      ];
    });
  }

  @override
  Future<Result<List<GroundTruth>>> loadSessionGroundTruth(String sessionId) {
    return _guard(() => _local.loadAllGroundTruth(sessionId));
  }

  Future<GroundTruth> _requireGt(String sessionId, int frameNumber) async {
    final result = await getGroundTruth(
      sessionId: sessionId,
      frameNumber: frameNumber,
    );
    return result.fold(
      onOk: (v) => v,
      onErr: (f) => throw CacheException(message: f.message),
    );
  }

  Future<void> _validateOrThrow(Annotation annotation, GroundTruth gt) async {
    final labels = await _local.loadLabels();
    final enabled = {
      for (final l in labels.where((e) => e.enabled)) l.id,
    };
    final issues = _validator.validateAnnotation(
      annotation,
      imageWidth: gt.imageWidth,
      imageHeight: gt.imageHeight,
      siblings: gt.annotations.where((a) => a.id != annotation.id).toList(),
      enabledLabelIds: enabled,
    );
    final blocking = issues.where(
      (i) =>
          i.code != 'overlapping_objects' &&
          i.code != 'placeholder_type' &&
          i.code != 'duplicate_annotation',
    );
    if (blocking.isNotEmpty) {
      throw CacheException(message: blocking.first.message);
    }
  }

  AnnotationStatus _deriveFrameStatus(List<Annotation> annotations) {
    if (annotations.isEmpty) return AnnotationStatus.unannotated;
    if (annotations.every((a) => a.status == AnnotationStatus.approved)) {
      return AnnotationStatus.approved;
    }
    if (annotations.any((a) => a.status == AnnotationStatus.rejected)) {
      return AnnotationStatus.needsReview;
    }
    if (annotations.any((a) => a.status == AnnotationStatus.reviewed)) {
      return AnnotationStatus.reviewed;
    }
    return AnnotationStatus.draft;
  }

  void _pushUndo(GroundTruth gt) {
    final key = _key(gt.sessionId, gt.frameNumber);
    final stack = _undo[key] ??= [];
    stack.add(gt);
    if (stack.length > 40) stack.removeAt(0);
  }

  void _clearRedo(String sessionId, int frameNumber) {
    _redo.remove(_key(sessionId, frameNumber));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
