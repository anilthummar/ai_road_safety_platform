import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';

/// Research analytics façade (Phase 12.7).
abstract class DatasetAnalyticsRepository {
  /// Full dashboard report (overview + quality + charts).
  Future<Result<DatasetAnalyticsReport>> loadAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  });

  /// Research insight highlights only.
  Future<Result<ResearchInsights>> loadResearchInsights({
    AnalyticsFilter filter = const AnalyticsFilter(),
  });

  /// Storage analytics slice.
  Future<Result<StorageAnalytics>> loadStorageAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  });

  /// Session distribution analytics.
  Future<Result<SessionAnalytics>> loadSessionAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  });

  /// Location analytics.
  Future<Result<LocationAnalytics>> loadLocationAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  });

  /// Inference / AI analytics.
  Future<Result<InferenceAnalytics>> loadInferenceAnalytics({
    AnalyticsFilter filter = const AnalyticsFilter(),
  });
}
