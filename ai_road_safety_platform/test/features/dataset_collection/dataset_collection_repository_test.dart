import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_collection_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_collection_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements DatasetCollectionLocalDataSource {}

DatasetSession _session({
  String id = 's1',
  DatasetSessionStatus status = DatasetSessionStatus.recording,
  Duration duration = Duration.zero,
}) {
  final now = DateTime.utc(2026, 7, 14);
  return DatasetSession(
    id: id,
    sessionName: 'Morning Drive',
    description: '',
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

void main() {
  late _MockLocal local;
  late DatasetCollectionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const CreateDatasetSessionParams(sessionName: 'x'),
    );
    registerFallbackValue(_session());
  });

  setUp(() {
    local = _MockLocal();
    repository = DatasetCollectionRepositoryImpl(
      localDataSource: local,
      errorHandler: ErrorHandler(logger: AppLogger()),
    );
  });

  test('startSession rejects when another session is active', () async {
    when(local.getActiveSession).thenAnswer((_) async => _session());

    final result = await repository.startSession(
      const CreateDatasetSessionParams(sessionName: 'Evening'),
    );

    expect(result.isErr, isTrue);
    expect(result.fold(onOk: (_) => '', onErr: (f) => f.message), contains('already active'));
    verifyNever(() => local.startRecordingSession(any()));
  });

  test('startSession succeeds and remembers current id', () async {
    final created = _session(id: 'new');
    when(local.getActiveSession).thenAnswer((_) async => null);
    when(() => local.startRecordingSession(any()))
        .thenAnswer((_) async => created);
    when(() => local.setCurrentSessionId(any())).thenAnswer((_) async {});

    final result = await repository.startSession(
      const CreateDatasetSessionParams(sessionName: 'Morning Drive'),
    );

    expect(result.isOk, isTrue);
    verify(() => local.setCurrentSessionId('new')).called(1);
  });

  test('pauseSession requires recording status', () async {
    when(local.getActiveSession).thenAnswer(
      (_) async => _session(status: DatasetSessionStatus.paused),
    );

    final result =
        await repository.pauseSession(elapsed: const Duration(seconds: 5));
    expect(result.isErr, isTrue);
  });

  test('resumeSession rejects terminal sessions', () async {
    // getActiveSession only returns unfinished — simulate paused then resume of
    // stopped is blocked via getActiveSession null.
    when(local.getActiveSession).thenAnswer((_) async => null);
    final result = await repository.resumeSession();
    expect(result.isErr, isTrue);
    expect(
      result.fold(onOk: (_) => '', onErr: (f) => f.message),
      contains('No active'),
    );
  });

  test('stopSession persists duration and clears current id', () async {
    final active = _session();
    when(local.getActiveSession).thenAnswer((_) async => active);
    when(() => local.updateSession(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as DatasetSession,
    );
    when(() => local.setCurrentSessionId(null)).thenAnswer((_) async {});

    final result =
        await repository.stopSession(elapsed: const Duration(seconds: 42));

    expect(result.isOk, isTrue);
    final saved = result.getOrThrow();
    expect(saved.status, DatasetSessionStatus.stopped);
    expect(saved.duration, const Duration(seconds: 42));
    verify(() => local.setCurrentSessionId(null)).called(1);
  });

  test('deleteSession blocks unfinished sessions', () async {
    when(() => local.getSession('s1')).thenAnswer(
      (_) async => _session(status: DatasetSessionStatus.recording),
    );

    final result = await repository.deleteSession('s1');
    expect(result.isErr, isTrue);
    verifyNever(() => local.deleteSession(any()));
  });

  test('renameSession rejects empty name', () async {
    when(() => local.getSession('s1')).thenAnswer((_) async => _session());

    final result = await repository.renameSession(
      const RenameDatasetSessionParams(id: 's1', sessionName: '   '),
    );
    expect(result.isErr, isTrue);
  });

  test('maps CacheException to CacheFailure', () async {
    when(local.getSessions).thenThrow(
      const CacheException(message: 'Hive failure'),
    );

    final result = await repository.getSessions();
    expect(result.isErr, isTrue);
    expect(
      result.fold(onOk: (_) => '', onErr: (f) => f.message),
      'Hive failure',
    );
  });
}
