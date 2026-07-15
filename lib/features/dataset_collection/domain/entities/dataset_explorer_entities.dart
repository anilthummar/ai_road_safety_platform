import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:equatable/equatable.dart';

/// Time-window filter for the session explorer (Phase 12.6).
enum SessionDateFilter {
  /// No date limit.
  all,

  /// Calendar today.
  today,

  /// Calendar yesterday.
  yesterday,

  /// Rolling last 7 days.
  last7Days,

  /// Rolling last 30 days.
  lastMonth,
}

/// Sort keys for the explorer list.
enum SessionSortOption {
  /// Newest created first.
  newest,

  /// Oldest created first.
  oldest,

  /// Highest [DatasetSession.totalStorage].
  largestDataset,

  /// Highest [DatasetSession.frameCount].
  mostFrames,

  /// Longest [DatasetSession.duration].
  longestDuration,

  /// Highest flood event count.
  highestFloodEvents,
}

/// Explorer query (search + filter + sort + pagination).
class SessionQuery extends Equatable {
  /// Free-text query (name / description / status).
  final String searchQuery;

  /// Date window.
  final SessionDateFilter dateFilter;

  /// Optional status filter (`null` = any).
  final DatasetSessionStatus? status;

  /// Minimum storage bytes (`null` = any).
  final int? minStorageBytes;

  /// Minimum flood events (`null` = any).
  final int? minFloodEvents;

  /// Sort option.
  final SessionSortOption sort;

  /// Page index (0-based) for pagination.
  final int page;

  /// Page size.
  final int pageSize;

  /// Creates [SessionQuery].
  const SessionQuery({
    this.searchQuery = '',
    this.dateFilter = SessionDateFilter.all,
    this.status,
    this.minStorageBytes,
    this.minFloodEvents,
    this.sort = SessionSortOption.newest,
    this.page = 0,
    this.pageSize = 20,
  });

  /// Copy helper.
  SessionQuery copyWith({
    String? searchQuery,
    SessionDateFilter? dateFilter,
    DatasetSessionStatus? status,
    int? minStorageBytes,
    int? minFloodEvents,
    SessionSortOption? sort,
    int? page,
    int? pageSize,
    bool clearStatus = false,
    bool clearMinStorage = false,
    bool clearMinFlood = false,
  }) {
    return SessionQuery(
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: dateFilter ?? this.dateFilter,
      status: clearStatus ? null : (status ?? this.status),
      minStorageBytes:
          clearMinStorage ? null : (minStorageBytes ?? this.minStorageBytes),
      minFloodEvents:
          clearMinFlood ? null : (minFloodEvents ?? this.minFloodEvents),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        dateFilter,
        status,
        minStorageBytes,
        minFloodEvents,
        sort,
        page,
        pageSize,
      ];
}

/// Aggregate dashboard payload for researchers.
class DatasetDashboardData extends Equatable {
  /// Aggregate stats.
  final DatasetStatistics statistics;

  /// Hive folder storage snapshot.
  final DatasetStorage collectionStorage;

  /// Soft-budget disk usage from file tree.
  final StorageUsage diskUsage;

  /// Recent sessions (newest-first, capped).
  final List<DatasetSession> recentSessions;

  /// Unfinished recording session if any.
  final DatasetSession? activeSession;

  /// Total recording duration across all sessions.
  final Duration totalRecordingTime;

  /// Frames per minute across completed duration (0 if none).
  final double framesPerMinute;

  /// Average flood coverage across sessions.
  final double averageFloodCoverage;

  /// Creates [DatasetDashboardData].
  const DatasetDashboardData({
    required this.statistics,
    required this.collectionStorage,
    required this.diskUsage,
    required this.recentSessions,
    required this.totalRecordingTime,
    required this.framesPerMinute,
    required this.averageFloodCoverage,
    this.activeSession,
  });

  @override
  List<Object?> get props => [
        statistics,
        collectionStorage,
        diskUsage,
        recentSessions,
        activeSession,
        totalRecordingTime,
        framesPerMinute,
        averageFloodCoverage,
      ];
}

/// Paginated explorer result.
class SessionPage extends Equatable {
  /// Page items.
  final List<DatasetSession> sessions;

  /// Total matching (pre-pagination).
  final int totalCount;

  /// Query used.
  final SessionQuery query;

  /// Creates [SessionPage].
  const SessionPage({
    required this.sessions,
    required this.totalCount,
    required this.query,
  });

  /// Whether more pages exist.
  bool get hasMore =>
      (query.page + 1) * query.pageSize < totalCount;

  @override
  List<Object?> get props => [sessions, totalCount, query];
}

/// Preview thumbnail entry.
class SessionPreviewImage extends Equatable {
  /// Frame number.
  final int frameNumber;

  /// Absolute thumbnail path when on disk.
  final String? thumbnailPath;

  /// Absolute original path when thumbnail missing.
  final String? originalPath;

  /// Creates [SessionPreviewImage].
  const SessionPreviewImage({
    required this.frameNumber,
    this.thumbnailPath,
    this.originalPath,
  });

  @override
  List<Object?> get props => [frameNumber, thumbnailPath, originalPath];
}

/// Session details + preview/metadata summary.
class SessionDetails extends Equatable {
  /// Session row.
  final DatasetSession session;

  /// Disk bytes under session folder (0 if missing).
  final int diskBytes;

  /// Preview images (lazy-friendly list).
  final List<SessionPreviewImage> previews;

  /// Last frame metadata summary line (optional).
  final String? metadataSummary;

  /// Capture rate estimate (frames / minutes of duration).
  final double captureRateFpm;

  /// Recovery incompleteness flag.
  final bool isIncompleteOnDisk;

  /// Creates [SessionDetails].
  const SessionDetails({
    required this.session,
    required this.diskBytes,
    required this.previews,
    required this.captureRateFpm,
    this.metadataSummary,
    this.isIncompleteOnDisk = false,
  });

  @override
  List<Object?> get props => [
        session,
        diskBytes,
        previews,
        metadataSummary,
        captureRateFpm,
        isIncompleteOnDisk,
      ];
}
