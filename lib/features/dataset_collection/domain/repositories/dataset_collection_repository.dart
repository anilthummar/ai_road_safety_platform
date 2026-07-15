import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';

/// Domain contract for dataset session metadata + recording lifecycle (12.2).
abstract class DatasetCollectionRepository {
  /// Creates an idle session (no recording).
  Future<Result<DatasetSession>> createSession(CreateDatasetSessionParams params);

  /// Creates a session and immediately starts recording.
  Future<Result<DatasetSession>> startSession(CreateDatasetSessionParams params);

  /// Pauses the active recording session (persists [elapsed]).
  Future<Result<DatasetSession>> pauseSession({required Duration elapsed});

  /// Resumes the paused session.
  Future<Result<DatasetSession>> resumeSession();

  /// Stops the active/paused session (status → stopped).
  Future<Result<DatasetSession>> stopSession({required Duration elapsed});

  /// Cancels the active/paused session.
  Future<Result<DatasetSession>> cancelSession({required Duration elapsed});

  /// Marks an unfinished session completed (status → completed).
  Future<Result<DatasetSession>> completeSession({required Duration elapsed});

  /// Renames an existing session.
  Future<Result<DatasetSession>> renameSession(RenameDatasetSessionParams params);

  /// Deletes a session by id (blocked while recording/paused).
  Future<Result<void>> deleteSession(String id);

  /// Alias of [getSessions] for recording manager API.
  Future<Result<List<DatasetSession>>> getAllSessions();

  /// All sessions newest-first.
  Future<Result<List<DatasetSession>>> getSessions();

  /// Single session by id.
  Future<Result<DatasetSession>> getSession(String id);

  /// Unfinished session (recording or paused), if any.
  Future<Result<DatasetSession?>> getActiveSession();

  /// Same as [getActiveSession] — restore entry point.
  Future<Result<DatasetSession?>> loadCurrentSession();

  /// Replaces session metadata after validation.
  Future<Result<DatasetSession>> updateSession(DatasetSession session);

  /// Aggregate stats computed from local sessions.
  Future<Result<DatasetStatistics>> getStatistics();

  /// Dataset folder + disk usage snapshot.
  Future<Result<DatasetStorage>> getStorageInformation();
}
