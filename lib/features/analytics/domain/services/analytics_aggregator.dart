import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';

/// Pure aggregation of [HistoryRecord]s into [AnalyticsReport]s.
class AnalyticsAggregator {
  /// Creates [AnalyticsAggregator].
  const AnalyticsAggregator();

  /// Builds a report for [period] ending at [now] (local time).
  AnalyticsReport build({
    required List<HistoryRecord> records,
    required AnalyticsPeriod period,
    DateTime? now,
  }) {
    final end = now ?? DateTime.now();
    final localEnd = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1));
    final rangeStart = _rangeStart(period, localEnd);
    final inRange = records
        .where(
          (r) =>
              !r.timestamp.isBefore(rangeStart) &&
              r.timestamp.isBefore(localEnd),
        )
        .toList();

    final buckets = _buckets(period, rangeStart, localEnd, inRange);
    final summary = _summary(inRange);

    return AnalyticsReport(
      period: period,
      rangeStart: rangeStart,
      rangeEnd: localEnd,
      summary: summary,
      buckets: buckets,
      generatedAt: end,
    );
  }

  DateTime _rangeStart(AnalyticsPeriod period, DateTime localEndExclusive) {
    return switch (period) {
      AnalyticsPeriod.weekly =>
        localEndExclusive.subtract(const Duration(days: 7)),
      AnalyticsPeriod.monthly =>
        localEndExclusive.subtract(const Duration(days: 28)),
      AnalyticsPeriod.yearly => DateTime(
          localEndExclusive.year - 1,
          localEndExclusive.month,
          localEndExclusive.day,
        ),
    };
  }

  AnalyticsSummary _summary(List<HistoryRecord> records) {
    if (records.isEmpty) return const AnalyticsSummary.empty();

    var flood = 0;
    var risk = 0;
    var high = 0;
    var extreme = 0;
    var speedSum = 0.0;
    var speedN = 0;
    var maxFlood = 0.0;
    var riskScoreSum = 0.0;
    final tripDays = <String>{};

    for (final r in records) {
      if (r.floodPercent >= AnalyticsConfig.floodEventThresholdPercent) {
        flood++;
      }
      if (r.riskLevel.rank >= AnalyticsConfig.riskEventMinRank) {
        risk++;
      }
      if (r.riskLevel == RiskLevel.high || r.riskLevel == RiskLevel.extreme) {
        high++;
      }
      if (r.riskLevel == RiskLevel.extreme) {
        extreme++;
      }
      if (r.speedKmh > 0) {
        speedSum += r.speedKmh;
        speedN++;
      }
      if (r.floodPercent > maxFlood) {
        maxFlood = r.floodPercent;
      }
      riskScoreSum += r.riskScore;
      if (r.hasGps) {
        tripDays.add(_dayKey(r.timestamp.toLocal()));
      }
    }

    return AnalyticsSummary(
      trips: tripDays.length,
      floodEvents: flood,
      riskEvents: risk,
      highRiskEvents: high,
      extremeRiskEvents: extreme,
      averageSpeedKmh: speedN == 0 ? 0 : speedSum / speedN,
      maxFloodPercent: maxFlood,
      averageRiskScore: riskScoreSum / records.length,
      totalRecords: records.length,
    );
  }

  List<AnalyticsBucket> _buckets(
    AnalyticsPeriod period,
    DateTime rangeStart,
    DateTime rangeEnd,
    List<HistoryRecord> records,
  ) {
    return switch (period) {
      AnalyticsPeriod.weekly => _dailyBuckets(rangeStart, rangeEnd, records),
      AnalyticsPeriod.monthly => _weeklyBuckets(rangeStart, rangeEnd, records),
      AnalyticsPeriod.yearly => _monthlyBuckets(rangeStart, rangeEnd, records),
    };
  }

  List<AnalyticsBucket> _dailyBuckets(
    DateTime rangeStart,
    DateTime rangeEnd,
    List<HistoryRecord> records,
  ) {
    final buckets = <AnalyticsBucket>[];
    var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    while (cursor.isBefore(rangeEnd)) {
      final next = cursor.add(const Duration(days: 1));
      final slice = _slice(records, cursor, next);
      buckets.add(
        _bucketFrom(
          start: cursor,
          end: next,
          label: labels[cursor.weekday - 1],
          records: slice,
        ),
      );
      cursor = next;
    }
    return buckets;
  }

  List<AnalyticsBucket> _weeklyBuckets(
    DateTime rangeStart,
    DateTime rangeEnd,
    List<HistoryRecord> records,
  ) {
    final buckets = <AnalyticsBucket>[];
    var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    var week = 1;
    while (cursor.isBefore(rangeEnd)) {
      final next = cursor.add(const Duration(days: 7));
      final end = next.isAfter(rangeEnd) ? rangeEnd : next;
      final slice = _slice(records, cursor, end);
      buckets.add(
        _bucketFrom(
          start: cursor,
          end: end,
          label: 'W$week',
          records: slice,
        ),
      );
      week++;
      cursor = next;
    }
    return buckets;
  }

  List<AnalyticsBucket> _monthlyBuckets(
    DateTime rangeStart,
    DateTime rangeEnd,
    List<HistoryRecord> records,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final buckets = <AnalyticsBucket>[];
    var cursor = DateTime(rangeStart.year, rangeStart.month);
    while (cursor.isBefore(rangeEnd)) {
      final next = DateTime(cursor.year, cursor.month + 1);
      final end = next.isAfter(rangeEnd) ? rangeEnd : next;
      final slice = _slice(records, cursor, end);
      buckets.add(
        _bucketFrom(
          start: cursor,
          end: end,
          label: months[cursor.month - 1],
          records: slice,
        ),
      );
      cursor = next;
    }
    return buckets;
  }

  List<HistoryRecord> _slice(
    List<HistoryRecord> records,
    DateTime start,
    DateTime end,
  ) {
    return records
        .where(
          (r) =>
              !r.timestamp.toLocal().isBefore(start) &&
              r.timestamp.toLocal().isBefore(end),
        )
        .toList();
  }

  AnalyticsBucket _bucketFrom({
    required DateTime start,
    required DateTime end,
    required String label,
    required List<HistoryRecord> records,
  }) {
    var flood = 0;
    var risk = 0;
    var speedSum = 0.0;
    var speedN = 0;
    final tripDays = <String>{};

    for (final r in records) {
      if (r.floodPercent >= AnalyticsConfig.floodEventThresholdPercent) {
        flood++;
      }
      if (r.riskLevel.rank >= AnalyticsConfig.riskEventMinRank) {
        risk++;
      }
      if (r.speedKmh > 0) {
        speedSum += r.speedKmh;
        speedN++;
      }
      if (r.hasGps) {
        tripDays.add(_dayKey(r.timestamp.toLocal()));
      }
    }

    return AnalyticsBucket(
      start: start,
      end: end,
      label: label,
      floodEvents: flood,
      riskEvents: risk,
      trips: tripDays.length,
      averageSpeedKmh: speedN == 0 ? 0 : speedSum / speedN,
      recordCount: records.length,
    );
  }

  String _dayKey(DateTime local) =>
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
