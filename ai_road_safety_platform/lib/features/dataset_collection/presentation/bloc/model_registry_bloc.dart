import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_registry_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_registry_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_registry_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

export 'model_registry_event.dart';
export 'model_registry_state.dart';

/// Local model version / artifact registry orchestration (Phase 13.2).
class ModelRegistryBloc
    extends Bloc<ModelRegistryEvent, ModelRegistryState> {
  final LoadModelRegistryUseCase _load;
  final RegisterModelUseCase _register;
  final DeleteModelUseCase _delete;
  final ActivateModelUseCase _activate;
  final ArchiveModelUseCase _archive;
  final SeedBundledModelsUseCase _seed;
  final AppLogger _logger;
  final Uuid _uuid;

  ModelRegistryBloc({
    required LoadModelRegistryUseCase loadModelRegistry,
    required RegisterModelUseCase registerModel,
    required DeleteModelUseCase deleteModel,
    required ActivateModelUseCase activateModel,
    required ArchiveModelUseCase archiveModel,
    required SeedBundledModelsUseCase seedBundledModels,
    required AppLogger logger,
    Uuid? uuid,
  })  : _load = loadModelRegistry,
        _register = registerModel,
        _delete = deleteModel,
        _activate = activateModel,
        _archive = archiveModel,
        _seed = seedBundledModels,
        _logger = logger,
        _uuid = uuid ?? const Uuid(),
        super(const ModelRegistryInitial()) {
    on<ModelRegistryLoad>(_onLoad);
    on<ModelRegistryRefresh>(_onLoad);
    on<ModelRegistryActivate>(_onActivate);
    on<ModelRegistryArchive>(_onArchive);
    on<ModelRegistryDelete>(_onDelete);
    on<ModelRegistryRegisterDemo>(_onRegisterDemo);
    on<ModelRegistrySeedBundled>(_onSeed);
  }

  Future<void> _onLoad(
    ModelRegistryEvent event,
    Emitter<ModelRegistryState> emit,
  ) async {
    emit(const ModelRegistryLoading());
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(ModelRegistryLoaded(snapshot: snap)),
      onErr: (f) => emit(ModelRegistryError(failure: f)),
    );
  }

  Future<void> _onActivate(
    ModelRegistryActivate event,
    Emitter<ModelRegistryState> emit,
  ) async {
    emit(const ModelRegistryLoading(message: 'Activating model…'));
    final result = await _activate(ActivateModelParams(event.modelId));
    await result.fold(
      onOk: (m) async {
        _logger.info('Activated ${m.id}', tag: 'ModelRegistryBloc');
        await _reload(emit, message: 'Activated ${m.displayName}');
      },
      onErr: (f) async => emit(ModelRegistryError(failure: f)),
    );
  }

  Future<void> _onArchive(
    ModelRegistryArchive event,
    Emitter<ModelRegistryState> emit,
  ) async {
    emit(const ModelRegistryLoading(message: 'Archiving…'));
    final result = await _archive(ActivateModelParams(event.modelId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Archived'),
      onErr: (f) async => emit(ModelRegistryError(failure: f)),
    );
  }

  Future<void> _onDelete(
    ModelRegistryDelete event,
    Emitter<ModelRegistryState> emit,
  ) async {
    emit(const ModelRegistryLoading(message: 'Deleting…'));
    final result = await _delete(DeleteModelParams(event.modelId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Deleted'),
      onErr: (f) async => emit(ModelRegistryError(failure: f)),
    );
  }

  Future<void> _onRegisterDemo(
    ModelRegistryRegisterDemo event,
    Emitter<ModelRegistryState> emit,
  ) async {
    emit(const ModelRegistryLoading(message: 'Registering metadata…'));
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final model = RegisteredModel(
      id: id,
      name: 'Research Draft',
      version: '0.${now.millisecondsSinceEpoch % 1000}.0',
      taskType: event.taskType,
      status: ModelStatus.registered,
      description: 'Metadata-only draft (no binary yet)',
      artifacts: [
        ModelArtifact(
          id: 'art-$id',
          fileName: 'placeholder.tflite',
          assetPath: 'assets/models/yolov8n.tflite',
          source: ModelArtifactSource.bundledAsset,
          mimeHint: 'application/tflite',
        ),
      ],
      tags: const {'demo': 'true'},
      metrics: const {'params_m': 0},
      createdAt: now,
      updatedAt: now,
      notes: 'Created from Model Management UI',
    );
    final result = await _register(model);
    await result.fold(
      onOk: (m) async => _reload(emit, message: 'Registered ${m.displayName}'),
      onErr: (f) async => emit(ModelRegistryError(failure: f)),
    );
  }

  Future<void> _onSeed(
    ModelRegistrySeedBundled event,
    Emitter<ModelRegistryState> emit,
  ) async {
    emit(const ModelRegistryLoading(message: 'Seeding bundled models…'));
    final result = await _seed(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        ModelRegistryLoaded(
          snapshot: snap,
          statusMessage: 'Bundled catalog ready',
        ),
      ),
      onErr: (f) => emit(ModelRegistryError(failure: f)),
    );
  }

  Future<void> _reload(
    Emitter<ModelRegistryState> emit, {
    String? message,
  }) async {
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        ModelRegistryLoaded(snapshot: snap, statusMessage: message),
      ),
      onErr: (f) => emit(ModelRegistryError(failure: f)),
    );
  }
}
