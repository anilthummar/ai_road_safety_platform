import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_explorer_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_explorer_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoadDashboard extends Mock implements LoadDashboardUseCase {}

class _MockSearch extends Mock implements SearchSessionsUseCase {}

class _MockDetails extends Mock implements LoadSessionDetailsUseCase {}

class _MockRename extends Mock implements RenameExplorerSessionUseCase {}

class _MockDelete extends Mock implements DeleteExplorerSessionUseCase {}

class _MockDuplicate extends Mock implements DuplicateExplorerSessionUseCase {}

DatasetSession _session(String id) {
  final now = DateTime.utc(2026, 7, 14);
  return DatasetSession(
    id: id,
    sessionName: 'S$id',
    description: '',
    createdAt: now,
    updatedAt: now,
    duration: const Duration(minutes: 1),
    status: DatasetSessionStatus.completed,
    frameCount: 10,
    floodEventCount: 1,
    totalStorage: 100,
    averageSpeed: 20,
    averageConfidence: 0.9,
    averageFloodCoverage: 2,
    deviceName: 't',
    appVersion: '1',
    modelVersion: 'm',
  );
}

DatasetDashboardData _dashboard({int sessions = 1}) {
  return DatasetDashboardData(
    statistics: DatasetStatistics(
      totalSessions: sessions,
      totalFrames: 10,
      totalFloodEvents: 1,
      totalStorage: 100,
      averageSpeed: 20,
      averageConfidence: 0.9,
    ),
    collectionStorage: const DatasetStorage(
      totalDiskSpace: 0,
      usedDiskSpace: 100,
      remainingDiskSpace: 0,
      datasetFolder: '/tmp',
    ),
    diskUsage: const StorageUsage(
      datasetRoot: '/tmp',
      usedBytes: 100,
      freeBytes: 0,
      totalBytes: 0,
      softLimitBytes: 1000,
      isLowStorage: false,
    ),
    recentSessions: sessions == 0 ? const [] : [_session('1')],
    totalRecordingTime: const Duration(minutes: 1),
    framesPerMinute: 10,
    averageFloodCoverage: 2,
  );
}

void main() {
  late _MockLoadDashboard loadDashboard;
  late _MockSearch search;
  late _MockDetails details;
  late _MockRename rename;
  late _MockDelete delete;
  late _MockDuplicate duplicate;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const SessionQuery());
    registerFallbackValue(
      const RenameDatasetSessionParams(id: '1', sessionName: 'n'),
    );
  });

  setUp(() {
    loadDashboard = _MockLoadDashboard();
    search = _MockSearch();
    details = _MockDetails();
    rename = _MockRename();
    delete = _MockDelete();
    duplicate = _MockDuplicate();
  });

  DatasetExplorerBloc build() => DatasetExplorerBloc(
        loadDashboard: loadDashboard,
        searchSessions: search,
        loadSessionDetails: details,
        renameSession: rename,
        deleteSession: delete,
        duplicateSession: duplicate,
        logger: AppLogger(),
      );

  blocTest<DatasetExplorerBloc, DatasetExplorerState>(
    'LoadDashboard emits DashboardLoaded',
    build: () {
      when(() => loadDashboard(any()))
          .thenAnswer((_) async => Ok(_dashboard()));
      return build();
    },
    act: (b) => b.add(const DatasetExplorerLoadDashboard()),
    expect: () => [
      isA<DatasetExplorerLoading>(),
      isA<DatasetExplorerDashboardLoaded>(),
    ],
  );

  blocTest<DatasetExplorerBloc, DatasetExplorerState>(
    'LoadDashboard with zero sessions emits Empty',
    build: () {
      when(() => loadDashboard(any()))
          .thenAnswer((_) async => Ok(_dashboard(sessions: 0)));
      return build();
    },
    act: (b) => b.add(const DatasetExplorerLoadDashboard()),
    expect: () => [
      isA<DatasetExplorerLoading>(),
      isA<DatasetExplorerEmpty>(),
    ],
  );

  blocTest<DatasetExplorerBloc, DatasetExplorerState>(
    'SearchSession emits SessionsLoaded',
    build: () {
      when(() => search(any())).thenAnswer(
        (_) async => Ok(
          SessionPage(
            sessions: [_session('1')],
            totalCount: 1,
            query: const SessionQuery(searchQuery: 'S'),
          ),
        ),
      );
      return build();
    },
    act: (b) => b.add(const DatasetExplorerSearchSession('S')),
    expect: () => [
      isA<DatasetExplorerLoading>(),
      isA<DatasetExplorerSessionsLoaded>(),
    ],
  );

  blocTest<DatasetExplorerBloc, DatasetExplorerState>(
    'OpenSession emits SessionOpened',
    build: () {
      when(() => details(any())).thenAnswer(
        (_) async => Ok(
          SessionDetails(
            session: _session('1'),
            diskBytes: 10,
            previews: const [],
            captureRateFpm: 10,
          ),
        ),
      );
      return build();
    },
    act: (b) => b.add(const DatasetExplorerOpenSession('1')),
    expect: () => [
      isA<DatasetExplorerLoading>(),
      isA<DatasetExplorerSessionOpened>(),
    ],
  );

  blocTest<DatasetExplorerBloc, DatasetExplorerState>(
    'LoadDashboard error',
    build: () {
      when(() => loadDashboard(any())).thenAnswer(
        (_) async => const Err(CacheFailure(message: 'boom')),
      );
      return build();
    },
    act: (b) => b.add(const DatasetExplorerLoadDashboard()),
    expect: () => [
      isA<DatasetExplorerLoading>(),
      isA<DatasetExplorerError>(),
    ],
  );
}
