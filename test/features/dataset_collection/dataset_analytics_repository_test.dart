import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_analytics_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_analytics_calculator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollection extends Mock implements DatasetCollectionRepository {}

class _MockStorage extends Mock implements DatasetStorageRepository {}

class _MockFiles extends Mock implements DatasetFileManager {}

void main() {
  late _MockCollection collection;
  late _MockStorage storage;
  late _MockFiles files;
  late DatasetAnalyticsRepositoryImpl repo;

  final session = DatasetSession(
    id: 's1',
    sessionName: 'Drive',
    description: '',
    createdAt: DateTime.utc(2026, 7, 14),
    updatedAt: DateTime.utc(2026, 7, 14),
    duration: const Duration(minutes: 5),
    status: DatasetSessionStatus.completed,
    frameCount: 50,
    floodEventCount: 3,
    totalStorage: 2048,
    averageSpeed: 25,
    averageConfidence: 0.7,
    averageFloodCoverage: 8,
    deviceName: 't',
    appVersion: '1',
    modelVersion: 'm',
  );

  setUp(() {
    collection = _MockCollection();
    storage = _MockStorage();
    files = _MockFiles();
    when(() => files.ensureRootLayout()).thenAnswer((_) async {});
    when(() => collection.getSessions())
        .thenAnswer((_) async => Ok([session]));
    when(() => storage.calculateStorage()).thenAnswer(
      (_) async => const Ok(
        StorageUsage(
          datasetRoot: '/tmp',
          usedBytes: 2048,
          freeBytes: 0,
          totalBytes: 0,
          softLimitBytes: 1 << 30,
          isLowStorage: false,
        ),
      ),
    );
    when(() => storage.listFolderInfo())
        .thenAnswer((_) async => const Ok(<FolderInfo>[]));
    when(() => storage.recoverSession()).thenAnswer(
      (_) async => const Ok(<SessionRecoveryInfo>[]),
    );
    when(
      () => storage.loadMetadata(
        sessionId: any(named: 'sessionId'),
        frameNumber: any(named: 'frameNumber'),
      ),
    ).thenAnswer(
      (_) async => const Err(CacheFailure(message: 'missing')),
    );

    repo = DatasetAnalyticsRepositoryImpl(
      collectionRepository: collection,
      storageRepository: storage,
      fileManager: files,
      calculator: const DatasetAnalyticsCalculator(),
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  test('loadAnalytics returns loaded report', () async {
    final result = await repo.loadAnalytics();
    expect(result.isOk, isTrue);
    final report = result.getOrThrow();
    expect(report.overview.totalSessions, 1);
    expect(report.overview.totalFrames, 50);
    expect(report.insights.insights, isNotEmpty);
  });

  test('loadResearchInsights returns highlights', () async {
    final insights = (await repo.loadResearchInsights()).getOrThrow();
    expect(insights.insights, isNotEmpty);
  });

  test('loadStorageAnalytics returns storage slice', () async {
    final storageAnalytics =
        (await repo.loadStorageAnalytics()).getOrThrow();
    expect(storageAnalytics.totalStorageBytes, 2048);
  });
}
