import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_deployment_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/model_deployment_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_deployment_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

class _MockModels extends Mock implements ModelRegistryRepository {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late _MockModels models;
  late ModelDeploymentRepositoryImpl repo;

  final now = DateTime.utc(2026, 7, 14);

  RegisteredModel yolo({String id = 'bundled-yolov8n'}) => RegisteredModel(
        id: id,
        name: 'YOLOv8n Detection',
        version: '1.0.0',
        taskType: ModelTaskType.objectDetection,
        status: ModelStatus.registered,
        createdAt: now,
        updatedAt: now,
        artifacts: const [
          ModelArtifact(
            id: 'a',
            fileName: 'yolov8n.tflite',
            assetPath: 'assets/models/yolov8n.tflite',
            source: ModelArtifactSource.bundledAsset,
          ),
        ],
      );

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('deploy_');
    files = _MockFiles();
    models = _MockModels();
    final paths = DatasetPaths(root: temp.path);
    when(() => files.paths).thenReturn(paths);
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory(paths.deployments).create(recursive: true);
      await Directory(paths.deploymentPackages).create(recursive: true);
    });
    when(() => models.getModel(any())).thenAnswer(
      (inv) async => Ok(yolo(id: inv.positionalArguments.first as String)),
    );
    when(() => models.activateModel(any())).thenAnswer(
      (inv) async => Ok(
        yolo(id: inv.positionalArguments.first as String)
            .copyWith(status: ModelStatus.active),
      ),
    );
    when(() => models.seedBundledModels()).thenAnswer(
      (_) async => Ok(
        ModelRegistrySnapshot(
          models: [yolo()],
          active: ActiveModelPointers(
            detectionModelId: 'bundled-yolov8n',
            updatedAt: now,
          ),
          generatedAt: now,
        ),
      ),
    );

    repo = ModelDeploymentRepositoryImpl(
      localDataSource: ModelDeploymentLocalDataSourceImpl(
        fileManager: files,
        logger: AppLogger(),
      ),
      engine: const ModelDeploymentEngine(),
      modelRegistryRepository: models,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('stage activate and rollback', () async {
    final a = await repo.stageFromModel('bundled-yolov8n');
    expect(a.isOk, isTrue);
    final idA = a.fold(onOk: (p) => p.id, onErr: (_) => '');

    final actA = await repo.activateDeployment(idA);
    expect(actA.isOk, isTrue);
    expect(
      actA.fold(onOk: (p) => p.status, onErr: (_) => DeploymentStatus.failed),
      DeploymentStatus.active,
    );

    final b = await repo.stageFromModel('bundled-yolov8n');
    final idB = b.fold(onOk: (p) => p.id, onErr: (_) => '');
    final actB = await repo.activateDeployment(idB);
    expect(actB.isOk, isTrue);
    expect(
      actB.fold(onOk: (p) => p.previousDeploymentId, onErr: (_) => null),
      idA,
    );

    final rolled = await repo.rollbackDeployment(idB);
    expect(rolled.isOk, isTrue);
    expect(
      rolled.fold(onOk: (p) => p.id, onErr: (_) => ''),
      idA,
    );

    final pointers = await repo.getActivePointers();
    expect(
      pointers.fold(onOk: (p) => p.detectionDeploymentId, onErr: (_) => null),
      idA,
    );
  });

  test('resolveActiveModel returns asset fallback for bundled package', () async {
    final staged = await repo.stageFromModel('bundled-yolov8n');
    final id = staged.fold(onOk: (p) => p.id, onErr: (_) => '');
    await repo.activateDeployment(id);

    final resolved = await repo.resolveActiveModel(
      ModelTaskType.objectDetection,
      fallbackAssetPath: 'assets/models/yolov8n.tflite',
    );
    expect(resolved.isOk, isTrue);
    expect(
      resolved.fold(onOk: (r) => r.usesBundledAsset, onErr: (_) => false),
      isTrue,
    );
    expect(
      resolved.fold(onOk: (r) => r.assetPath, onErr: (_) => null),
      'assets/models/yolov8n.tflite',
    );
  });

  test('cannot delete active package', () async {
    final staged = await repo.stageFromModel('bundled-yolov8n');
    final id = staged.fold(onOk: (p) => p.id, onErr: (_) => '');
    await repo.activateDeployment(id);
    final deleted = await repo.deletePackage(id);
    expect(deleted.isErr, isTrue);
  });
}
