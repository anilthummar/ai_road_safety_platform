import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_registry_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_registry_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadModelRegistryUseCase {}

class _MockRegister extends Mock implements RegisterModelUseCase {}

class _MockDelete extends Mock implements DeleteModelUseCase {}

class _MockActivate extends Mock implements ActivateModelUseCase {}

class _MockArchive extends Mock implements ArchiveModelUseCase {}

class _MockSeed extends Mock implements SeedBundledModelsUseCase {}

void main() {
  late _MockLoad load;
  late _MockRegister register;
  late _MockDelete delete;
  late _MockActivate activate;
  late _MockArchive archive;
  late _MockSeed seed;

  final snap = ModelRegistrySnapshot(
    models: BundledModelCatalog.defaults(now: DateTime.utc(2026, 7, 14)),
    active: ActiveModelPointers(
      detectionModelId: 'bundled-yolov8n',
      updatedAt: DateTime.utc(2026, 7, 14),
    ),
    generatedAt: DateTime.utc(2026, 7, 14),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      RegisteredModel(
        id: 'x',
        name: 'x',
        version: '1',
        taskType: ModelTaskType.unknown,
        status: ModelStatus.registered,
        createdAt: DateTime.utc(2026, 7, 14),
        updatedAt: DateTime.utc(2026, 7, 14),
        artifacts: const [
          ModelArtifact(
            id: 'a',
            fileName: 'a.tflite',
            assetPath: 'assets/models/yolov8n.tflite',
            source: ModelArtifactSource.bundledAsset,
          ),
        ],
      ),
    );
    registerFallbackValue(const DeleteModelParams('x'));
    registerFallbackValue(const ActivateModelParams('x'));
  });

  setUp(() {
    load = _MockLoad();
    register = _MockRegister();
    delete = _MockDelete();
    activate = _MockActivate();
    archive = _MockArchive();
    seed = _MockSeed();
    when(() => load(any())).thenAnswer((_) async => Ok(snap));
  });

  ModelRegistryBloc build() => ModelRegistryBloc(
        loadModelRegistry: load,
        registerModel: register,
        deleteModel: delete,
        activateModel: activate,
        archiveModel: archive,
        seedBundledModels: seed,
        logger: AppLogger(),
      );

  blocTest<ModelRegistryBloc, ModelRegistryState>(
    'load emits loaded snapshot',
    build: build,
    act: (b) => b.add(const ModelRegistryLoad()),
    expect: () => [
      isA<ModelRegistryLoading>(),
      isA<ModelRegistryLoaded>().having(
        (s) => s.snapshot.models.length,
        'models',
        2,
      ),
    ],
  );

  blocTest<ModelRegistryBloc, ModelRegistryState>(
    'activate then reloads',
    build: build,
    setUp: () {
      when(() => activate(any())).thenAnswer(
        (_) async => Ok(snap.models.first.copyWith(status: ModelStatus.active)),
      );
    },
    act: (b) => b.add(const ModelRegistryActivate('bundled-yolov8n')),
    expect: () => [
      isA<ModelRegistryLoading>(),
      isA<ModelRegistryLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('Activated'),
      ),
    ],
  );
}
