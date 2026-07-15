import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset analytics Bloc events (Phase 12.7).
sealed class DatasetAnalyticsEvent extends Equatable {
  const DatasetAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Load full analytics report.
final class DatasetAnalyticsLoad extends DatasetAnalyticsEvent {
  /// Optional filter override.
  final AnalyticsFilter? filter;

  /// Creates [DatasetAnalyticsLoad].
  const DatasetAnalyticsLoad({this.filter});

  @override
  List<Object?> get props => [filter];
}

/// Refresh with current filter.
final class DatasetAnalyticsRefresh extends DatasetAnalyticsEvent {
  const DatasetAnalyticsRefresh();
}

/// Load research insights section (uses cached filter / reload).
final class DatasetAnalyticsLoadResearchInsights
    extends DatasetAnalyticsEvent {
  const DatasetAnalyticsLoadResearchInsights();
}

/// Reload storage analytics (full report refresh).
final class DatasetAnalyticsLoadStorage extends DatasetAnalyticsEvent {
  const DatasetAnalyticsLoadStorage();
}

/// Reload session analytics.
final class DatasetAnalyticsLoadSession extends DatasetAnalyticsEvent {
  const DatasetAnalyticsLoadSession();
}

/// Reload location analytics.
final class DatasetAnalyticsLoadLocation extends DatasetAnalyticsEvent {
  const DatasetAnalyticsLoadLocation();
}

/// Reload inference analytics.
final class DatasetAnalyticsLoadInference extends DatasetAnalyticsEvent {
  const DatasetAnalyticsLoadInference();
}

/// Apply filter / search.
final class DatasetAnalyticsFilter extends DatasetAnalyticsEvent {
  /// New filter.
  final AnalyticsFilter filter;

  /// Creates [DatasetAnalyticsFilter].
  const DatasetAnalyticsFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}
