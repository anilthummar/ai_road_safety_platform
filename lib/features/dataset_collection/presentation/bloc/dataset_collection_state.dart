import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset collection presentation states (session manager — Phase 12.2).
sealed class DatasetCollectionState extends Equatable {
  const DatasetCollectionState();

  @override
  List<Object?> get props => [];
}

/// Cold start.
final class DatasetCollectionInitial extends DatasetCollectionState {
  const DatasetCollectionInitial();
}

/// Full-screen loading.
final class DatasetCollectionLoading extends DatasetCollectionState {
  /// Status text.
  final String message;

  /// Creates [DatasetCollectionLoading].
  const DatasetCollectionLoading({this.message = 'Loading datasets…'});

  @override
  List<Object?> get props => [message];
}

/// Shared dashboard payload for idle / recording / paused / etc.
final class DatasetCollectionDashboardData extends Equatable {
  /// Sessions newest-first.
  final List<DatasetSession> sessions;

  /// Aggregates.
  final DatasetStatistics statistics;

  /// Storage snapshot.
  final DatasetStorage storage;

  /// Active unfinished session when recording/paused.
  final DatasetSession? activeSession;

  /// Live elapsed from [SessionTimerService].
  final Duration elapsed;

  /// Optional snack/banner text.
  final String? statusMessage;

  /// When set, UI should show Continue Previous Session? dialog.
  final DatasetSession? restoreCandidate;

  /// Creates [DatasetCollectionDashboardData].
  const DatasetCollectionDashboardData({
    required this.sessions,
    required this.statistics,
    required this.storage,
    this.activeSession,
    this.elapsed = Duration.zero,
    this.statusMessage,
    this.restoreCandidate,
  });

  /// True when there are no sessions.
  bool get isEmpty => sessions.isEmpty;

  /// Copy helper.
  DatasetCollectionDashboardData copyWith({
    List<DatasetSession>? sessions,
    DatasetStatistics? statistics,
    DatasetStorage? storage,
    DatasetSession? activeSession,
    Duration? elapsed,
    String? statusMessage,
    DatasetSession? restoreCandidate,
    bool clearActive = false,
    bool clearStatus = false,
    bool clearRestore = false,
  }) {
    return DatasetCollectionDashboardData(
      sessions: sessions ?? this.sessions,
      statistics: statistics ?? this.statistics,
      storage: storage ?? this.storage,
      activeSession:
          clearActive ? null : (activeSession ?? this.activeSession),
      elapsed: elapsed ?? this.elapsed,
      statusMessage:
          clearStatus ? null : (statusMessage ?? this.statusMessage),
      restoreCandidate:
          clearRestore ? null : (restoreCandidate ?? this.restoreCandidate),
    );
  }

  @override
  List<Object?> get props => [
        sessions,
        statistics,
        storage,
        activeSession,
        elapsed,
        statusMessage,
        restoreCandidate,
      ];
}

/// Sessions loaded — no active recording (idle dashboard).
final class DatasetCollectionSessionsLoaded extends DatasetCollectionState {
  /// Dashboard payload.
  final DatasetCollectionDashboardData data;

  /// Creates [DatasetCollectionSessionsLoaded].
  const DatasetCollectionSessionsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Explicit empty dashboard (no sessions yet).
final class DatasetCollectionEmpty extends DatasetCollectionState {
  /// Dashboard payload (sessions empty).
  final DatasetCollectionDashboardData data;

  /// Creates [DatasetCollectionEmpty].
  const DatasetCollectionEmpty(this.data);

  @override
  List<Object?> get props => [data];
}

/// Actively recording.
final class DatasetCollectionRecording extends DatasetCollectionState {
  /// Dashboard payload with [DatasetCollectionDashboardData.activeSession].
  final DatasetCollectionDashboardData data;

  /// Creates [DatasetCollectionRecording].
  const DatasetCollectionRecording(this.data);

  @override
  List<Object?> get props => [data];
}

/// Recording paused.
final class DatasetCollectionPaused extends DatasetCollectionState {
  /// Dashboard payload.
  final DatasetCollectionDashboardData data;

  /// Creates [DatasetCollectionPaused].
  const DatasetCollectionPaused(this.data);

  @override
  List<Object?> get props => [data];
}

/// Recording stopped (transient feedback then back to loaded).
final class DatasetCollectionStopped extends DatasetCollectionState {
  /// Stopped session.
  final DatasetSession session;

  /// Creates [DatasetCollectionStopped].
  const DatasetCollectionStopped(this.session);

  @override
  List<Object?> get props => [session];
}

/// Recording completed (transient).
final class DatasetCollectionCompleted extends DatasetCollectionState {
  /// Completed session.
  final DatasetSession session;

  /// Creates [DatasetCollectionCompleted].
  const DatasetCollectionCompleted(this.session);

  @override
  List<Object?> get props => [session];
}

/// Recording cancelled (transient).
final class DatasetCollectionCancelled extends DatasetCollectionState {
  /// Cancelled session.
  final DatasetSession session;

  /// Creates [DatasetCollectionCancelled].
  const DatasetCollectionCancelled(this.session);

  @override
  List<Object?> get props => [session];
}

/// Prompt to continue or discard unfinished session after app restart.
final class DatasetCollectionRestorePrompt extends DatasetCollectionState {
  /// Dashboard + [restoreCandidate].
  final DatasetCollectionDashboardData data;

  /// Creates [DatasetCollectionRestorePrompt].
  const DatasetCollectionRestorePrompt(this.data);

  @override
  List<Object?> get props => [data];
}

/// Creating / mutating (transient full-screen).
final class DatasetCollectionBusy extends DatasetCollectionState {
  /// Status text.
  final String message;

  /// Creates [DatasetCollectionBusy].
  const DatasetCollectionBusy({this.message = 'Working…'});

  @override
  List<Object?> get props => [message];
}

/// Failure.
final class DatasetCollectionError extends DatasetCollectionState {
  /// Domain failure.
  final Failure failure;

  /// Creates [DatasetCollectionError].
  const DatasetCollectionError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Helper to extract dashboard data from recording states.
extension DatasetCollectionStateX on DatasetCollectionState {
  /// Dashboard data when present.
  DatasetCollectionDashboardData? get dashboardOrNull => switch (this) {
        DatasetCollectionSessionsLoaded(:final data) => data,
        DatasetCollectionEmpty(:final data) => data,
        DatasetCollectionRecording(:final data) => data,
        DatasetCollectionPaused(:final data) => data,
        DatasetCollectionRestorePrompt(:final data) => data,
        _ => null,
      };
}
