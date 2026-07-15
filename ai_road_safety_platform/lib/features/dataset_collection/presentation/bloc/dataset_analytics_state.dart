import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset analytics presentation states (Phase 12.7).
sealed class DatasetAnalyticsState extends Equatable {
  const DatasetAnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Cold start.
final class DatasetAnalyticsInitial extends DatasetAnalyticsState {
  const DatasetAnalyticsInitial();
}

/// Loading.
final class DatasetAnalyticsLoading extends DatasetAnalyticsState {
  /// Message.
  final String message;

  /// Creates [DatasetAnalyticsLoading].
  const DatasetAnalyticsLoading({this.message = 'Computing analytics…'});

  @override
  List<Object?> get props => [message];
}

/// Report ready.
final class DatasetAnalyticsLoaded extends DatasetAnalyticsState {
  /// Full report.
  final DatasetAnalyticsReport report;

  /// Creates [DatasetAnalyticsLoaded].
  const DatasetAnalyticsLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

/// No matching sessions.
final class DatasetAnalyticsEmpty extends DatasetAnalyticsState {
  /// Filter that produced empty set.
  final AnalyticsFilter filter;

  /// Creates [DatasetAnalyticsEmpty].
  const DatasetAnalyticsEmpty({this.filter = const AnalyticsFilter()});

  @override
  List<Object?> get props => [filter];
}

/// Failure.
final class DatasetAnalyticsError extends DatasetAnalyticsState {
  /// Failure.
  final Failure failure;

  /// Creates [DatasetAnalyticsError].
  const DatasetAnalyticsError(this.failure);

  @override
  List<Object?> get props => [failure];
}
