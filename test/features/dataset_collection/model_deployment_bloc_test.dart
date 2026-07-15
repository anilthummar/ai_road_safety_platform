import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_deployment_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_deployment_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadDeploymentSnapshotUseCase {}

class _MockStage extends Mock implements StageDeploymentUseCase {}

class _MockActivate extends Mock implements ActivateDeploymentUseCase {}

class _MockRollback extends Mock implements RollbackDeploymentUseCase {}

class _MockDelete extends Mock implements DeleteDeploymentUseCase {}

class _MockDemo extends Mock implements CreateDemoDeploymentUseCase {}

void main() {
  late _MockLoad load;
  late _MockStage stage;
  late _MockActivate activate;
  late _MockRollback rollback;
  late _MockDelete delete;
  late _MockDemo demo;

  final now = DateTime.utc(2026, 7, 14);
  final pkg = DeploymentPackage(
    id: 'd1',
    modelId: 'bundled-yolov8n',
    modelVersion: '1.0.0',
    displayName: 'YOLO · 1.0.0',
    taskType: ModelTaskType.objectDetection,
    status: DeploymentStatus.active,
    createdAt: now,
  );
  final snap = DeploymentSnapshot(
    packages: [pkg],
    active: ActiveDeploymentPointers(
      detectionDeploymentId: 'd1',
      updatedAt: now,
    ),
    generatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const StageDeploymentParams('x'));
    registerFallbackValue(const DeploymentIdParams('x'));
  });

  setUp(() {
    load = _MockLoad();
    stage = _MockStage();
    activate = _MockActivate();
    rollback = _MockRollback();
    delete = _MockDelete();
    demo = _MockDemo();
    when(() => load(any())).thenAnswer((_) async => Ok(snap));
  });

  ModelDeploymentBloc build() => ModelDeploymentBloc(
        loadDeploymentSnapshot: load,
        stageDeployment: stage,
        activateDeployment: activate,
        rollbackDeployment: rollback,
        deleteDeployment: delete,
        createDemoDeployment: demo,
        logger: AppLogger(),
      );

  blocTest<ModelDeploymentBloc, ModelDeploymentState>(
    'load emits loaded snapshot',
    build: build,
    act: (b) => b.add(const ModelDeploymentLoad()),
    expect: () => [
      isA<ModelDeploymentLoading>(),
      isA<ModelDeploymentLoaded>().having(
        (s) => s.snapshot.totalCount,
        'count',
        1,
      ),
    ],
  );

  blocTest<ModelDeploymentBloc, ModelDeploymentState>(
    'activate then reloads',
    build: build,
    setUp: () {
      when(() => activate(any())).thenAnswer((_) async => Ok(pkg));
    },
    act: (b) => b.add(const ModelDeploymentActivate('d1')),
    expect: () => [
      isA<ModelDeploymentLoading>(),
      isA<ModelDeploymentLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('Active'),
      ),
    ],
  );
}
