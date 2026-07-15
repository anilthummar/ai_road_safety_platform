import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/annotation_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'annotation_event.dart';
export 'annotation_state.dart';

/// Annotation workspace orchestration (Phase 12.9).
class AnnotationBloc extends Bloc<AnnotationEvent, AnnotationState> {
  final AnnotationRepository _repository;
  final LabelRepository _labels;
  final CreateAnnotationUseCase _create;
  final UpdateAnnotationUseCase _update;
  final DeleteAnnotationUseCase _delete;
  final UndoAnnotationUseCase _undo;
  final RedoAnnotationUseCase _redo;
  final ApproveAnnotationUseCase _approve;
  final RejectAnnotationUseCase _reject;
  final LoadGroundTruthUseCase _loadGt;
  final AppLogger _logger;

  AnnotationBloc({
    required AnnotationRepository repository,
    required LabelRepository labelRepository,
    required CreateAnnotationUseCase createAnnotation,
    required UpdateAnnotationUseCase updateAnnotation,
    required DeleteAnnotationUseCase deleteAnnotation,
    required UndoAnnotationUseCase undoAnnotation,
    required RedoAnnotationUseCase redoAnnotation,
    required ApproveAnnotationUseCase approveAnnotation,
    required RejectAnnotationUseCase rejectAnnotation,
    required LoadGroundTruthUseCase loadGroundTruth,
    required AppLogger logger,
  })  : _repository = repository,
        _labels = labelRepository,
        _create = createAnnotation,
        _update = updateAnnotation,
        _delete = deleteAnnotation,
        _undo = undoAnnotation,
        _redo = redoAnnotation,
        _approve = approveAnnotation,
        _reject = rejectAnnotation,
        _loadGt = loadGroundTruth,
        _logger = logger,
        super(const AnnotationInitial()) {
    on<AnnotationLoadSession>(_onLoadSession);
    on<AnnotationLoadImage>(_onLoadImage);
    on<AnnotationCreate>(_onCreate);
    on<AnnotationUpdate>(_onUpdate);
    on<AnnotationDelete>(_onDelete);
    on<AnnotationUndo>(_onUndo);
    on<AnnotationRedo>(_onRedo);
    on<AnnotationApprove>(_onApprove);
    on<AnnotationReject>(_onReject);
    on<AnnotationSelectTool>(_onSelectTool);
    on<AnnotationSelectLabel>(_onSelectLabel);
    on<AnnotationSelectAnnotation>(_onSelectAnnotation);
    on<AnnotationSetZoom>(_onZoom);
    on<AnnotationSetPan>(_onPan);
    on<AnnotationFitToScreen>(_onFit);
    on<AnnotationAcceptAi>(_onAcceptAi);
    on<AnnotationDuplicate>(_onDuplicate);
    on<AnnotationMerge>(_onMerge);
    on<AnnotationSplit>(_onSplit);
    on<AnnotationLoadLabels>(_onLoadLabels);
  }

  Future<void> _onLoadSession(
    AnnotationLoadSession event,
    Emitter<AnnotationState> emit,
  ) async {
    emit(const AnnotationLoading(message: 'Loading session frames…'));
    final labelsResult = await _labels.getLabels();
    final framesResult = await _repository.listFrames(event.sessionId);
    final qualityResult = await _repository.qualityMetrics(event.sessionId);

    Failure? failure;
    var labels = DefaultHazardLabels.all;
    var frames = <AnnotatableFrame>[];
    var quality = const AnnotationQualityMetrics.empty();

    labelsResult.fold(
      onOk: (v) => labels = v,
      onErr: (f) => failure = f,
    );
    framesResult.fold(
      onOk: (v) => frames = v,
      onErr: (f) => failure = f,
    );
    qualityResult.fold(onOk: (v) => quality = v, onErr: (_) {});

    if (failure != null) {
      emit(AnnotationError(failure!));
      return;
    }
    if (frames.isEmpty) {
      emit(
        AnnotationEditing(
          sessionId: event.sessionId,
          frames: const [],
          groundTruth: GroundTruth(
            sessionId: event.sessionId,
            frameNumber: 0,
            annotations: const [],
            history: const [],
            frameStatus: AnnotationStatus.unannotated,
            updatedAt: DateTime.now().toUtc(),
          ),
          labels: labels,
          tool: AnnotationTool.select,
          selectedLabelId: labels.first.id,
          zoom: 1,
          panX: 0,
          panY: 0,
          undoAvailable: false,
          redoAvailable: false,
          quality: quality,
          statusMessage: 'No frames found for this session',
        ),
      );
      return;
    }

    final first = frames.first;
    final gtResult = await _loadGt(
      FrameKeyParams(sessionId: first.sessionId, frameNumber: first.frameNumber),
    );
    await gtResult.fold(
      onOk: (gt) async {
        final undo = await _repository.canUndo(
          sessionId: first.sessionId,
          frameNumber: first.frameNumber,
        );
        final redo = await _repository.canRedo(
          sessionId: first.sessionId,
          frameNumber: first.frameNumber,
        );
        emit(
          AnnotationEditing(
            sessionId: event.sessionId,
            frames: frames,
            groundTruth: gt,
            labels: labels,
            tool: AnnotationTool.boundingBox,
            selectedLabelId: labels.first.id,
            zoom: 1,
            panX: 0,
            panY: 0,
            undoAvailable: undo.fold(onOk: (v) => v, onErr: (_) => false),
            redoAvailable: redo.fold(onOk: (v) => v, onErr: (_) => false),
            quality: quality,
          ),
        );
      },
      onErr: (f) async => emit(AnnotationError(f)),
    );
  }

