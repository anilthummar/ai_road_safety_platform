import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';

/// Local Hive + filesystem access for dataset session metadata.
abstract class DatasetCollectionLocalDataSource {
  /// Create + persist a new idle session from params.
  Future<DatasetSession> createSession(CreateDatasetSessionParams params);

  /// Create + persist a session already in [DatasetSessionStatus.recording].
  Future<DatasetSession> startRecordingSession(
    CreateDatasetSessionParams params,
  );

  /// Persist a new session.
  Future<DatasetSession> saveSession(DatasetSession session);

  /// Replace an existing session.
  Future<DatasetSession> updateSession(DatasetSession session);

  /// Delete by id.
  Future<void> deleteSession(String id);

  /// All sessions newest-first.
  Future<List<DatasetSession>> getSessions();

  /// Single session by id.
  Future<DatasetSession> getSession(String id);

  /// Unfinished recording/paused session (most recent), if any.
  Future<DatasetSession?> getActiveSession();

  /// Aggregate statistics from stored sessions.
  Future<DatasetStatistics> getStatistics();

  /// Dataset folder + disk usage.
  Future<DatasetStorage> getStorageInformation();

  /// Remembers the unfinished session id for restore.
  Future<void> setCurrentSessionId(String? id);

  /// Persisted unfinished session id (may be stale — verify via [getActiveSession]).
  Future<String?> getCurrentSessionId();
}
