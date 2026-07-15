import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_deployment_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_deployment_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_deployment_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'model_deployment_event.dart';
export 'model_deployment_state.dart';

/// Edge package staging / activate / rollback orchestration (Phase 13.6).
class ModelDeploymentBloc
    extends Bloc<ModelDeploymentEvent, ModelDeploymentState> {
  final LoadDeploymentSnapshotUseCase _load;
  final StageDeploymentUseCase _stage;
  final ActivateDeploymentUseCase _activate;
  final RollbackDeploymentUseCase _rollback;
  final DeleteDeploymentUseCase _delete;
  final CreateDemoDeploymentUseCase _demo;
  final AppLogger _logger;

  ModelDeploymentBloc({
    required LoadDeploymentSnapshotUseCase loadDeploymentSnapshot,
    required StageDeploymentUseCase stageDeployment,
    required ActivateDeploymentUseCase activateDeployment,
    required RollbackDeploymentUseCase rollbackDeployment,
    required DeleteDeploymentUseCase deleteDeployment,
    required CreateDemoDeploymentUseCase createDemoDeployment,
    required AppLogger logger,
  })  : _load = loadDeploymentSnapshot,
        _stage = stageDeployment,
        _activate = activateDeployment,
        _rollback = rollbackDeployment,
        _delete = deleteDeployment,
        _demo = createDemoDeployment,
        _logger = logger,
        super(const ModelDeploymentInitial()) {
    on<ModelDeploymentLoad>(_onLoad);
    on<ModelDeploymentRefresh>(_onLoad);
    on<ModelDeploymentStage>(_onStage);
    on<ModelDeploymentActivate>(_onActivate);
    on<ModelDeploymentRollback>(_onRollback);
    on<ModelDeploymentDelete>(_onDelete);
    on<ModelDeploymentCreateDemo>(_onDemo);
    on<ModelDeploymentStageActiveDetection>(_onStageDetection);
  }

  Future<void> _onLoad(
    ModelDeploymentEvent event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    emit(const ModelDeploymentLoading());
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(ModelDeploymentLoaded(snapshot: snap)),
      onErr: (f) => emit(ModelDeploymentError(failure: f)),
    );
  }

  Future<void> _onStage(
    ModelDeploymentStage event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    emit(const ModelDeploymentLoading(message: 'Staging package…'));
    final result = await _stage(StageDeploymentParams(event.modelId));
    await result.fold(
      onOk: (pkg) async {
        _logger.info('Staged ${pkg.id}', tag: 'DeployBloc');
        await _reload(emit, message: 'Staged ${pkg.displayName}');
      },
      onErr: (f) async => emit(ModelDeploymentError(failure: f)),
    );
  }

  Future<void> _onStageDetection(
    ModelDeploymentStageActiveDetection event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    add(const ModelDeploymentStage('bundled-yolov8n'));
  }

  Future<void> _onActivate(
    ModelDeploymentActivate event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    emit(const ModelDeploymentLoading(message: 'Activating…'));
    final result = await _activate(DeploymentIdParams(event.deploymentId));
    await result.fold(
      onOk: (pkg) async =>
          _reload(emit, message: 'Active · ${pkg.displayName}'),
      onErr: (f) async => emit(ModelDeploymentError(failure: f)),
    );
  }

  Future<void> _onRollback(
    ModelDeploymentRollback event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    emit(const ModelDeploymentLoading(message: 'Rolling back…'));
    final result = await _rollback(DeploymentIdParams(event.deploymentId));
    await result.fold(
      onOk: (pkg) async =>
          _reload(emit, message: 'Rolled back → ${pkg.displayName}'),
      onErr: (f) async => emit(ModelDeploymentError(failure: f)),
    );
  }

  Future<void> _onDelete(
    ModelDeploymentDelete event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    emit(const ModelDeploymentLoading(message: 'Deleting…'));
    final result = await _delete(DeploymentIdParams(event.deploymentId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Package deleted'),
      onErr: (f) async => emit(ModelDeploymentError(failure: f)),
    );
  }

  Future<void> _onDemo(
    ModelDeploymentCreateDemo event,
    Emitter<ModelDeploymentState> emit,
  ) async {
    emit(const ModelDeploymentLoading(message: 'Creating demo deploy…'));
    final result = await _demo(const NoParams());
    await result.fold(
      onOk: (pkg) async =>
          _reload(emit, message: 'Demo active · ${pkg.displayName}'),
      onErr: (f) async => emit(ModelDeploymentError(failure: f)),
    );
  }

  Future<void> _reload(
    Emitter<ModelDeploymentState> emit, {
    String? message,
  }) async {
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        ModelDeploymentLoaded(snapshot: snap, statusMessage: message),
      ),
      onErr: (f) => emit(ModelDeploymentError(failure: f)),
    );
  }
}
