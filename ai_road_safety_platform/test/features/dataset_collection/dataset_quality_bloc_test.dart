import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_quality_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_quality_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAssess extends Mock implements AssessDatasetQualityUseCase {}

class _MockLoadLast extends Mock implements LoadLastQualityReportUseCase {}

class _MockGetThresholds extends Mock implements GetQualityThresholdsUseCase {}

class _MockUpdateThresholds extends Mock
    implements UpdateQualityThresholdsUseCase {}

class _MockEvaluate extends Mock implements EvaluateQualityGateUseCase {}

void main() {
  late _MockAssess assess;
  late _MockLoadLast loadLast;
  late _MockGetThresholds getThresholds;
  late _MockUpdateThresholds updateThresholds;
  late _MockEvaluate evaluate;

  final report = DatasetQualityAssessmentReport(
    generatedAt: DateTime.utc(2026, 7, 14),
    thresholds: QualityGateThresholds.defaults,
    decision: QualityGateDecision.conditional,
    overallScore: 62,
    trainingAllowed: true,
    gateSummary: 'Conditional',
    dimensions: const [
      DimensionScore(
        dimension: QualityDimension.annotationCoverage,
        score: 60,
        summary: 'ok',
      ),
    ],
    issues: const [],
    sessions: const [],
    labelCoverage: const [],
    captureMetrics: const DatasetQualityMetrics.empty(),
    annotationMetrics: const AnnotationQualityMetrics.empty(),
    totalSessions: 2,
    totalFrames: 40,
    passSessions: 0,
    conditionalSessions: 2,
    failSessions: 0,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const AssessDatasetParams());
    registerFallbackValue(QualityGateThresholds.defaults);
    registerFallbackValue(EvaluateQualityGateParams(report: report));
  });

  setUp(() {
    assess = _MockAssess();
    loadLast = _MockLoadLast();
    getThresholds = _MockGetThresholds();
    updateThresholds = _MockUpdateThresholds();
    evaluate = _MockEvaluate();
    when(() => getThresholds(any()))
        .thenAnswer((_) async => const Ok(QualityGateThresholds.defaults));
    when(() => loadLast(any())).thenAnswer((_) async => const Ok(null));
  });

  DatasetQualityBloc build() => DatasetQualityBloc(
        assessDatasetQuality: assess,
        loadLastQualityReport: loadLast,
        getQualityThresholds: getThresholds,
        updateQualityThresholds: updateThresholds,
        evaluateQualityGate: evaluate,
        logger: AppLogger(),
      );

  blocTest<DatasetQualityBloc, DatasetQualityState>(
    'load with no last report emits empty',
    build: build,
    act: (b) => b.add(const DatasetQualityLoad()),
    expect: () => [
      isA<DatasetQualityLoading>(),
      isA<DatasetQualityEmpty>(),
    ],
  );

  blocTest<DatasetQualityBloc, DatasetQualityState>(
    'assess emits loaded',
    build: build,
    setUp: () {
      when(() => assess(any())).thenAnswer((_) async => Ok(report));
    },
    act: (b) => b.add(const DatasetQualityAssess()),
    expect: () => [
      isA<DatasetQualityLoading>(),
      isA<DatasetQualityLoaded>().having(
        (s) => s.report.decision,
        'decision',
        QualityGateDecision.conditional,
      ),
    ],
  );
}
