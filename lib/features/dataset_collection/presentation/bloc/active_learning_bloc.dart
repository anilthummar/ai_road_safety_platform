import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/active_learning_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/active_learning_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/active_learning_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'active_learning_event.dart';
export 'active_learning_state.dart';

/// Active learning / smart sample selection orchestration (Phase 13.5).
class ActiveLearningBloc
    extends Bloc<ActiveLearningEvent, ActiveLearningState> {
  final LoadActiveLearningSnapshotUseCase _load;
  final RunActiveLearningSelectionUseCase _run;
  final DeleteActiveLearningSelectionUseCase _delete;
  final CreateDemoActiveLearningUseCase _demo;
  final AppLogger _logger;

  ActiveLearningBloc({
    required LoadActiveLearningSnapshotUseCase loadActiveLearningSnapshot,
    required RunActiveLearningSelectionUseCase runActiveLearningSelection,
    required DeleteActiveLearningSelectionUseCase deleteActiveLearningSelection,
    required CreateDemoActiveLearningUseCase createDemoActiveLearning,
    required AppLogger logger,
  })  : _load = loadActiveLearningSnapshot,
        _run = runActiveLearningSelection,
        _delete = deleteActiveLearningSelection,
        _demo = createDemoActiveLearning,
        _logger = logger,
        super(const ActiveLearningInitial()) {
    on<ActiveLearningLoad>(_onLoad);
    on<ActiveLearningRefresh>(_onLoad);
    on<ActiveLearningRun>(_onRun);
    on<ActiveLearningDelete>(_onDelete);
    on<ActiveLearningCreateDemo>(_onDemo);
  }

  Future<void> _onLoad(
    ActiveLearningEvent event,
    Emitter<ActiveLearningState> emit,
  ) async {
    emit(const ActiveLearningLoading());
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(ActiveLearningLoaded(snapshot: snap)),
      onErr: (f) => emit(ActiveLearningError(failure: f)),
    );
  }

  Future<void> _onRun(
    ActiveLearningRun event,
    Emitter<ActiveLearningState> emit,
  ) async {
    emit(const ActiveLearningLoading(message: 'Ranking samples…'));
    final result = await _run(
      RunActiveLearningParams(
        sessionIds: event.sessionIds,
        config: event.config,
      ),
    );
    await result.fold(
      onOk: (sel) async {
        _logger.info('Selection ${sel.id}', tag: 'ActiveLearningBloc');
        await _reload(
          emit,
          message:
              'Selected ${sel.selectedCount} / ${sel.framesConsidered} frames'
              '${sel.candidates.isEmpty ? '' : ' · top ${sel.topScore.toStringAsFixed(0)}'}',
        );
      },
      onErr: (f) async => emit(ActiveLearningError(failure: f)),
    );
  }

  Future<void> _onDelete(
    ActiveLearningDelete event,
    Emitter<ActiveLearningState> emit,
  ) async {
    emit(const ActiveLearningLoading(message: 'Deleting…'));
    final result =
        await _delete(DeleteActiveLearningParams(event.selectionId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Selection deleted'),
      onErr: (f) async => emit(ActiveLearningError(failure: f)),
    );
  }

  Future<void> _onDemo(
    ActiveLearningCreateDemo event,
    Emitter<ActiveLearningState> emit,
  ) async {
    emit(const ActiveLearningLoading(message: 'Creating demo selection…'));
    final result = await _demo(const NoParams());
    await result.fold(
      onOk: (sel) async => _reload(
        emit,
        message: 'Demo · ${sel.selectedCount} priority frames',
      ),
      onErr: (f) async => emit(ActiveLearningError(failure: f)),
    );
  }

  Future<void> _reload(
    Emitter<ActiveLearningState> emit, {
    String? message,
  }) async {
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        ActiveLearningLoaded(snapshot: snap, statusMessage: message),
      ),
      onErr: (f) => emit(ActiveLearningError(failure: f)),
    );
  }
}
