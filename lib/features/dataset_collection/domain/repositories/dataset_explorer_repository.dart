import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';

/// Read / query façade for the research dashboard (Phase 12.6).
abstract class DatasetExplorerRepository {
  /// Loads dashboard aggregates + recent sessions.
  Future<Result<DatasetDashboardData>> loadDashboard({int recentLimit = 8});

  /// Loads all sessions (unsorted) — prefer [searchSessions] for UI.
  Future<Result<List<DatasetSession>>> loadSessions();

  /// Search + filter + sort + paginate.
  Future<Result<SessionPage>> searchSessions(SessionQuery query);

  /// Filter-only convenience (same pipeline as search).
  Future<Result<SessionPage>> filterSessions(SessionQuery query);

  /// Sort-only convenience (same pipeline as search).
  Future<Result<SessionPage>> sortSessions(SessionQuery query);

  /// Session details + previews.
  Future<Result<SessionDetails>> loadSessionDetails(String sessionId);

  /// Preview image descriptors for a session.
  Future<Result<List<SessionPreviewImage>>> loadPreviewImages(
    String sessionId, {
    int limit = 24,
  });

  /// Renames a session via collection repo.
  Future<Result<DatasetSession>> renameSession(
    RenameDatasetSessionParams params,
  );

  /// Deletes Hive + on-disk session trees.
  Future<Result<void>> deleteSession(String sessionId);

  /// Duplicates session metadata as a new idle session (disk not copied).
  Future<Result<DatasetSession>> duplicateSession(String sessionId);
}
