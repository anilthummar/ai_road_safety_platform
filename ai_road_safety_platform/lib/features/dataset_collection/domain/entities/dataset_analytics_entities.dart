import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:equatable/equatable.dart';

/// Analytics date window (Phase 12.7).
enum AnalyticsDateFilter {
  /// All sessions.
  all,

  /// Calendar today.
  today,

  /// Calendar yesterday.
  yesterday,

  /// Rolling last 7 days.
  last7Days,

  /// Rolling last 30 days.
  last30Days,

  /// Inclusive custom range ([AnalyticsFilter.customStart]/[AnalyticsFilter.customEnd]).
  custom,
}

/// Named chart series point.
class AnalyticsChartPoint extends Equatable {
  /// Axis label.
  final String label;

  /// Numeric value.
  final double value;

  /// Optional category key.
  final String? category;

  /// Creates [AnalyticsChartPoint].
  const AnalyticsChartPoint({
    required this.label,
    required this.value,
    this.category,
  });

  @override
  List<Object?> get props => [label, value, category];
}

/// Filter / search applied before aggregation.
class AnalyticsFilter extends Equatable {
  /// Date window.
  final AnalyticsDateFilter dateFilter;

  /// Custom range start (inclusive day).
  final DateTime? customStart;

  /// Custom range end (inclusive day).
  final DateTime? customEnd;

  /// Optional status filter.
  final DatasetSessionStatus? status;

  /// Minimum flood events (`null` = any).
  final int? minFloodEvents;

  /// Free-text search (name / status / date ISO).
  final String searchQuery;

  /// Creates [AnalyticsFilter].
  const AnalyticsFilter({
    this.dateFilter = AnalyticsDateFilter.all,
    this.customStart,
    this.customEnd,
    this.status,
    this.minFloodEvents,
    this.searchQuery = '',
  });

  /// Copy helper.
  AnalyticsFilter copyWith({
    AnalyticsDateFilter? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    DatasetSessionStatus? status,
    int? minFloodEvents,
    String? searchQuery,
    bool clearStatus = false,
    bool clearMinFlood = false,
    bool clearCustom = false,
  }) {
    return AnalyticsFilter(
      dateFilter: dateFilter ?? this.dateFilter,
      customStart: clearCustom ? null : (customStart ?? this.customStart),
      customEnd: clearCustom ? null : (customEnd ?? this.customEnd),
      status: clearStatus ? null : (status ?? this.status),
      minFloodEvents:
          clearMinFlood ? null : (minFloodEvents ?? this.minFloodEvents),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        dateFilter,
        customStart,
        customEnd,
        status,
        minFloodEvents,
        searchQuery,
      ];
}

/// Top-level KPI strip for the research analytics dashboard.
class DatasetAnalyticsOverview extends Equatable {
  final int totalSessions;
  final int totalFrames;
  final Duration totalRecordingTime;
  final int totalFloodEvents;
  final Duration averageRecordingDuration;
  final double averageSpeed;
  final double averageFloodConfidence;
  final double averageWaterCoverage;
  final int storageUsedBytes;
  final int storageRemainingSoftBytes;
  final List<AnalyticsChartPoint> datasetGrowth;

  /// Creates [DatasetAnalyticsOverview].
  const DatasetAnalyticsOverview({
    required this.totalSessions,
    required this.totalFrames,
    required this.totalRecordingTime,
    required this.totalFloodEvents,
    required this.averageRecordingDuration,
    required this.averageSpeed,
    required this.averageFloodConfidence,
    required this.averageWaterCoverage,
    required this.storageUsedBytes,
    required this.storageRemainingSoftBytes,
    required this.datasetGrowth,
  });

  const DatasetAnalyticsOverview.empty()
      : totalSessions = 0,
        totalFrames = 0,
        totalRecordingTime = Duration.zero,
        totalFloodEvents = 0,
        averageRecordingDuration = Duration.zero,
        averageSpeed = 0,
        averageFloodConfidence = 0,
        averageWaterCoverage = 0,
        storageUsedBytes = 0,
        storageRemainingSoftBytes = 0,
        datasetGrowth = const [];

  @override
  List<Object?> get props => [
        totalSessions,
        totalFrames,
        totalRecordingTime,
        totalFloodEvents,
        averageRecordingDuration,
        averageSpeed,
        averageFloodConfidence,
        averageWaterCoverage,
        storageUsedBytes,
        storageRemainingSoftBytes,
        datasetGrowth,
      ];
}

/// Dataset quality / completeness metrics.
class DatasetQualityMetrics extends Equatable {
  final double framesPerSession;
  final double framesPerMinute;
  final double captureFrequencyHz;
  final double captureSuccessRate;
  final double averageCaptureIntervalSeconds;
  final double completenessScore;
  final int missingMetadataCount;
  final int corruptedFrameCount;
  final int emptySessionCount;

