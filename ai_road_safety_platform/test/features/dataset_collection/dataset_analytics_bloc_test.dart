import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_analytics_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_analytics_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadAnalyticsUseCase {}

DatasetAnalyticsReport _report({int sessions = 1}) {
  return DatasetAnalyticsReport(
    filter: const AnalyticsFilter(),
    overview: DatasetAnalyticsOverview(
      totalSessions: sessions,
      totalFrames: 10,
      totalRecordingTime: const Duration(minutes: 1),
      totalFloodEvents: 1,
      averageRecordingDuration: const Duration(minutes: 1),
      averageSpeed: 10,
      averageFloodConfidence: 0.5,
      averageWaterCoverage: 5,
      storageUsedBytes: 100,
      storageRemainingSoftBytes: 900,
      datasetGrowth: const [
        AnalyticsChartPoint(label: '07-14', value: 10),
      ],
    ),
    quality: const DatasetQualityMetrics.empty(),
    insights: const ResearchInsights(
      insights: [
        ResearchInsight(
          title: 'Longest recording',
          value: '01:00',
          subtitle: 'S1',
        ),
      ],
    ),
    location: const LocationAnalytics.empty(),
    inference: const InferenceAnalytics.empty(),
    sessions: const SessionAnalytics.empty(),
    storage: const StorageAnalytics.empty(),
    generatedAt: DateTime.utc(2026, 7, 14),
    matchedSessionCount: sessions,
  );
}

void main() {
  late _MockLoad load;

  setUpAll(() {
    registerFallbackValue(const AnalyticsFilterParams());
  });

  setUp(() {
    load = _MockLoad();
  });

  DatasetAnalyticsBloc build() => DatasetAnalyticsBloc(
        loadAnalytics: load,
        logger: AppLogger(),
      );

  blocTest<DatasetAnalyticsBloc, DatasetAnalyticsState>(
    'Load emits Loaded',
    build: () {
      when(() => load(any())).thenAnswer((_) async => Ok(_report()));
      return build();
    },
    act: (b) => b.add(const DatasetAnalyticsLoad()),
    expect: () => [
      isA<DatasetAnalyticsLoading>(),
      isA<DatasetAnalyticsLoaded>(),
    ],
  );

  blocTest<DatasetAnalyticsBloc, DatasetAnalyticsState>(
    'Load emits Empty when no sessions',
    build: () {
      when(() => load(any()))
          .thenAnswer((_) async => Ok(_report(sessions: 0)));
      return build();
    },
    act: (b) => b.add(const DatasetAnalyticsLoad()),
    expect: () => [
      isA<DatasetAnalyticsLoading>(),
      isA<DatasetAnalyticsEmpty>(),
    ],
  );

  blocTest<DatasetAnalyticsBloc, DatasetAnalyticsState>(
    'Filter applies and reloads',
    build: () {
      when(() => load(any())).thenAnswer((_) async => Ok(_report()));
      return build();
    },
    act: (b) => b.add(
      const DatasetAnalyticsFilter(
        AnalyticsFilter(dateFilter: AnalyticsDateFilter.last7Days),
      ),
    ),
    expect: () => [
      isA<DatasetAnalyticsLoading>(),
      isA<DatasetAnalyticsLoaded>(),
    ],
    verify: (_) {
      final captured = verify(() => load(captureAny())).captured.single
          as AnalyticsFilterParams;
      expect(captured.filter.dateFilter, AnalyticsDateFilter.last7Days);
    },
  );

  blocTest<DatasetAnalyticsBloc, DatasetAnalyticsState>(
    'Load error',
    build: () {
      when(() => load(any())).thenAnswer(
        (_) async => const Err(CacheFailure(message: 'fail')),
      );
      return build();
    },
    act: (b) => b.add(const DatasetAnalyticsLoad()),
    expect: () => [
      isA<DatasetAnalyticsLoading>(),
      isA<DatasetAnalyticsError>(),
    ],
  );
}
