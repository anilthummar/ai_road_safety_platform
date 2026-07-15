import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_benchmark_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_benchmark_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadBenchmarkSnapshotUseCase {}

class _MockRun extends Mock implements RunBenchmarkUseCase {}

class _MockDelete extends Mock implements DeleteBenchmarkReportUseCase {}

class _MockDemo extends Mock implements CreateDemoBenchmarkUseCase {}

void main() {
  late _MockLoad load;
  late _MockRun run;
  late _MockDelete delete;
  late _MockDemo demo;

  final report = BenchmarkReport(
    id: 'b1',
    modelId: 'bundled-yolov8n',
    createdAt: DateTime.utc(2026, 7, 14),
    metrics: const BenchmarkMetrics(
      truePositives: 1,
      falsePositives: 0,
      falseNegatives: 0,
      precision: 1,
      recall: 1,
      f1: 1,
      meanIou: 0.9,
      mapProxy: 1,
    ),
  );
  final snap = BenchmarkSnapshot(
    reports: [report],
    generatedAt: DateTime.utc(2026, 7, 14),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const RunBenchmarkParams(modelId: 'x'));
    registerFallbackValue(const DeleteBenchmarkReportParams('x'));
    registerFallbackValue(const CreateDemoBenchmarkParams());
  });

  setUp(() {
    load = _MockLoad();
    run = _MockRun();
    delete = _MockDelete();
    demo = _MockDemo();
    when(() => load(any())).thenAnswer((_) async => Ok(snap));
  });

  ModelBenchmarkBloc build() => ModelBenchmarkBloc(
        loadBenchmarkSnapshot: load,
        runBenchmark: run,
        deleteBenchmarkReport: delete,
        createDemoBenchmark: demo,
        logger: AppLogger(),
      );

  blocTest<ModelBenchmarkBloc, ModelBenchmarkState>(
    'load emits loaded snapshot',
    build: build,
    act: (b) => b.add(const ModelBenchmarkLoad()),
    expect: () => [
      isA<ModelBenchmarkLoading>(),
      isA<ModelBenchmarkLoaded>().having(
        (s) => s.snapshot.totalCount,
        'count',
        1,
      ),
    ],
  );

  blocTest<ModelBenchmarkBloc, ModelBenchmarkState>(
    'demo then reloads',
    build: build,
    setUp: () {
      when(() => demo(any())).thenAnswer((_) async => Ok(report));
    },
    act: (b) => b.add(const ModelBenchmarkCreateDemo()),
    expect: () => [
      isA<ModelBenchmarkLoading>(),
      isA<ModelBenchmarkLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('Demo'),
      ),
    ],
  );
}
