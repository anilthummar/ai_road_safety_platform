import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/session_timer_service.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_collection_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_collection_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreate extends Mock implements CreateDatasetSessionUseCase {}

class _MockStart extends Mock implements StartRecordingSessionUseCase {}

class _MockPause extends Mock implements PauseRecordingSessionUseCase {}

class _MockResume extends Mock implements ResumeRecordingSessionUseCase {}

class _MockStop extends Mock implements StopRecordingSessionUseCase {}

class _MockCancel extends Mock implements CancelRecordingSessionUseCase {}

class _MockRename extends Mock implements RenameDatasetSessionUseCase {}

class _MockDelete extends Mock implements DeleteDatasetSessionUseCase {}

class _MockGetSessions extends Mock implements GetDatasetSessionsUseCase {}

class _MockGetStats extends Mock implements GetDatasetStatisticsUseCase {}

class _MockGetStorage extends Mock implements GetStorageInformationUseCase {}

class _MockLoadCurrent extends Mock
    implements LoadCurrentRecordingSessionUseCase {}

class _FakeTimer implements SessionTimerService {
  final _controller = StreamController<Duration>.broadcast();
  Duration _elapsed = Duration.zero;
  bool _running = false;

  @override
  Stream<Duration> get elapsedStream => _controller.stream;

  @override
  Duration get elapsed => _elapsed;

  @override
  bool get isRunning => _running;

  @override
  void start({Duration seed = Duration.zero}) {
    _elapsed = seed;
    _running = true;
    _controller.add(_elapsed);
  }

  @override
  void pause() {
    _running = false;
    _controller.add(_elapsed);
  }

  @override
  void resume() {
    _running = true;
    _controller.add(_elapsed);
  }

  @override
  void stop() {
    _running = false;
    _controller.add(_elapsed);
  }

  @override
  void reset() {
    _elapsed = Duration.zero;
    _running = false;
    _controller.add(_elapsed);
  }

  @override
  void dispose() {
    _controller.close();
  }

  void tick(Duration value) {
    _elapsed = value;
    _controller.add(value);
  }
}

DatasetSession _session({
  String id = 's1',
  DatasetSessionStatus status = DatasetSessionStatus.recording,
  Duration duration = Duration.zero,
}) {
  final now = DateTime.utc(2026, 7, 14);
  return DatasetSession(
    id: id,
    sessionName: 'Morning Drive',
    description: 'route',
    createdAt: now,
    updatedAt: now,
    startedAt: now,
    duration: duration,
    status: status,
    frameCount: 0,
    floodEventCount: 0,
    totalStorage: 0,
    averageSpeed: 0,
    averageConfidence: 0,
    averageFloodCoverage: 0,
    deviceName: 'test',
    appVersion: '1.0.0',
    modelVersion: 'pending',
  );
}

const _stats = DatasetStatistics.empty();
const _storage = DatasetStorage(
  totalDiskSpace: 0,
  usedDiskSpace: 0,
  remainingDiskSpace: 0,
  datasetFolder: '/tmp/dataset_collection',
);

