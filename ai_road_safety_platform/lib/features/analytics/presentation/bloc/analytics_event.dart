import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:equatable/equatable.dart';

/// Analytics presentation events.
sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Load report for the default (weekly) period.
final class AnalyticsStarted extends AnalyticsEvent {
  const AnalyticsStarted();
}

/// Switch weekly / monthly / yearly.
final class AnalyticsPeriodChanged extends AnalyticsEvent {
  /// New period.
  final AnalyticsPeriod period;

  /// Creates [AnalyticsPeriodChanged].
  const AnalyticsPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

/// Manual refresh.
final class AnalyticsRefreshed extends AnalyticsEvent {
  const AnalyticsRefreshed();
}

/// Internal watch update.
final class AnalyticsReportUpdated extends AnalyticsEvent {
  /// Latest report.
  final AnalyticsReport report;

  /// Creates [AnalyticsReportUpdated].
  const AnalyticsReportUpdated(this.report);

  @override
  List<Object?> get props => [report];
}
