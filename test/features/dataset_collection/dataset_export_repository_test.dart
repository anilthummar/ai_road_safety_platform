import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_export_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_export_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_export_factory.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_document_generators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollection extends Mock implements DatasetCollectionRepository {}

class _MockStorage extends Mock implements DatasetStorageRepository {}

class _MockFiles extends Mock implements DatasetFileManager {}

class _MockBg extends Mock implements StorageBackgroundProcessor {}

void main() {
  late Directory temp;
  late _MockCollection collection;
  late _MockStorage storage;
  late _MockFiles files;
  late _MockBg bg;
  late DatasetExportRepositoryImpl repo;

  final session = DatasetSession(
    id: 's1',
    sessionName: 'Export Drive',
    description: '',
    createdAt: DateTime.utc(2026, 7, 14),
    updatedAt: DateTime.utc(2026, 7, 14),
    duration: const Duration(minutes: 2),
    status: DatasetSessionStatus.completed,
    frameCount: 12,
    floodEventCount: 1,
    totalStorage: 2048,
    averageSpeed: 15,
    averageConfidence: 0.7,
    averageFloodCoverage: 4,
    deviceName: 't',
    appVersion: '1.0.0',
    modelVersion: 'm1',
  );

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('export_repo_');
    collection = _MockCollection();
    storage = _MockStorage();
    files = _MockFiles();
    bg = _MockBg();

    when(() => files.paths).thenReturn(DatasetPaths(root: temp.path));
    when(() => files.ensureRootLayout()).thenAnswer((_) async {
      await Directory('${temp.path}/exports').create(recursive: true);
    });
    when(() => files.fileCount(any())).thenAnswer((_) async => 0);
    when(() => files.directoryByteSize(any())).thenAnswer((_) async => 100);
    when(() => bg.runAsync<String>(any())).thenAnswer((inv) async {
      final fn = inv.positionalArguments.first as Future<String> Function();
      return fn();
    });

    when(() => collection.getSessions())
        .thenAnswer((_) async => Ok([session]));
    when(() => storage.calculateStorage()).thenAnswer(
      (_) async => Ok(
        StorageUsage(
          datasetRoot: temp.path,
          usedBytes: 100,
          freeBytes: 0,
          totalBytes: 0,
          softLimitBytes: 1 << 30,
          isLowStorage: false,
        ),
      ),
    );

    final local = DatasetExportLocalDataSourceImpl(
      fileManager: files,
      backgroundProcessor: bg,
      logger: AppLogger(),
    );

    repo = DatasetExportRepositoryImpl(
      collectionRepository: collection,
      storageRepository: storage,
      fileManager: files,
      localDataSource: local,
      factory: DatasetExportFactory(paths: () => DatasetPaths(root: temp.path)),
      manifestGenerator: const ExportManifestGenerator(),
      readmeGenerator: const ExportReadmeGenerator(),
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('exportDataset creates folder and manifest', () async {
    final result = await repo.exportDataset(
      const ExportSettings(
        datasetName: 'Unit_Dataset',
        includeImages: false,
        includeMetadata: false,
        compressOutput: false,
      ),
    );
    expect(result.isOk, isTrue);
    final export = result.getOrThrow();
    expect(File('${export.exportFolderPath}/manifest.json').existsSync(), isTrue);
    expect(File('${export.exportFolderPath}/README.md').existsSync(), isTrue);
    expect(
      File('${export.exportFolderPath}/sessions/sessions.json').existsSync(),
      isTrue,
    );
  });

  test('validateExport and compressDataset', () async {
    final export = (await repo.exportDataset(
      const ExportSettings(
        datasetName: 'Zip_Dataset',
        includeImages: false,
        includeMetadata: false,
        compressOutput: false,
      ),
    ))
        .getOrThrow();

    final zip = (await repo.compressDataset(export.exportFolderPath))
        .getOrThrow();
    expect(File(zip).existsSync(), isTrue);

    final validation =
        (await repo.validateExport(export.exportFolderPath)).getOrThrow();
    expect(validation.isValid, isTrue);
    expect(validation.zipPresent, isTrue);
    expect(validation.zipIntegrityOk, isTrue);
  });
}
