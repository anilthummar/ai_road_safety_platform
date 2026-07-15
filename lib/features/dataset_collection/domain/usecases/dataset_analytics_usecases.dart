import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_analytics_repository.dart';
import 'package:equatable/equatable.dart';

/// Shared filter parameter for analytics use cases.
class AnalyticsFilterParams extends Equatable {
  /// Filter.
  final AnalyticsFilter filter;

  /// Creates [AnalyticsFilterParams].
  const AnalyticsFilterParams([this.filter = const AnalyticsFilter()]);

  @override
  List<Object?> get props => [filter];
}

/// Loads full analytics report.
class LoadAnalyticsUseCase
    extends UseCase<Result<DatasetAnalyticsReport>, AnalyticsFilterParams> {
  final DatasetAnalyticsRepository _repository;

  /// Creates [LoadAnalyticsUseCase].
  LoadAnalyticsUseCase(this._repository);

  @override
  Future<Result<DatasetAnalyticsReport>> call(AnalyticsFilterParams params) {
    return _repository.loadAnalytics(filter: params.filter);
  }
}

/// Loads research insights.
class LoadResearchInsightsUseCase
    extends UseCase<Result<ResearchInsights>, AnalyticsFilterParams> {
  final DatasetAnalyticsRepository _repository;

  /// Creates [LoadResearchInsightsUseCase].
  LoadResearchInsightsUseCase(this._repository);

  @override
  Future<Result<ResearchInsights>> call(AnalyticsFilterParams params) {
    return _repository.loadResearchInsights(filter: params.filter);
  }
}

/// Loads storage analytics.
class LoadStorageAnalyticsUseCase
    extends UseCase<Result<StorageAnalytics>, AnalyticsFilterParams> {
  final DatasetAnalyticsRepository _repository;

  /// Creates [LoadStorageAnalyticsUseCase].
  LoadStorageAnalyticsUseCase(this._repository);

  @override
  Future<Result<StorageAnalytics>> call(AnalyticsFilterParams params) {
    return _repository.loadStorageAnalytics(filter: params.filter);
  }
}

/// Loads session analytics.
class LoadSessionAnalyticsUseCase
    extends UseCase<Result<SessionAnalytics>, AnalyticsFilterParams> {
  final DatasetAnalyticsRepository _repository;

  /// Creates [LoadSessionAnalyticsUseCase].
  LoadSessionAnalyticsUseCase(this._repository);

  @override
  Future<Result<SessionAnalytics>> call(AnalyticsFilterParams params) {
    return _repository.loadSessionAnalytics(filter: params.filter);
  }
}

/// Loads location analytics.
class LoadLocationAnalyticsUseCase
    extends UseCase<Result<LocationAnalytics>, AnalyticsFilterParams> {
  final DatasetAnalyticsRepository _repository;

  /// Creates [LoadLocationAnalyticsUseCase].
  LoadLocationAnalyticsUseCase(this._repository);

  @override
  Future<Result<LocationAnalytics>> call(AnalyticsFilterParams params) {
    return _repository.loadLocationAnalytics(filter: params.filter);
  }
}

/// Loads inference analytics.
class LoadInferenceAnalyticsUseCase
    extends UseCase<Result<InferenceAnalytics>, AnalyticsFilterParams> {
  final DatasetAnalyticsRepository _repository;

  /// Creates [LoadInferenceAnalyticsUseCase].
  LoadInferenceAnalyticsUseCase(this._repository);

  @override
  Future<Result<InferenceAnalytics>> call(AnalyticsFilterParams params) {
    return _repository.loadInferenceAnalytics(filter: params.filter);
  }
}