  /// Creates [DatasetQualityMetrics].
  const DatasetQualityMetrics({
    required this.framesPerSession,
    required this.framesPerMinute,
    required this.captureFrequencyHz,
    required this.captureSuccessRate,
    required this.averageCaptureIntervalSeconds,
    required this.completenessScore,
    required this.missingMetadataCount,
    required this.corruptedFrameCount,
    required this.emptySessionCount,
  });

  const DatasetQualityMetrics.empty()
      : framesPerSession = 0,
        framesPerMinute = 0,
        captureFrequencyHz = 0,
        captureSuccessRate = 0,
        averageCaptureIntervalSeconds = 0,
        completenessScore = 0,
        missingMetadataCount = 0,
        corruptedFrameCount = 0,
        emptySessionCount = 0;

  @override
  List<Object?> get props => [
        framesPerSession,
        framesPerMinute,
        captureFrequencyHz,
        captureSuccessRate,
        averageCaptureIntervalSeconds,
        completenessScore,
        missingMetadataCount,
        corruptedFrameCount,
        emptySessionCount,
      ];
}

/// Research insight highlight.
class ResearchInsight extends Equatable {
  final String title;
  final String value;
  final String subtitle;
  final String? sessionId;

  /// Creates [ResearchInsight].
  const ResearchInsight({
    required this.title,
    required this.value,
    required this.subtitle,
    this.sessionId,
  });

  @override
  List<Object?> get props => [title, value, subtitle, sessionId];
}

/// Bundle of research insights.
class ResearchInsights extends Equatable {
  final List<ResearchInsight> insights;

  /// Creates [ResearchInsights].
  const ResearchInsights({required this.insights});

  const ResearchInsights.empty() : insights = const [];

  @override
  List<Object?> get props => [insights];
}

/// Location-oriented aggregates (session + sampled metadata).
class LocationAnalytics extends Equatable {
  final int totalGpsPoints;
  final double averageSpeed;
  final double distanceCoveredKm;
  final int sessionsWithGps;
  final int sessionsWithoutGps;
  final List<AnalyticsChartPoint> accuracyDistribution;

  /// Creates [LocationAnalytics].
  const LocationAnalytics({
    required this.totalGpsPoints,
    required this.averageSpeed,
    required this.distanceCoveredKm,
    required this.sessionsWithGps,
    required this.sessionsWithoutGps,
    required this.accuracyDistribution,
  });

  const LocationAnalytics.empty()
      : totalGpsPoints = 0,
        averageSpeed = 0,
        distanceCoveredKm = 0,
        sessionsWithGps = 0,
        sessionsWithoutGps = 0,
        accuracyDistribution = const [];

  @override
  List<Object?> get props => [
        totalGpsPoints,
        averageSpeed,
        distanceCoveredKm,
        sessionsWithGps,
        sessionsWithoutGps,
        accuracyDistribution,
      ];
}

/// AI / inference aggregates.
class InferenceAnalytics extends Equatable {
  final double averageInferenceTimeMs;
  final double averageFloodConfidence;
  final int floodDetectionCount;
  final List<AnalyticsChartPoint> riskLevelDistribution;
  final List<AnalyticsChartPoint> waterCoverageDistribution;

  /// Creates [InferenceAnalytics].
  const InferenceAnalytics({
    required this.averageInferenceTimeMs,
    required this.averageFloodConfidence,
    required this.floodDetectionCount,
    required this.riskLevelDistribution,
    required this.waterCoverageDistribution,
  });

  const InferenceAnalytics.empty()
      : averageInferenceTimeMs = 0,
        averageFloodConfidence = 0,
        floodDetectionCount = 0,
        riskLevelDistribution = const [],
        waterCoverageDistribution = const [];

  @override
  List<Object?> get props => [
        averageInferenceTimeMs,
        averageFloodConfidence,
        floodDetectionCount,
        riskLevelDistribution,
        waterCoverageDistribution,
      ];
}

/// Session distribution analytics.
class SessionAnalytics extends Equatable {
  final List<AnalyticsChartPoint> durationDistribution;
  final List<AnalyticsChartPoint> frameCountDistribution;
  final List<AnalyticsChartPoint> storageDistribution;
  final List<AnalyticsChartPoint> recordingFrequency;
  final List<AnalyticsChartPoint> sessionTimeline;
  final List<AnalyticsChartPoint> statusDistribution;

