import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/experiment_tracking_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/experiment_tracking_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadExperimentTrackerUseCase {}

class _MockCreate extends Mock implements CreateExperimentRunUseCase {}

class _MockStart extends Mock implements StartExperimentRunUseCase {}

class _MockLogMetric extends Mock implements LogExperimentMetricUseCase {}

class _MockComplete extends Mock implements CompleteExperimentRunUseCase {}

class _MockFail extends Mock implements FailExperimentRunUseCase {}

class _MockCancel extends Mock implements CancelExperimentRunUseCase {}

class _MockDelete extends Mock implements DeleteExperimentRunUseCase {}

class _MockDemo extends Mock implements CreateDemoExperimentRunUseCase {}

void main() {
  late _MockLoad load;
  late _MockCreate create;
  late _MockStart start;
  late _MockLogMetric logMetric;
  late _MockComplete complete;
  late _MockFail fail;
  late _MockCancel cancel;
  late _MockDelete delete;
  late _MockDemo demo;

  final now = DateTime.utc(2026, 7, 14);
  final run = ExperimentRun(
    id: 'r1',
    name: 'Run A',
    status: ExperimentRunStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
  final snap = ExperimentTrackerSnapshot(runs: [run], generatedAt: now);

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CreateExperimentRunParams(name: 'x'),
    );
    registerFallbackValue(const ExperimentRunIdParams('x'));
    registerFallbackValue(
      const LogExperimentMetricParams(runId: 'x', key: 'k', value: 1),
    );
    registerFallbackValue(const FailExperimentRunParams('x'));
  });

  setUp(() {
    load = _MockLoad();
    create = _MockCreate();
    start = _MockStart();
    logMetric = _MockLogMetric();
    complete = _MockComplete();
    fail = _MockFail();
    cancel = _MockCancel();
    delete = _MockDelete();
    demo = _MockDemo();
    when(() => load(any())).thenAnswer((_) async => Ok(snap));
  });

  ExperimentTrackingBloc build() => ExperimentTrackingBloc(
        loadExperimentTracker: load,
        createExperimentRun: create,
        startExperimentRun: start,
        logExperimentMetric: logMetric,
        completeExperimentRun: complete,
        failExperimentRun: fail,
        cancelExperimentRun: cancel,
        deleteExperimentRun: delete,
        createDemoExperimentRun: demo,
        logger: AppLogger(),
      );

  blocTest<ExperimentTrackingBloc, ExperimentTrackingState>(
    'load emits loaded snapshot',
    build: build,
    act: (b) => b.add(const ExperimentTrackingLoad()),
    expect: () => [
      isA<ExperimentTrackingLoading>(),
      isA<ExperimentTrackingLoaded>().having(
        (s) => s.snapshot.totalCount,
        'count',
        1,
      ),
    ],
  );

  blocTest<ExperimentTrackingBloc, ExperimentTrackingState>(
    'start then reloads',
    build: build,
    setUp: () {
      when(() => start(any())).thenAnswer(
        (_) async => Ok(run.copyWith(status: ExperimentRunStatus.running)),
      );
    },
    act: (b) => b.add(const ExperimentTrackingStart('r1')),
    expect: () => [
      isA<ExperimentTrackingLoading>(),
      isA<ExperimentTrackingLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('started'),
      ),
    ],
  );

  blocTest<ExperimentTrackingBloc, ExperimentTrackingState>(
    'demo then reloads',
    build: build,
    setUp: () {
      when(() => demo(any())).thenAnswer(
        (_) async => Ok(
          run.copyWith(
            status: ExperimentRunStatus.completed,
            source: ExperimentRunSource.demo,
          ),
        ),
      );
    },
    act: (b) => b.add(const ExperimentTrackingCreateDemo()),
    expect: () => [
      isA<ExperimentTrackingLoading>(),
      isA<ExperimentTrackingLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('Demo'),
      ),
    ],
  );
}
