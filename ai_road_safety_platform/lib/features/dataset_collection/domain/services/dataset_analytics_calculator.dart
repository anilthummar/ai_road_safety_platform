import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';

/// Pure aggregation engine for research analytics (Phase 12.7).
///
/// No I/O — callers supply already-loaded sessions, storage, recovery, and
/// optional frame samples. Background isolation is a placeholder for later.
class DatasetAnalyticsCalculator {
  /// Creates [DatasetAnalyticsCalculator].
  const DatasetAnalyticsCalculator();

  /// Builds a full [DatasetAnalyticsReport].
  DatasetAnalyticsReport build({
    required List<DatasetSession> sessions,
    required StorageUsage usage,
    required List<FolderInfo> folders,
    required AnalyticsFilter filter,
    List<AnalyticsRecoverySnapshot> recovery = const [],
    List<AnalyticsFrameSample> samples = const [],
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final filtered = applyFilter(sessions, filter, now: clock);
    final recoveryById = {
      for (final r in recovery) r.sessionId: r,
    };

    final overview = _overview(filtered, usage);
    final quality = _quality(filtered, recoveryById);
    final insights = _insights(filtered);
    final location = _location(filtered, samples);
    final inference = _inference(filtered, samples);
    final sessionAnalytics = _sessions(filtered);
    final storage = _storage(filtered, usage, folders);

    return DatasetAnalyticsReport(
      filter: filter,
      overview: overview,
      quality: quality,
      insights: insights,
      location: location,
      inference: inference,
      sessions: sessionAnalytics,
      storage: storage,
      generatedAt: clock,
      matchedSessionCount: filtered.length,
    );
  }

  /// Applies date / status / flood / search filters.
  List<DatasetSession> applyFilter(
    List<DatasetSession> source,
    AnalyticsFilter filter, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    var list = List<DatasetSession>.from(source);

    final q = filter.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.sessionName.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.status.label.toLowerCase().contains(q) ||
            s.createdAt.toIso8601String().contains(q) ||
            s.id.toLowerCase().contains(q);
      }).toList();
    }

    list = list.where((s) => _matchesDate(s.createdAt, filter, clock)).toList();

    if (filter.status != null) {
      list = list.where((s) => s.status == filter.status).toList();
    }
    if (filter.minFloodEvents != null) {
      list = list
          .where((s) => s.floodEventCount >= filter.minFloodEvents!)
          .toList();
    }
    return list;
  }

  bool _matchesDate(
    DateTime createdAt,
    AnalyticsFilter filter,
    DateTime now,
  ) {
    final d = createdAt.toLocal();
    final localNow = now.toLocal();
    return switch (filter.dateFilter) {
      AnalyticsDateFilter.all => true,
      AnalyticsDateFilter.today => _sameDay(d, localNow),
      AnalyticsDateFilter.yesterday =>
        _sameDay(d, localNow.subtract(const Duration(days: 1))),
      AnalyticsDateFilter.last7Days =>
        d.isAfter(localNow.subtract(const Duration(days: 7))),
      AnalyticsDateFilter.last30Days =>
        d.isAfter(localNow.subtract(const Duration(days: 30))),
      AnalyticsDateFilter.custom => () {
          final start = filter.customStart;
          final end = filter.customEnd;
          if (start == null || end == null) return true;
          final day = DateTime(d.year, d.month, d.day);
          final s = DateTime(start.year, start.month, start.day);
          final e = DateTime(end.year, end.month, end.day)
              .add(const Duration(days: 1));
          return !day.isBefore(s) && day.isBefore(e);
        }(),
    };
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DatasetAnalyticsOverview _overview(
    List<DatasetSession> sessions,
    StorageUsage usage,
  ) {
    if (sessions.isEmpty) {
      return DatasetAnalyticsOverview(
        totalSessions: 0,
        totalFrames: 0,
        totalRecordingTime: Duration.zero,
        totalFloodEvents: 0,
        averageRecordingDuration: Duration.zero,
        averageSpeed: 0,
        averageFloodConfidence: 0,
        averageWaterCoverage: 0,
        storageUsedBytes: usage.usedBytes,
        storageRemainingSoftBytes:
            (usage.softLimitBytes - usage.usedBytes).clamp(0, 1 << 62),
        datasetGrowth: const [],
      );
    }

    final totalFrames =
        sessions.fold<int>(0, (a, s) => a + s.frameCount);
    final totalFlood =
        sessions.fold<int>(0, (a, s) => a + s.floodEventCount);
    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (a, s) => a + s.duration,
    );
    final avgDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ sessions.length,
    );
    final avgSpeed =
        sessions.fold<double>(0, (a, s) => a + s.averageSpeed) /
            sessions.length;
    final avgConf =
        sessions.fold<double>(0, (a, s) => a + s.averageConfidence) /
            sessions.length;
    final avgCover =
        sessions.fold<double>(0, (a, s) => a + s.averageFloodCoverage) /
            sessions.length;

    return DatasetAnalyticsOverview(
      totalSessions: sessions.length,
      totalFrames: totalFrames,
      totalRecordingTime: totalDuration,
      totalFloodEvents: totalFlood,
      averageRecordingDuration: avgDuration,
      averageSpeed: avgSpeed,
      averageFloodConfidence: avgConf,
      averageWaterCoverage: avgCover,
      storageUsedBytes: usage.usedBytes,
      storageRemainingSoftBytes:
          (usage.softLimitBytes - usage.usedBytes).clamp(0, 1 << 62),
      datasetGrowth: _growth(sessions),
    );
  }

  List<AnalyticsChartPoint> _growth(List<DatasetSession> sessions) {
    final sorted = List<DatasetSession>.from(sessions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final byDay = <String, int>{};
    for (final s in sorted) {
      final key = _dayKey(s.createdAt);
      byDay[key] = (byDay[key] ?? 0) + s.frameCount;
    }
    var cumulative = 0;
    return [
      for (final e in byDay.entries)
        AnalyticsChartPoint(
          label: e.key.substring(5), // MM-DD
          value: (cumulative += e.value).toDouble(),
        ),
    ];
  }

  DatasetQualityMetrics _quality(
    List<DatasetSession> sessions,
    Map<String, AnalyticsRecoverySnapshot> recovery,
  ) {
    if (sessions.isEmpty) return const DatasetQualityMetrics.empty();

    final n = sessions.length;
    final totalFrames =
        sessions.fold<int>(0, (a, s) => a + s.frameCount);
    final totalSeconds = sessions.fold<int>(
      0,
      (a, s) => a + s.duration.inSeconds,
    );
    final emptySessions = sessions.where((s) => s.frameCount == 0).length;
    final framesPerSession = totalFrames / n;
    final minutes = totalSeconds / 60.0;
    final fpm = minutes <= 0 ? 0.0 : totalFrames / minutes;
    final hz = totalSeconds <= 0 ? 0.0 : totalFrames / totalSeconds;
    final interval = totalFrames <= 1 || totalSeconds <= 0
        ? 0.0
        : totalSeconds / totalFrames;

    var missingMeta = 0;
    var corrupted = 0;
    var sessionsWithDisk = 0;
    var completeSessions = 0;
    for (final s in sessions) {
      final r = recovery[s.id];
      if (r == null) continue;
      sessionsWithDisk++;
      final gap = (r.imageCount - r.metadataCount).abs();
      missingMeta += gap;
      if (r.isIncomplete) corrupted += gap == 0 ? 1 : gap;
      if (!r.isIncomplete &&
          r.imageCount > 0 &&
          r.imageCount == r.metadataCount) {
        completeSessions++;
      }
    }

    // Capture success: frames attributed vs empty, blended with disk completeness.
    final nonEmpty = n - emptySessions;
    final sessionSuccess = n == 0 ? 0.0 : nonEmpty / n;
    final diskSuccess = sessionsWithDisk == 0
        ? sessionSuccess
        : completeSessions / sessionsWithDisk;
    final captureSuccess = ((sessionSuccess + diskSuccess) / 2).clamp(0.0, 1.0);

    // Completeness score 0–100.
    final hasFramesScore = (totalFrames > 0 ? 40.0 : 0.0);
    final gpsProxyScore = sessions.where((s) => s.averageSpeed > 0).length /
        n *
        20.0;
    final confScore = sessions
            .fold<double>(0, (a, s) => a + s.averageConfidence) /
        n *
        20.0;
    final diskScore = sessionsWithDisk == 0
        ? 10.0
        : (completeSessions / sessionsWithDisk) * 20.0;
    final completeness =
        (hasFramesScore + gpsProxyScore + confScore + diskScore)
            .clamp(0.0, 100.0);

    return DatasetQualityMetrics(
      framesPerSession: framesPerSession,
      framesPerMinute: fpm,
      captureFrequencyHz: hz,
      captureSuccessRate: captureSuccess,
      averageCaptureIntervalSeconds: interval,
      completenessScore: completeness,
      missingMetadataCount: missingMeta,
      corruptedFrameCount: corrupted,
      emptySessionCount: emptySessions,
    );
  }

  ResearchInsights _insights(List<DatasetSession> sessions) {
    if (sessions.isEmpty) return const ResearchInsights.empty();

    DatasetSession? longest;
    DatasetSession? largest;
    DatasetSession? mostFlood;
    DatasetSession? highestConf;
    for (final s in sessions) {
      if (longest == null || s.duration > longest.duration) longest = s;
      if (largest == null || s.totalStorage > largest.totalStorage) {
        largest = s;
      }
      if (mostFlood == null || s.floodEventCount > mostFlood.floodEventCount) {
        mostFlood = s;
      }
      if (highestConf == null ||
          s.averageConfidence > highestConf.averageConfidence) {
        highestConf = s;
      }
    }

    final byHour = <int, int>{};
    final byDay = <String, int>{};
    for (final s in sessions) {
      final local = (s.startedAt ?? s.createdAt).toLocal();
      byHour[local.hour] = (byHour[local.hour] ?? 0) + 1;
      final key = _dayKey(local);
      byDay[key] = (byDay[key] ?? 0) + 1;
    }
    var bestHour = 0;
    var bestHourCount = 0;
    byHour.forEach((h, c) {
      if (c > bestHourCount) {
        bestHour = h;
        bestHourCount = c;
      }
    });
    var mostActiveDay = '—';
    var mostActiveCount = 0;
    byDay.forEach((d, c) {
      if (c > mostActiveCount) {
        mostActiveDay = d;
        mostActiveCount = c;
      }
    });

    final daySpan = byDay.length.clamp(1, 1 << 20);
    final avgDaily = sessions.length / daySpan;

    return ResearchInsights(
      insights: [
        ResearchInsight(
          title: 'Best recording time',
          value: '${bestHour.toString().padLeft(2, '0')}:00',
          subtitle: '$bestHourCount session(s) started in this hour',
        ),
        ResearchInsight(
          title: 'Longest recording',
          value: _fmtDuration(longest!.duration),
          subtitle: longest.sessionName,
          sessionId: longest.id,
        ),
        ResearchInsight(
          title: 'Largest dataset',
          value: _fmtBytes(largest!.totalStorage),
          subtitle: largest.sessionName,
          sessionId: largest.id,
        ),
        ResearchInsight(
          title: 'Most flood events',
          value: '${mostFlood!.floodEventCount}',
          subtitle: mostFlood.sessionName,
          sessionId: mostFlood.id,
        ),
        ResearchInsight(
          title: 'Highest confidence',
          value: highestConf!.averageConfidence.toStringAsFixed(2),
          subtitle: highestConf.sessionName,
          sessionId: highestConf.id,
        ),
        ResearchInsight(
          title: 'Most active day',
          value: mostActiveDay,
          subtitle: '$mostActiveCount session(s)',
        ),
        ResearchInsight(
          title: 'Average daily recording',
          value: avgDaily.toStringAsFixed(1),
          subtitle: 'Sessions per active day',
        ),
      ],
    );
  }

  LocationAnalytics _location(
    List<DatasetSession> sessions,
    List<AnalyticsFrameSample> samples,
  ) {
    if (sessions.isEmpty) return const LocationAnalytics.empty();

    final sampleGps = samples.where((s) => s.hasGps).toList();
    final sessionsWithSampleGps = {
      for (final s in sampleGps) s.sessionId,
    };
    // Proxy: speed reported on session OR GPS sample present.
    final withGps = sessions
        .where(
          (s) => s.averageSpeed > 0 || sessionsWithSampleGps.contains(s.id),
        )
        .length;
    final withoutGps = sessions.length - withGps;

    final avgSpeed =
        sessions.fold<double>(0, (a, s) => a + s.averageSpeed) /
            sessions.length;
    // Distance ≈ mean km/h * hours.
    var distance = 0.0;
    for (final s in sessions) {
      if (s.averageSpeed <= 0) continue;
      distance += s.averageSpeed * (s.duration.inSeconds / 3600.0);
    }

    final gpsPoints = sampleGps.isNotEmpty
        ? sampleGps.length
        : sessions.fold<int>(0, (a, s) => a + (s.averageSpeed > 0 ? s.frameCount : 0));

    final accuracyBuckets = <String, int>{
      '<5m': 0,
      '5–15m': 0,
      '15–50m': 0,
      '>50m': 0,
      'unknown': 0,
    };
    if (sampleGps.isEmpty) {
      accuracyBuckets['unknown'] = withGps;
    } else {
      for (final s in sampleGps) {
        final a = s.accuracyMeters;
        if (a < 5) {
          accuracyBuckets['<5m'] = accuracyBuckets['<5m']! + 1;
        } else if (a < 15) {
          accuracyBuckets['5–15m'] = accuracyBuckets['5–15m']! + 1;
        } else if (a < 50) {
          accuracyBuckets['15–50m'] = accuracyBuckets['15–50m']! + 1;
        } else {
          accuracyBuckets['>50m'] = accuracyBuckets['>50m']! + 1;
        }
      }
    }

    return LocationAnalytics(
      totalGpsPoints: gpsPoints,
      averageSpeed: avgSpeed,
      distanceCoveredKm: distance,
      sessionsWithGps: withGps,
      sessionsWithoutGps: withoutGps,
      accuracyDistribution: [
        for (final e in accuracyBuckets.entries)
          if (e.value > 0)
            AnalyticsChartPoint(label: e.key, value: e.value.toDouble()),
      ],
    );
  }

  InferenceAnalytics _inference(
    List<DatasetSession> sessions,
    List<AnalyticsFrameSample> samples,
  ) {
    if (sessions.isEmpty) return const InferenceAnalytics.empty();

    final available = samples.where((s) => s.inferenceAvailable).toList();
    final avgInf = available.isEmpty
        ? 0.0
        : available.fold<double>(0, (a, s) => a + s.inferenceTimeMs) /
            available.length;
    final avgConf = available.isEmpty
        ? sessions.fold<double>(0, (a, s) => a + s.averageConfidence) /
            sessions.length
        : available.fold<double>(0, (a, s) => a + s.confidence) /
            available.length;
    final floodCount = available.isEmpty
        ? sessions.fold<int>(0, (a, s) => a + s.floodEventCount)
        : available.where((s) => s.waterCoverage > 5 || s.confidence > 0.5).length;

    final riskBuckets = <String, int>{};
    if (available.isEmpty) {
      for (final s in sessions) {
        final key = s.averageFloodCoverage >= 40
            ? 'high'
            : s.averageFloodCoverage >= 15
                ? 'medium'
                : s.averageFloodCoverage > 0
                    ? 'low'
                    : 'none';
        riskBuckets[key] = (riskBuckets[key] ?? 0) + 1;
      }
    } else {
      for (final s in available) {
        final key = s.riskLevel.isEmpty ? 'unknown' : s.riskLevel.toLowerCase();
        riskBuckets[key] = (riskBuckets[key] ?? 0) + 1;
      }
    }

    final coverBuckets = <String, int>{
      '0%': 0,
      '1–10%': 0,
      '11–40%': 0,
      '41–100%': 0,
    };
    final covers = available.isEmpty
        ? sessions.map((s) => s.averageFloodCoverage)
        : available.map((s) => s.waterCoverage);
    for (final c in covers) {
      if (c <= 0) {
        coverBuckets['0%'] = coverBuckets['0%']! + 1;
      } else if (c <= 10) {
        coverBuckets['1–10%'] = coverBuckets['1–10%']! + 1;
      } else if (c <= 40) {
        coverBuckets['11–40%'] = coverBuckets['11–40%']! + 1;
      } else {
        coverBuckets['41–100%'] = coverBuckets['41–100%']! + 1;
      }
    }

    return InferenceAnalytics(
      averageInferenceTimeMs: avgInf,
      averageFloodConfidence: avgConf,
      floodDetectionCount: floodCount,
      riskLevelDistribution: [
        for (final e in riskBuckets.entries)
          AnalyticsChartPoint(label: e.key, value: e.value.toDouble()),
      ],
      waterCoverageDistribution: [
        for (final e in coverBuckets.entries)
          if (e.value > 0)
            AnalyticsChartPoint(label: e.key, value: e.value.toDouble()),
      ],
    );
  }

  SessionAnalytics _sessions(List<DatasetSession> sessions) {
    if (sessions.isEmpty) return const SessionAnalytics.empty();

    final durationBuckets = <String, int>{
      '<1m': 0,
      '1–5m': 0,
      '5–15m': 0,
      '15–60m': 0,
      '>60m': 0,
    };
    final frameBuckets = <String, int>{
      '0': 0,
      '1–50': 0,
      '51–200': 0,
      '201–1000': 0,
      '>1000': 0,
    };
    final storageBuckets = <String, int>{
      '<1MB': 0,
      '1–10MB': 0,
      '10–100MB': 0,
      '>100MB': 0,
    };
    final statusBuckets = <String, int>{};
    final byDay = <String, int>{};

    for (final s in sessions) {
      final mins = s.duration.inSeconds / 60.0;
      if (mins < 1) {
        durationBuckets['<1m'] = durationBuckets['<1m']! + 1;
      } else if (mins < 5) {
        durationBuckets['1–5m'] = durationBuckets['1–5m']! + 1;
      } else if (mins < 15) {
        durationBuckets['5–15m'] = durationBuckets['5–15m']! + 1;
      } else if (mins < 60) {
        durationBuckets['15–60m'] = durationBuckets['15–60m']! + 1;
      } else {
        durationBuckets['>60m'] = durationBuckets['>60m']! + 1;
      }

      final f = s.frameCount;
      if (f == 0) {
        frameBuckets['0'] = frameBuckets['0']! + 1;
      } else if (f <= 50) {
        frameBuckets['1–50'] = frameBuckets['1–50']! + 1;
      } else if (f <= 200) {
        frameBuckets['51–200'] = frameBuckets['51–200']! + 1;
      } else if (f <= 1000) {
        frameBuckets['201–1000'] = frameBuckets['201–1000']! + 1;
      } else {
        frameBuckets['>1000'] = frameBuckets['>1000']! + 1;
      }

      final mb = s.totalStorage / (1024 * 1024);
      if (mb < 1) {
        storageBuckets['<1MB'] = storageBuckets['<1MB']! + 1;
      } else if (mb < 10) {
        storageBuckets['1–10MB'] = storageBuckets['1–10MB']! + 1;
      } else if (mb < 100) {
        storageBuckets['10–100MB'] = storageBuckets['10–100MB']! + 1;
      } else {
        storageBuckets['>100MB'] = storageBuckets['>100MB']! + 1;
      }

      statusBuckets[s.status.label] =
          (statusBuckets[s.status.label] ?? 0) + 1;
      final key = _dayKey(s.createdAt);
      byDay[key] = (byDay[key] ?? 0) + 1;
    }

    final sortedDays = byDay.keys.toList()..sort();
    return SessionAnalytics(
      durationDistribution: _mapPoints(durationBuckets),
      frameCountDistribution: _mapPoints(frameBuckets),
      storageDistribution: _mapPoints(storageBuckets),
      recordingFrequency: [
        for (final d in sortedDays)
          AnalyticsChartPoint(
            label: d.substring(5),
            value: byDay[d]!.toDouble(),
          ),
      ],
      sessionTimeline: [
        for (final d in sortedDays)
          AnalyticsChartPoint(
            label: d.substring(5),
            value: byDay[d]!.toDouble(),
            category: 'sessions',
          ),
      ],
      statusDistribution: [
        for (final e in statusBuckets.entries)
          AnalyticsChartPoint(label: e.key, value: e.value.toDouble()),
      ],
    );
  }

  StorageAnalytics _storage(
    List<DatasetSession> sessions,
    StorageUsage usage,
    List<FolderInfo> folders,
  ) {
    int findFolder(String needle) {
      for (final f in folders) {
        final label = f.label.toLowerCase();
        final path = f.path.toLowerCase();
        if (label.contains(needle) || path.contains(needle)) {
          return f.sizeBytes;
        }
      }
      return 0;
    }

    final images = findFolder('image') +
        findFolder('original') +
        findFolder('thumb') +
        findFolder('compress');
    final meta = findFolder('meta');
    final cache = findFolder('cache');
    final temp = findFolder('temp');
    // Prefer folder sums when present; else attribute session storage.
    final imagesBytes = images > 0
        ? images
        : sessions.fold<int>(0, (a, s) => a + s.totalStorage);
    final metaBytes = meta;
    final avgSession = sessions.isEmpty
        ? 0.0
        : sessions.fold<int>(0, (a, s) => a + s.totalStorage) /
            sessions.length;

    final breakdown = <AnalyticsChartPoint>[
      if (imagesBytes > 0)
        AnalyticsChartPoint(
          label: 'Images',
          value: imagesBytes.toDouble(),
        ),
      if (metaBytes > 0)
        AnalyticsChartPoint(
          label: 'Metadata',
          value: metaBytes.toDouble(),
        ),
      if (cache > 0)
        AnalyticsChartPoint(label: 'Cache', value: cache.toDouble()),
      if (temp > 0)
        AnalyticsChartPoint(label: 'Temp', value: temp.toDouble()),
    ];
    if (breakdown.isEmpty && usage.usedBytes > 0) {
      breakdown.add(
        AnalyticsChartPoint(
          label: 'Dataset',
          value: usage.usedBytes.toDouble(),
        ),
      );
    }

    return StorageAnalytics(
      totalStorageBytes: usage.usedBytes,
      imagesStorageBytes: imagesBytes,
      metadataStorageBytes: metaBytes,
      cacheSizeBytes: cache,
      temporaryFilesBytes: temp,
      averageSessionSizeBytes: avgSession,
      remainingSoftBudgetBytes:
          (usage.softLimitBytes - usage.usedBytes).clamp(0, 1 << 62),
      breakdown: breakdown,
    );
  }

  List<AnalyticsChartPoint> _mapPoints(Map<String, int> buckets) => [
        for (final e in buckets.entries)
          AnalyticsChartPoint(label: e.key, value: e.value.toDouble()),
      ];

  String _dayKey(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
