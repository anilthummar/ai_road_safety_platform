import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_explorer_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollection extends Mock implements DatasetCollectionRepository {}

class _MockStorage extends Mock implements DatasetStorageRepository {}

class _MockFiles extends Mock implements DatasetFileManager {}

DatasetSession _session({
  required String id,
  required String name,
  DateTime? createdAt,
  int frames = 0,
  int storage = 0,
  int floods = 0,
  Duration duration = Duration.zero,
  DatasetSessionStatus status = DatasetSessionStatus.completed,
}) {
  final now = createdAt ?? DateTime.utc(2026, 7, 14);
  return DatasetSession(
    id: id,
    sessionName: name,
    description: 'desc-$name',
    createdAt: now,
    updatedAt: now,
    duration: duration,
    status: status,
    frameCount: frames,
    floodEventCount: floods,
    totalStorage: storage,
    averageSpeed: 10,
    averageConfidence: 0.8,
    averageFloodCoverage: 5,
    deviceName: 'test',
    appVersion: '1',
    modelVersion: 'm1',
  );
}

void main() {
  late _MockCollection collection;
  late _MockStorage storage;
  late _MockFiles files;
  late DatasetExplorerRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(
      const CreateDatasetSessionParams(sessionName: 'x'),
    );
  });

  setUp(() {
    collection = _MockCollection();
    storage = _MockStorage();
    files = _MockFiles();
    when(() => files.paths)
        .thenReturn(const DatasetPaths(root: '/tmp/dataset'));
    when(() => files.ensureRootLayout()).thenAnswer((_) async {});
    when(() => files.directoryByteSize(any())).thenAnswer((_) async => 42);

    repo = DatasetExplorerRepositoryImpl(
      collectionRepository: collection,
      storageRepository: storage,
      fileManager: files,
      errorHandler: ErrorHandler(logger: AppLogger()),
      logger: AppLogger(),
    );
  });

  test('searchSessions filters by name and paginates', () async {
    final sessions = [
      _session(id: '1', name: 'Alpha', frames: 10, storage: 100),
      _session(id: '2', name: 'Beta', frames: 5, storage: 50),
      _session(id: '3', name: 'Alpha Drive', frames: 20, storage: 200),
    ];
    when(() => collection.getSessions())
        .thenAnswer((_) async => Ok(sessions));

    final result = await repo.searchSessions(
      const SessionQuery(searchQuery: 'alpha', pageSize: 1, page: 0),
    );

    expect(result.isOk, isTrue);
    final page = result.getOrThrow();
    expect(page.totalCount, 2);
    expect(page.sessions.length, 1);
    expect(page.hasMore, isTrue);
  });

  test('sortSessions by most frames', () async {
    final sessions = [
      _session(id: '1', name: 'A', frames: 3),
      _session(id: '2', name: 'B', frames: 30),
      _session(id: '3', name: 'C', frames: 10),
    ];
    when(() => collection.getSessions())
        .thenAnswer((_) async => Ok(sessions));

    final result = await repo.sortSessions(
      const SessionQuery(sort: SessionSortOption.mostFrames),
    );
    final page = result.getOrThrow();
    expect(page.sessions.map((s) => s.id).toList(), ['2', '3', '1']);
  });

  test('filterSessions today', () async {
    final today = DateTime.now();
    final sessions = [
      _session(id: '1', name: 'Today', createdAt: today),
      _session(
        id: '2',
        name: 'Old',
        createdAt: today.subtract(const Duration(days: 10)),
      ),
    ];
    when(() => collection.getSessions())
        .thenAnswer((_) async => Ok(sessions));

    final result = await repo.filterSessions(
      const SessionQuery(dateFilter: SessionDateFilter.today),
    );
    expect(result.getOrThrow().sessions.map((s) => s.id), ['1']);
  });

  test('loadDashboard aggregates', () async {
    final sessions = [
      _session(
        id: '1',
        name: 'A',
        frames: 60,
        duration: const Duration(minutes: 2),
      ),
    ];
    when(() => collection.getSessions())
        .thenAnswer((_) async => Ok(sessions));
    when(() => collection.getStatistics()).thenAnswer(
      (_) async => const Ok(
        DatasetStatistics(
          totalSessions: 1,
          totalFrames: 60,
          totalFloodEvents: 0,
          totalStorage: 10,
          averageSpeed: 1,
          averageConfidence: 0.5,
        ),
      ),
    );
    when(() => collection.getStorageInformation()).thenAnswer(
      (_) async => const Ok(
        DatasetStorage(
          totalDiskSpace: 0,
          usedDiskSpace: 10,
          remainingDiskSpace: 0,
          datasetFolder: '/tmp/dataset',
        ),
      ),
    );
    when(() => storage.calculateStorage()).thenAnswer(
      (_) async => const Ok(
        StorageUsage(
          datasetRoot: '/tmp/dataset',
          usedBytes: 10,
          freeBytes: 0,
          totalBytes: 0,
          softLimitBytes: 1000,
          isLowStorage: false,
        ),
      ),
    );
    when(() => collection.getActiveSession())
        .thenAnswer((_) async => const Ok(null));

    final data = (await repo.loadDashboard()).getOrThrow();
    expect(data.statistics.totalFrames, 60);
    expect(data.framesPerMinute, 30);
    expect(data.recentSessions, hasLength(1));
  });

  test('duplicateSession creates copy', () async {
    final source = _session(id: 's1', name: 'Original');
    when(() => collection.getSession('s1'))
        .thenAnswer((_) async => Ok(source));
    when(() => collection.createSession(any())).thenAnswer(
      (_) async => Ok(_session(id: 's2', name: 'Original (Copy)')),
    );

    final copy = (await repo.duplicateSession('s1')).getOrThrow();
    expect(copy.id, 's2');
    expect(copy.sessionName, contains('Copy'));
  });
}