void main() {
  late _MockCreate create;
  late _MockStart start;
  late _MockPause pause;
  late _MockResume resume;
  late _MockStop stop;
  late _MockCancel cancel;
  late _MockRename rename;
  late _MockDelete delete;
  late _MockGetSessions getSessions;
  late _MockGetStats getStats;
  late _MockGetStorage getStorage;
  late _MockLoadCurrent loadCurrent;
  late _FakeTimer timer;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CreateDatasetSessionParams(sessionName: 'x'),
    );
    registerFallbackValue(
      const RenameDatasetSessionParams(id: 'x', sessionName: 'y'),
    );
    registerFallbackValue(const SessionElapsedParams(Duration.zero));
    registerFallbackValue(_session());
  });

  DatasetCollectionBloc buildBloc() {
    return DatasetCollectionBloc(
      createSession: create,
      startSession: start,
      pauseSession: pause,
      resumeSession: resume,
      stopSession: stop,
      cancelSession: cancel,
      renameSession: rename,
      deleteSession: delete,
      getSessions: getSessions,
      getStatistics: getStats,
      getStorage: getStorage,
      loadCurrent: loadCurrent,
      timer: timer,
      logger: AppLogger(),
    );
  }

  void stubDashboard({List<DatasetSession> sessions = const []}) {
    when(() => getSessions(any())).thenAnswer((_) async => Ok(sessions));
    when(() => getStats(any())).thenAnswer((_) async => const Ok(_stats));
    when(() => getStorage(any())).thenAnswer((_) async => const Ok(_storage));
  }

  setUp(() {
    create = _MockCreate();
    start = _MockStart();
    pause = _MockPause();
    resume = _MockResume();
    stop = _MockStop();
    cancel = _MockCancel();
    rename = _MockRename();
    delete = _MockDelete();
    getSessions = _MockGetSessions();
    getStats = _MockGetStats();
    getStorage = _MockGetStorage();
    loadCurrent = _MockLoadCurrent();
    timer = _FakeTimer();
  });

  blocTest<DatasetCollectionBloc, DatasetCollectionState>(
    'Initialize with no active session emits Empty',
    build: () {
      stubDashboard();
      when(() => loadCurrent(any())).thenAnswer((_) async => const Ok(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const DatasetCollectionInitialize()),
    expect: () => [
      isA<DatasetCollectionLoading>(),
      isA<DatasetCollectionEmpty>(),
    ],
  );

  blocTest<DatasetCollectionBloc, DatasetCollectionState>(
    'Initialize with unfinished session emits RestorePrompt',
    build: () {
      final unfinished = _session(status: DatasetSessionStatus.paused);
      stubDashboard(sessions: [unfinished]);
      when(() => loadCurrent(any()))
          .thenAnswer((_) async => Ok(unfinished));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const DatasetCollectionInitialize()),
    expect: () => [
      isA<DatasetCollectionLoading>(),
      isA<DatasetCollectionRestorePrompt>(),
    ],
  );

  blocTest<DatasetCollectionBloc, DatasetCollectionState>(
    'StartRecording emits Recording',
    build: () {
      final session = _session();
      stubDashboard(sessions: [session]);
      when(() => start(any())).thenAnswer((_) async => Ok(session));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const DatasetCollectionStartRecording(
        CreateDatasetSessionParams(sessionName: 'Morning Drive'),
      ),
    ),
    expect: () => [
      isA<DatasetCollectionBusy>(),
      isA<DatasetCollectionRecording>(),
    ],
  );

  blocTest<DatasetCollectionBloc, DatasetCollectionState>(
    'PauseRecording emits Paused',
    build: () {
      final recording = _session();
      final paused =
          recording.copyWith(status: DatasetSessionStatus.paused);
      stubDashboard(sessions: [recording]);
      when(() => pause(any())).thenAnswer((_) async => Ok(paused));
      return buildBloc();
    },
    seed: () => DatasetCollectionRecording(
      DatasetCollectionDashboardData(
        sessions: [_session()],
        statistics: _stats,
        storage: _storage,
        activeSession: _session(),
      ),
    ),
    act: (bloc) {
      timer.start();
      bloc.add(const DatasetCollectionPauseRecording());
    },
    expect: () => [
      isA<DatasetCollectionPaused>(),
    ],
  );

  blocTest<DatasetCollectionBloc, DatasetCollectionState>(
    'StartRecording failure emits Error then refreshes',
    build: () {
      stubDashboard();
      when(() => start(any())).thenAnswer(
        (_) async => const Err(CacheFailure(message: 'already active')),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const DatasetCollectionStartRecording(
        CreateDatasetSessionParams(sessionName: 'Dup'),
      ),
    ),
    expect: () => [
      isA<DatasetCollectionBusy>(),
      isA<DatasetCollectionError>(),
      isA<DatasetCollectionEmpty>(),
    ],
  );
}