  /// Creates [SessionAnalytics].
  const SessionAnalytics({
    required this.durationDistribution,
    required this.frameCountDistribution,
    required this.storageDistribution,
    required this.recordingFrequency,
    required this.sessionTimeline,
    required this.statusDistribution,
  });

  const SessionAnalytics.empty()
      : durationDistribution = const [],
        frameCountDistribution = const [],
        storageDistribution = const [],
        recordingFrequency = const [],
        sessionTimeline = const [],
        statusDistribution = const [];

  @override
  List<Object?> get props => [
        durationDistribution,
        frameCountDistribution,
        storageDistribution,
        recordingFrequency,
        sessionTimeline,
        statusDistribution,
      ];
}

/// Storage breakdown analytics.
class StorageAnalytics extends Equatable {
  final int totalStorageBytes;
  final int imagesStorageBytes;
  final int metadataStorageBytes;
  final int cacheSizeBytes;
  final int temporaryFilesBytes;
  final double averageSessionSizeBytes;
  final int remainingSoftBudgetBytes;
  final List<AnalyticsChartPoint> breakdown;

  /// Creates [StorageAnalytics].
  const StorageAnalytics({
    required this.totalStorageBytes,
    required this.imagesStorageBytes,
    required this.metadataStorageBytes,
    required this.cacheSizeBytes,
    required this.temporaryFilesBytes,
    required this.averageSessionSizeBytes,
    required this.remainingSoftBudgetBytes,
    required this.breakdown,
  });

  const StorageAnalytics.empty()
      : totalStorageBytes = 0,
        imagesStorageBytes = 0,
        metadataStorageBytes = 0,
        cacheSizeBytes = 0,
        temporaryFilesBytes = 0,
        averageSessionSizeBytes = 0,
        remainingSoftBudgetBytes = 0,
        breakdown = const [];

  @override
  List<Object?> get props => [
        totalStorageBytes,
        imagesStorageBytes,
        metadataStorageBytes,
        cacheSizeBytes,
        temporaryFilesBytes,
        averageSessionSizeBytes,
        remainingSoftBudgetBytes,
        breakdown,
      ];
}

/// Full research analytics payload.
class DatasetAnalyticsReport extends Equatable {
  final AnalyticsFilter filter;
  final DatasetAnalyticsOverview overview;
  final DatasetQualityMetrics quality;
  final ResearchInsights insights;
  final LocationAnalytics location;
  final InferenceAnalytics inference;
  final SessionAnalytics sessions;
  final StorageAnalytics storage;
  final DateTime generatedAt;
  final int matchedSessionCount;

  /// Creates [DatasetAnalyticsReport].
  const DatasetAnalyticsReport({
    required this.filter,
    required this.overview,
    required this.quality,
    required this.insights,
    required this.location,
    required this.inference,
    required this.sessions,
    required this.storage,
    required this.generatedAt,
    required this.matchedSessionCount,
  });

  bool get isEmpty => matchedSessionCount == 0;

  @override
  List<Object?> get props => [
        filter,
        overview,
        quality,
        insights,
        location,
        inference,
        sessions,
        storage,
        generatedAt,
        matchedSessionCount,
      ];
}

/// Optional sampled frame inference/location for richer analytics.
class AnalyticsFrameSample extends Equatable {
  final String sessionId;
  final bool hasGps;
  final double accuracyMeters;
  final double inferenceTimeMs;
  final double confidence;
  final double waterCoverage;
  final String riskLevel;
  final bool inferenceAvailable;

  /// Creates [AnalyticsFrameSample].
  const AnalyticsFrameSample({
    required this.sessionId,
    required this.hasGps,
    required this.accuracyMeters,
    required this.inferenceTimeMs,
    required this.confidence,
    required this.waterCoverage,
    required this.riskLevel,
    required this.inferenceAvailable,
  });

  @override
  List<Object?> get props => [
        sessionId,
        hasGps,
        accuracyMeters,
        inferenceTimeMs,
        confidence,
        waterCoverage,
        riskLevel,
        inferenceAvailable,
      ];
}

/// Disk recovery summary per session used by quality scoring.
class AnalyticsRecoverySnapshot extends Equatable {
  final String sessionId;
  final int imageCount;
  final int metadataCount;
  final bool isIncomplete;

  /// Creates [AnalyticsRecoverySnapshot].
  const AnalyticsRecoverySnapshot({
    required this.sessionId,
    required this.imageCount,
    required this.metadataCount,
    required this.isIncomplete,
  });

  @override
  List<Object?> get props =>
      [sessionId, imageCount, metadataCount, isIncomplete];
}
