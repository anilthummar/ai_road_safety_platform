import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset explorer Bloc events (Phase 12.6).
sealed class DatasetExplorerEvent extends Equatable {
  const DatasetExplorerEvent();

  @override
  List<Object?> get props => [];
}

/// Load dashboard aggregates.
final class DatasetExplorerLoadDashboard extends DatasetExplorerEvent {
  const DatasetExplorerLoadDashboard();
}

/// Refresh dashboard.
final class DatasetExplorerRefreshDashboard extends DatasetExplorerEvent {
  const DatasetExplorerRefreshDashboard();
}

/// Load / refresh session list with current query.
final class DatasetExplorerLoadSessions extends DatasetExplorerEvent {
  /// Optional query override.
  final SessionQuery? query;

  /// Creates [DatasetExplorerLoadSessions].
  const DatasetExplorerLoadSessions({this.query});

  @override
  List<Object?> get props => [query];
}

/// Search text changed.
final class DatasetExplorerSearchSession extends DatasetExplorerEvent {
  /// Search text.
  final String query;

  /// Creates [DatasetExplorerSearchSession].
  const DatasetExplorerSearchSession(this.query);

  @override
  List<Object?> get props => [query];
}

/// Apply filter fields.
final class DatasetExplorerFilterSession extends DatasetExplorerEvent {
  /// Date filter.
  final SessionDateFilter dateFilter;

  /// Status filter.
  final DatasetSessionStatus? status;

  /// Min storage.
  final int? minStorageBytes;

  /// Min flood events.
  final int? minFloodEvents;

  /// Creates [DatasetExplorerFilterSession].
  const DatasetExplorerFilterSession({
    this.dateFilter = SessionDateFilter.all,
    this.status,
    this.minStorageBytes,
    this.minFloodEvents,
  });

  @override
  List<Object?> get props =>
      [dateFilter, status, minStorageBytes, minFloodEvents];
}

/// Apply sort.
final class DatasetExplorerSortSession extends DatasetExplorerEvent {
  /// Sort option.
  final SessionSortOption sort;

  /// Creates [DatasetExplorerSortSession].
  const DatasetExplorerSortSession(this.sort);

  @override
  List<Object?> get props => [sort];
}

/// Load next page (infinite scroll).
final class DatasetExplorerLoadMore extends DatasetExplorerEvent {
  const DatasetExplorerLoadMore();
}

/// Open session details.
final class DatasetExplorerOpenSession extends DatasetExplorerEvent {
  /// Session id.
  final String sessionId;

  /// Creates [DatasetExplorerOpenSession].
  const DatasetExplorerOpenSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Delete session.
final class DatasetExplorerDeleteSession extends DatasetExplorerEvent {
  /// Session id.
  final String sessionId;

  /// Creates [DatasetExplorerDeleteSession].
  const DatasetExplorerDeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Rename session.
final class DatasetExplorerRenameSession extends DatasetExplorerEvent {
  /// Params.
  final RenameDatasetSessionParams params;

  /// Creates [DatasetExplorerRenameSession].
  const DatasetExplorerRenameSession(this.params);

  @override
  List<Object?> get props => [params];
}

/// Duplicate session.
final class DatasetExplorerDuplicateSession extends DatasetExplorerEvent {
  /// Session id.
  final String sessionId;

  /// Creates [DatasetExplorerDuplicateSession].
  const DatasetExplorerDuplicateSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
