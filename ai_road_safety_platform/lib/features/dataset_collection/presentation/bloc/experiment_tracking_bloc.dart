import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/experiment_tracking_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/experiment_tracking_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/experiment_tracking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'experiment_tracking_event.dart';
export 'experiment_tracking_state.dart';

/// Local experiment tracking orchestration (Phase 13.3).
class ExperimentTrackingBloc
    extends Bloc<ExperimentTrackingEvent, ExperimentTrackingState> {
  final LoadExperimentTrackerUseCase _load;
  final CreateExperimentRunUseCase _create;
  final StartExperimentRunUseCase _start;
  final LogExperimentMetricUseCase _logMetric;
  final CompleteExperimentRunUseCase _complete;
  final FailExperimentRunUseCase _fail;
  final CancelExperimentRunUseCase _cancel;
  final DeleteExperimentRunUseCase _delete;
  final CreateDemoExperimentRunUseCase _demo;
  final AppLogger _logger;

  ExperimentTrackingBloc({
    required LoadExperimentTrackerUseCase loadExperimentTracker,
    required CreateExperimentRunUseCase createExperimentRun,
    required StartExperimentRunUseCase startExperimentRun,
    required LogExperimentMetricUseCase logExperimentMetric,
    required CompleteExperimentRunUseCase completeExperimentRun,
    required FailExperimentRunUseCase failExperimentRun,
    required CancelExperimentRunUseCase cancelExperimentRun,
    required DeleteExperimentRunUseCase deleteExperimentRun,
    required CreateDemoExperimentRunUseCase createDemoExperimentRun,
    required AppLogger logger,
  })  : _load = loadExperimentTracker,
        _create = createExperimentRun,
        _start = startExperimentRun,
        _logMetric = logExperimentMetric,
        _complete = completeExperimentRun,
        _fail = failExperimentRun,
        _cancel = cancelExperimentRun,
        _delete = deleteExperimentRun,
        _demo = createDemoExperimentRun,
        _logger = logger,
        super(const ExperimentTrackingInitial()) {
    on<ExperimentTrackingLoad>(_onLoad);
    on<ExperimentTrackingRefresh>(_onLoad);
    on<ExperimentTrackingCreateDraft>(_onCreateDraft);
    on<ExperimentTrackingStart>(_onStart);
    on<ExperimentTrackingLogMetric>(_onLogMetric);
    on<ExperimentTrackingComplete>(_onComplete);
    on<ExperimentTrackingFail>(_onFail);
    on<ExperimentTrackingCancel>(_onCancel);
    on<ExperimentTrackingDelete>(_onDelete);
    on<ExperimentTrackingCreateDemo>(_onDemo);
  }

  Future<void> _onLoad(
    ExperimentTrackingEvent event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading());
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(ExperimentTrackingLoaded(snapshot: snap)),
      onErr: (f) => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onCreateDraft(
    ExperimentTrackingCreateDraft event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Creating run…'));
    final result = await _create(
      CreateExperimentRunParams(
        name: event.name,
        experimentName: event.experimentName,
        modelId: event.modelId,
        params: event.params,
      ),
    );
    await result.fold(
      onOk: (run) async {
        _logger.info('Created run ${run.id}', tag: 'ExperimentBloc');
        await _reload(emit, message: 'Created ${run.displayName}');
      },
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onStart(
    ExperimentTrackingStart event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Starting run…'));
    final result = await _start(ExperimentRunIdParams(event.runId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Run started'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onLogMetric(
    ExperimentTrackingLogMetric event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Logging metric…'));
    final result = await _logMetric(
      LogExperimentMetricParams(
        runId: event.runId,
        key: event.key,
        value: event.value,
        step: event.step,
      ),
    );
    await result.fold(
      onOk: (_) async =>
          _reload(emit, message: 'Logged ${event.key}=${event.value}'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onComplete(
    ExperimentTrackingComplete event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Completing…'));
    final result = await _complete(ExperimentRunIdParams(event.runId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Run completed'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onFail(
    ExperimentTrackingFail event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Failing run…'));
    final result = await _fail(FailExperimentRunParams(event.runId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Run marked failed'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onCancel(
    ExperimentTrackingCancel event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Cancelling…'));
    final result = await _cancel(ExperimentRunIdParams(event.runId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Run cancelled'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onDelete(
    ExperimentTrackingDelete event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Deleting…'));
    final result = await _delete(ExperimentRunIdParams(event.runId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Run deleted'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _onDemo(
    ExperimentTrackingCreateDemo event,
    Emitter<ExperimentTrackingState> emit,
  ) async {
    emit(const ExperimentTrackingLoading(message: 'Creating demo run…'));
    final result = await _demo(const NoParams());
    await result.fold(
      onOk: (run) async =>
          _reload(emit, message: 'Demo run · ${run.displayName}'),
      onErr: (f) async => emit(ExperimentTrackingError(failure: f)),
    );
  }

  Future<void> _reload(
    Emitter<ExperimentTrackingState> emit, {
    String? message,
  }) async {
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        ExperimentTrackingLoaded(snapshot: snap, statusMessage: message),
      ),
      onErr: (f) => emit(ExperimentTrackingError(failure: f)),
    );
  }
}
