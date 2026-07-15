import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_registry_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/model_registry_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_registry_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements DatasetFileManager {}

void main() {
  late Directory temp;
  late _MockFiles files;
  late ModelRegistryRepositoryImpl repo;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('model_reg_');
    files = _MockFiles();
    final paths = DatasetPaths(root: temp.path);
    when(() => files.paths).thenReturn(paths);
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory(paths.models).create(recursive: true);
      await Directory(paths.modelVersions).create(recursive: true);
      await Directory(paths.modelImported).create(recursive: true);
    });

    repo = ModelRegistryRepositoryImpl(
      localDataSource: ModelRegistryLocalDataSourceImpl(
        fileManager: files,
        logger: AppLogger(),
      ),
      validator: const ModelRegistryValidator(),
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('seed bundled and activate', () async {
    final snap = await repo.seedBundledModels();
    expect(snap.isOk, isTrue);
    final models = snap.fold(
      onOk: (v) => v.models,
      onErr: (_) => <RegisteredModel>[],
    );
    expect(models.length, greaterThanOrEqualTo(2));

    final activated = await repo.activateModel('bundled-yolov8n');
    expect(activated.isOk, isTrue);
    expect(
      activated.fold(onOk: (m) => m.status, onErr: (_) => ModelStatus.failed),
      ModelStatus.active,
    );

    final pointers = await repo.getActivePointers();
    expect(
      pointers.fold(
        onOk: (p) => p.detectionModelId,
        onErr: (_) => null,
      ),
      'bundled-yolov8n',
    );
  });

  test('cannot delete bundled', () async {
    await repo.seedBundledModels();
    final result = await repo.deleteModel('bundled-flood-seg');
    expect(result.isErr, isTrue);
  });

  test('register and archive custom model', () async {
    await repo.seedBundledModels();
    final now = DateTime.utc(2026, 7, 14);
    final model = RegisteredModel(
      id: 'custom-1',
      name: 'Custom Seg',
      version: '0.1.0',
      taskType: ModelTaskType.semanticSegmentation,
      status: ModelStatus.registered,
      artifacts: const [
        ModelArtifact(
          id: 'a',
          fileName: 'c.tflite',
          assetPath: 'assets/models/flood_seg.tflite',
          source: ModelArtifactSource.bundledAsset,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    expect((await repo.registerModel(model)).isOk, isTrue);
    expect((await repo.archiveModel('custom-1')).isOk, isTrue);
    expect((await repo.deleteModel('custom-1')).isOk, isTrue);
  });

  test('import local tflite copies artifact', () async {
    await repo.seedBundledModels();
    final src = File('${temp.path}/fake.tflite');
    await src.writeAsBytes([1, 2, 3, 4]);
    final result = await repo.importLocalArtifact(
      name: 'Imported',
      version: '2.0.0',
      taskType: ModelTaskType.objectDetection,
      tfliteSourcePath: src.path,
    );
    expect(result.isOk, isTrue);
    final m = result.fold(onOk: (v) => v, onErr: (_) => throw StateError('x'));
    expect(m.artifacts.first.absolutePath, isNotNull);
    expect(File(m.artifacts.first.absolutePath!).existsSync(), isTrue);
  });
}
