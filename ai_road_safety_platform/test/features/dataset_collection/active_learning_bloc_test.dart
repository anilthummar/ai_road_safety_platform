import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/active_learning_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/active_learning_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadActiveLearningSnapshotUseCase {}

class _MockRun extends Mock implements RunActiveLearningSelectionUseCase {}

class _MockDelete extends Mock implements DeleteActiveLearningSelectionUseCase {}

class _MockDemo extends Mock implements CreateDemoActiveLearningUseCase {}

void main() {
  late _MockLoad load;
  late _MockRun run;
  late _MockDelete delete;
  late _MockDemo demo;

  final selection = ActiveLearningSelection(
    id: 'al1',
    createdAt: DateTime.utc(2026, 7, 14),
    config: const ActiveLearningStrategyConfig(topK: 5),
    candidates: const [
      SampleCandidate(
        sessionId: 's',
        frameNumber: 1,
        score: 40,
        reasons: [SamplePriorityReason.unlabeled],
        frameStatus: 'unannotated',
      ),
    ],
    framesConsidered: 4,
  );
  final snap = ActiveLearningSnapshot(
    selections: [selection],
    generatedAt: DateTime.utc(2026, 7, 14),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const RunActiveLearningParams());
    registerFallbackValue(const DeleteActiveLearningParams('x'));
  });

  setUp(() {
    load = _MockLoad();
    run = _MockRun();
    delete = _MockDelete();
    demo = _MockDemo();
    when(() => load(any())).thenAnswer((_) async => Ok(snap));
  });

  ActiveLearningBloc build() => ActiveLearningBloc(
        loadActiveLearningSnapshot: load,
        runActiveLearningSelection: run,
        deleteActiveLearningSelection: delete,
        createDemoActiveLearning: demo,
        logger: AppLogger(),
      );

  blocTest<ActiveLearningBloc, ActiveLearningState>(
    'load emits loaded snapshot',
    build: build,
    act: (b) => b.add(const ActiveLearningLoad()),
    expect: () => [
      isA<ActiveLearningLoading>(),
      isA<ActiveLearningLoaded>().having(
        (s) => s.snapshot.totalSelections,
        'count',
        1,
      ),
    ],
  );

  blocTest<ActiveLearningBloc, ActiveLearningState>(
    'demo then reloads',
    build: build,
    setUp: () {
      when(() => demo(any())).thenAnswer((_) async => Ok(selection));
    },
    act: (b) => b.add(const ActiveLearningCreateDemo()),
    expect: () => [
      isA<ActiveLearningLoading>(),
      isA<ActiveLearningLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('Demo'),
      ),
    ],
  );
}