  Future<void> _onLoadImage(
    AnnotationLoadImage event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = state;
    if (current is! AnnotationEditing) return;
    emit(const AnnotationLoading(message: 'Loading frame…'));
    final gtResult = await _loadGt(
      FrameKeyParams(
        sessionId: event.sessionId,
        frameNumber: event.frameNumber,
      ),
    );
    await gtResult.fold(
      onOk: (gt) async {
        final flags = await _undoRedo(event.sessionId, event.frameNumber);
        emit(
          current.copyWith(
            groundTruth: gt,
            clearSelection: true,
            zoom: 1,
            panX: 0,
            panY: 0,
            undoAvailable: flags.$1,
            redoAvailable: flags.$2,
            clearStatus: true,
          ),
        );
      },
      onErr: (f) async => emit(AnnotationError(f, snapshot: current)),
    );
  }

  Future<void> _onCreate(
    AnnotationCreate event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _create(event.annotation);
    await _reloadAfterMutation(emit, current, result.isOk, result.isErr
        ? result.fold(onOk: (_) => null, onErr: (f) => f)
        : null);
    if (result.isOk) {
      _logger.info('Annotation Created', tag: 'AnnotationBloc');
    }
  }

  Future<void> _onUpdate(
    AnnotationUpdate event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _update(event.annotation);
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
    );
    if (result.isOk) {
      _logger.info('Annotation Updated', tag: 'AnnotationBloc');
    }
  }

  Future<void> _onDelete(
    AnnotationDelete event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _delete(
      DeleteAnnotationParams(
        sessionId: current.groundTruth.sessionId,
        frameNumber: current.groundTruth.frameNumber,
        annotationId: event.annotationId,
      ),
    );
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
    );
    if (result.isOk) {
      _logger.info('Annotation Deleted', tag: 'AnnotationBloc');
    }
  }

  Future<void> _onUndo(
    AnnotationUndo event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    final result = await _undo(
      FrameKeyParams(
        sessionId: current.groundTruth.sessionId,
        frameNumber: current.groundTruth.frameNumber,
      ),
    );
    await result.fold(
      onOk: (gt) async {
        final flags = await _undoRedo(gt.sessionId, gt.frameNumber);
        _logger.info('Undo', tag: 'AnnotationBloc');
        emit(
          current.copyWith(
            groundTruth: gt,
            undoAvailable: flags.$1,
            redoAvailable: flags.$2,
            statusMessage: 'Undid last change',
          ),
        );
      },
      onErr: (f) async => emit(AnnotationError(f, snapshot: current)),
    );
  }

  Future<void> _onRedo(
    AnnotationRedo event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    final result = await _redo(
      FrameKeyParams(
        sessionId: current.groundTruth.sessionId,
        frameNumber: current.groundTruth.frameNumber,
      ),
    );
    await result.fold(
      onOk: (gt) async {
        final flags = await _undoRedo(gt.sessionId, gt.frameNumber);
        _logger.info('Redo', tag: 'AnnotationBloc');
        emit(
          current.copyWith(
            groundTruth: gt,
            undoAvailable: flags.$1,
            redoAvailable: flags.$2,
            statusMessage: 'Redid last change',
          ),
        );
      },
      onErr: (f) async => emit(AnnotationError(f, snapshot: current)),
    );
  }

  Future<void> _onApprove(
    AnnotationApprove event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _approve(
      ReviewAnnotationParams(
        sessionId: current.groundTruth.sessionId,
        frameNumber: current.groundTruth.frameNumber,
        annotationId: event.annotationId,
        comment: event.comment,
      ),
    );
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
      approved: true,
    );
    if (result.isOk) _logger.info('Approval', tag: 'AnnotationBloc');
  }

  Future<void> _onReject(
    AnnotationReject event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _reject(
      ReviewAnnotationParams(
        sessionId: current.groundTruth.sessionId,
        frameNumber: current.groundTruth.frameNumber,
        annotationId: event.annotationId,
        comment: event.reason,
      ),
    );
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
      rejected: true,
    );
    if (result.isOk) _logger.info('Rejection', tag: 'AnnotationBloc');
  }

  void _onSelectTool(
    AnnotationSelectTool event,
    Emitter<AnnotationState> emit,
  ) {
    final current = _editingOrNull();
    if (current == null) return;
    _logger.info('Tool Changed ${event.tool}', tag: 'AnnotationBloc');
    emit(current.copyWith(tool: event.tool));
  }

  void _onSelectLabel(
    AnnotationSelectLabel event,
    Emitter<AnnotationState> emit,
  ) {
    final current = _editingOrNull();
    if (current == null) return;
    emit(current.copyWith(selectedLabelId: event.labelId));
  }

  void _onSelectAnnotation(
    AnnotationSelectAnnotation event,
    Emitter<AnnotationState> emit,
  ) {
    final current = _editingOrNull();
    if (current == null) return;
    emit(
      current.copyWith(
        selectedAnnotationId: event.annotationId,
        clearSelection: event.annotationId == null,
      ),
    );
  }

  void _onZoom(AnnotationSetZoom event, Emitter<AnnotationState> emit) {
    final current = _editingOrNull();
    if (current == null) return;
    emit(current.copyWith(zoom: event.zoom.clamp(0.25, 8.0)));
  }

  void _onPan(AnnotationSetPan event, Emitter<AnnotationState> emit) {
    final current = _editingOrNull();
    if (current == null) return;
    emit(current.copyWith(panX: event.panX, panY: event.panY));
  }

  void _onFit(AnnotationFitToScreen event, Emitter<AnnotationState> emit) {
    final current = _editingOrNull();
    if (current == null) return;
    emit(current.copyWith(zoom: 1, panX: 0, panY: 0));
  }

  Future<void> _onAcceptAi(
    AnnotationAcceptAi event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _repository.acceptAiDetection(event.suggestion);
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
    );
  }

  Future<void> _onDuplicate(
    AnnotationDuplicate event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _repository.duplicateAnnotation(
      sessionId: current.groundTruth.sessionId,
      frameNumber: current.groundTruth.frameNumber,
      annotationId: event.annotationId,
    );
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
    );
  }

  Future<void> _onMerge(
    AnnotationMerge event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _repository.mergeAnnotations(
      sessionId: current.groundTruth.sessionId,
      frameNumber: current.groundTruth.frameNumber,
      primaryId: event.primaryId,
      secondaryId: event.secondaryId,
    );
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
    );
  }

  Future<void> _onSplit(
    AnnotationSplit event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    emit(AnnotationSaving(current));
    final result = await _repository.splitAnnotation(
      sessionId: current.groundTruth.sessionId,
      frameNumber: current.groundTruth.frameNumber,
      annotationId: event.annotationId,
    );
    await _reloadAfterMutation(
      emit,
      current,
      result.isOk,
      result.isErr ? result.fold(onOk: (_) => null, onErr: (f) => f) : null,
    );
  }

  Future<void> _onLoadLabels(
    AnnotationLoadLabels event,
    Emitter<AnnotationState> emit,
  ) async {
    final current = _editingOrNull();
    if (current == null) return;
    final result = await _labels.getLabels();
    result.fold(
      onOk: (labels) => emit(current.copyWith(labels: labels)),
      onErr: (f) => emit(AnnotationError(f, snapshot: current)),
    );
  }

  AnnotationEditing? _editingOrNull() {
    final s = state;
    if (s is AnnotationEditing) return s;
    if (s is AnnotationSaving) return s.snapshot;
    if (s is AnnotationError) return s.snapshot;
    return null;
  }

  Future<(bool, bool)> _undoRedo(String sessionId, int frame) async {
    final u = await _repository.canUndo(sessionId: sessionId, frameNumber: frame);
    final r = await _repository.canRedo(sessionId: sessionId, frameNumber: frame);
    return (
      u.fold(onOk: (v) => v, onErr: (_) => false),
      r.fold(onOk: (v) => v, onErr: (_) => false),
    );
  }

  Future<void> _reloadAfterMutation(
    Emitter<AnnotationState> emit,
    AnnotationEditing current,
    bool ok,
    Failure? failure, {
    bool approved = false,
    bool rejected = false,
  }) async {
    if (!ok && failure != null) {
      emit(AnnotationError(failure, snapshot: current));
      return;
    }
    final gtResult = await _loadGt(
      FrameKeyParams(
        sessionId: current.groundTruth.sessionId,
        frameNumber: current.groundTruth.frameNumber,
      ),
    );
    final frames = await _repository.listFrames(current.sessionId);
    final quality = await _repository.qualityMetrics(current.sessionId);
    await gtResult.fold(
      onOk: (gt) async {
        final flags = await _undoRedo(gt.sessionId, gt.frameNumber);
        emit(
          current.copyWith(
            groundTruth: gt,
            frames: frames.fold(onOk: (v) => v, onErr: (_) => current.frames),
            quality: quality.fold(
              onOk: (v) => v,
              onErr: (_) => current.quality,
            ),
            undoAvailable: flags.$1,
            redoAvailable: flags.$2,
            statusMessage: approved
                ? 'Approved'
                : rejected
                    ? 'Rejected'
                    : 'Saved',
          ),
        );
      },
      onErr: (f) async => emit(AnnotationError(f, snapshot: current)),
    );
  }
}
