import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset collection Bloc events (session manager — Phase 12.2).
sealed class DatasetCollectionEvent extends Equatable {
  const DatasetCollectionEvent();

  @override
  List<Object?> get props => [];
}

/// Bootstraps dashboard + restore unfinished session if any.
final class DatasetCollectionInitialize extends DatasetCollectionEvent {
  /// Alias: InitializeSession.
  const DatasetCollectionInitialize();
}

/// Reloads session list / dashboard.
final class DatasetCollectionLoadSessions extends DatasetCollectionEvent {
  const DatasetCollectionLoadSessions();
}

/// Creates an idle session (no recording).
final class DatasetCollectionCreateSession extends DatasetCollectionEvent {
  /// Create params.
  final CreateDatasetSessionParams params;

  /// Creates [DatasetCollectionCreateSession].
  const DatasetCollectionCreateSession(this.params);

  @override
  List<Object?> get props => [params];
}

/// Starts a new recording session.
final class DatasetCollectionStartRecording extends DatasetCollectionEvent {
  /// Session create params (name + description).
  final CreateDatasetSessionParams params;

  /// Creates [DatasetCollectionStartRecording].
  const DatasetCollectionStartRecording(this.params);

  @override
  List<Object?> get props => [params];
}

/// Pauses the active recording.
final class DatasetCollectionPauseRecording extends DatasetCollectionEvent {
  const DatasetCollectionPauseRecording();
}

/// Resumes a paused recording.
final class DatasetCollectionResumeRecording extends DatasetCollectionEvent {
  const DatasetCollectionResumeRecording();
}

/// Stops the active/paused recording.
final class DatasetCollectionStopRecording extends DatasetCollectionEvent {
  const DatasetCollectionStopRecording();
}

/// Cancels / discards the unfinished recording.
final class DatasetCollectionCancelRecording extends DatasetCollectionEvent {
  const DatasetCollectionCancelRecording();
}

/// Continues a restored unfinished session (Resume on dialog).
final class DatasetCollectionRestoreSession extends DatasetCollectionEvent {
  /// When true, resume timer; when false, discard (cancel).
  final bool continueSession;

  /// Creates [DatasetCollectionRestoreSession].
  const DatasetCollectionRestoreSession({required this.continueSession});

  @override
  List<Object?> get props => [continueSession];
}

/// Renames a session.
final class DatasetCollectionRenameSession extends DatasetCollectionEvent {
  /// Rename params.
  final RenameDatasetSessionParams params;

  /// Creates [DatasetCollectionRenameSession].
  const DatasetCollectionRenameSession(this.params);

  @override
  List<Object?> get props => [params];
}

/// Deletes a session.
final class DatasetCollectionDeleteSession extends DatasetCollectionEvent {
  /// Session id.
  final String id;

  /// Creates [DatasetCollectionDeleteSession].
  const DatasetCollectionDeleteSession(this.id);

  @override
  List<Object?> get props => [id];
}

/// Reloads aggregate statistics.
final class DatasetCollectionLoadStatistics extends DatasetCollectionEvent {
  const DatasetCollectionLoadStatistics();
}

/// Reloads storage card.
final class DatasetCollectionRefreshStorage extends DatasetCollectionEvent {
  const DatasetCollectionRefreshStorage();
}

/// Internal: timer tick from [SessionTimerService].
final class DatasetCollectionTimerTicked extends DatasetCollectionEvent {
  /// Elapsed duration.
  final Duration elapsed;

  /// Creates [DatasetCollectionTimerTicked].
  const DatasetCollectionTimerTicked(this.elapsed);

  @override
  List<Object?> get props => [elapsed];
}
