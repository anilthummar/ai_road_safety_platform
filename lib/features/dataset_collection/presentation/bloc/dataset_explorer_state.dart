import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset explorer presentation states (Phase 12.6).
sealed class DatasetExplorerState extends Equatable {
  const DatasetExplorerState();

  @override
  List<Object?> get props => [];
}

/// Cold start.
final class DatasetExplorerInitial extends DatasetExplorerState {
  const DatasetExplorerInitial();
}

/// Loading.
final class DatasetExplorerLoading extends DatasetExplorerState {
  /// Message.
  final String message;

  /// Creates [DatasetExplorerLoading].
  const DatasetExplorerLoading({this.message = 'Loading…'});

  @override
  List<Object?> get props => [message];
}

/// Dashboard ready.
final class DatasetExplorerDashboardLoaded extends DatasetExplorerState {
  /// Dashboard data.
  final DatasetDashboardData data;

  /// Creates [DatasetExplorerDashboardLoaded].
  const DatasetExplorerDashboardLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Sessions list ready.
final class DatasetExplorerSessionsLoaded extends DatasetExplorerState {
  /// Page.
  final SessionPage page;

  /// Accumulated sessions for infinite scroll.
  final List<DatasetSession> accumulated;

  /// Creates [DatasetExplorerSessionsLoaded].
  const DatasetExplorerSessionsLoaded({
    required this.page,
    required this.accumulated,
  });

  @override
  List<Object?> get props => [page, accumulated];
}

/// Session details opened.
final class DatasetExplorerSessionOpened extends DatasetExplorerState {
  /// Details.
  final SessionDetails details;

  /// Creates [DatasetExplorerSessionOpened].
  const DatasetExplorerSessionOpened(this.details);

  @override
  List<Object?> get props => [details];
}

/// Empty catalogue.
final class DatasetExplorerEmpty extends DatasetExplorerState {
  /// Optional dashboard still useful for storage chrome.
  final DatasetDashboardData? dashboard;

  /// Creates [DatasetExplorerEmpty].
  const DatasetExplorerEmpty({this.dashboard});

  @override
  List<Object?> get props => [dashboard];
}

/// Failure.
final class DatasetExplorerError extends DatasetExplorerState {
  /// Failure.
  final Failure failure;

  /// Creates [DatasetExplorerError].
  const DatasetExplorerError(this.failure);

  @override
  List<Object?> get props => [failure];
}
