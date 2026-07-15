import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_export_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_export_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_export_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockExportDataset extends Mock implements ExportDatasetUseCase {}

class _MockExportSession extends Mock implements ExportSessionUseCase {}

class _MockManifest extends Mock implements GenerateManifestUseCase {}

class _MockReadme extends Mock implements GenerateReadmeUseCase {}

class _MockCompress extends Mock implements CompressDatasetUseCase {}

class _MockValidate extends Mock implements ValidateExportUseCase {}

class _MockRepo extends Mock implements DatasetExportRepository {}

void main() {
  late _MockExportDataset exportDataset;
  late _MockExportSession exportSession;
  late _MockManifest manifest;
  late _MockReadme readme;
  late _MockCompress compress;
  late _MockValidate validate;
  late _MockRepo repo;

  final result = ExportResult(
    exportId: 'e1',
    exportFolderPath: '/tmp/export',
    manifest: ExportManifest(
      datasetName: 'D',
      exportDate: DateTime.utc(2026, 7, 14),
      exportVersion: '12.8.0',
      sessionCount: 1,
      frameCount: 10,
      imageCount: 0,
      metadataCount: 0,
      storageSizeBytes: 10,
      applicationVersion: '1.0.0',
      aiModelVersion: 'm',
      format: 'json',
      sessionIds: const ['s1'],
    ),
    settings: const ExportSettings(),
    completedAt: DateTime.utc(2026, 7, 14),
    createdFiles: const ['manifest.json'],
  );

  setUpAll(() {
    registerFallbackValue(
      const ExportDatasetParams(settings: ExportSettings()),
    );
    registerFallbackValue(
      const ExportSessionParams(sessionId: 's', settings: ExportSettings()),
    );
  });

  setUp(() {
    exportDataset = _MockExportDataset();
    exportSession = _MockExportSession();
    manifest = _MockManifest();
    readme = _MockReadme();
    compress = _MockCompress();
    validate = _MockValidate();
    repo = _MockRepo();
    when(() => repo.loadExportHistory())
        .thenAnswer((_) async => const Ok(<ExportHistoryEntry>[]));
    when(() => validate(any())).thenAnswer(
      (_) async => const Ok(
        ExportValidation(
          isValid: true,
          errors: [],
          warnings: [],
          imagesPresent: false,
          metadataPresent: false,
          sessionsPresent: true,
          manifestPresent: true,
          readmePresent: true,
          zipPresent: false,
          zipIntegrityOk: false,
        ),
      ),
    );
  });

  DatasetExportBloc build() => DatasetExportBloc(
        exportDataset: exportDataset,
        exportSession: exportSession,
        generateManifest: manifest,
        generateReadme: readme,
        compressDataset: compress,
        validateExport: validate,
        repository: repo,
        logger: AppLogger(),
      );

  blocTest<DatasetExportBloc, DatasetExportState>(
    'ExportRequested emits Completed',
    build: () {
      when(() => exportDataset(any())).thenAnswer((_) async => Ok(result));
      return build();
    },
    act: (b) => b.add(const DatasetExportRequested(ExportSettings())),
    expect: () => [
      isA<DatasetExportPreparing>(),
      isA<DatasetExportExporting>(),
      isA<DatasetExportCompleted>(),
    ],
  );

  blocTest<DatasetExportBloc, DatasetExportState>(
    'ExportRequested emits Failed',
    build: () {
      when(() => exportDataset(any())).thenAnswer(
        (_) async => const Err(CacheFailure(message: 'boom')),
      );
      return build();
    },
    act: (b) => b.add(const DatasetExportRequested(ExportSettings())),
    expect: () => [
      isA<DatasetExportPreparing>(),
      isA<DatasetExportExporting>(),
      isA<DatasetExportFailed>(),
    ],
  );

  blocTest<DatasetExportBloc, DatasetExportState>(
    'LoadHistory emits Initial',
    build: build,
    act: (b) => b.add(const DatasetExportLoadHistory()),
    expect: () => [isA<DatasetExportInitial>()],
  );
}
