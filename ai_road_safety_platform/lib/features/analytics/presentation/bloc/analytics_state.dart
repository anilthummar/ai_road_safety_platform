import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:equatable/equatable.dart';

/// Analytics presentation states.
sealed class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Initial.
final class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

/// Loading.
final class AnalyticsLoading extends AnalyticsState {
  /// Status.
  final String message;

  /// Creates [AnalyticsLoading].
  const AnalyticsLoading({this.message = 'Computing analytics…'});

  @override
  List<Object?> get props => [message];
}

/// Report ready.
final class AnalyticsLoaded extends AnalyticsState {
  /// Selected period.
  final AnalyticsPeriod period;

  /// Aggregated report.
  final AnalyticsReport report;

  /// Creates [AnalyticsLoaded].
  const AnalyticsLoaded({
    required this.period,
    required this.report,
  });

  @override
  List<Object?> get props => [period, report];
}

/// Failure.
final class AnalyticsError extends AnalyticsState {
  /// Failure.
  final Failure failure;

  /// Creates [AnalyticsError].
  const AnalyticsError(this.failure);

  @override
  List<Object?> get props => [failure];
}
