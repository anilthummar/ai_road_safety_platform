import 'package:equatable/equatable.dart';

/// Time window for analytics charts.
enum AnalyticsPeriod {
  /// Last 7 days (daily buckets).
  weekly,

  /// Last ~30 days (weekly buckets).
  monthly,

  /// Last 12 months (monthly buckets).
  yearly,
}

/// Extension helpers for [AnalyticsPeriod].
extension AnalyticsPeriodX on AnalyticsPeriod {
  /// Short UI label.
  String get label => switch (this) {
        AnalyticsPeriod.weekly => 'Weekly',
        AnalyticsPeriod.monthly => 'Monthly',
        AnalyticsPeriod.yearly => 'Yearly',
      };

  /// Inclusive lookback length used for range clipping.
  Duration get lookback => switch (this) {
        AnalyticsPeriod.weekly => const Duration(days: 7),
        AnalyticsPeriod.monthly => const Duration(days: 30),
        AnalyticsPeriod.yearly => const Duration(days: 365),
      };
}

/// Aggregated KPI totals for a period.
class AnalyticsSummary extends Equatable {
  /// Distinct trip-days (calendar days with GPS activity).
  final int trips;

  /// Snapshots with flood coverage ≥ threshold.
  final int floodEvents;

  /// Snapshots with elevated risk (medium+).
  final int riskEvents;

  /// High + extreme risk snapshots.
  final int highRiskEvents;

  /// Extreme risk snapshots.
  final int extremeRiskEvents;

  /// Mean vehicle speed (km/h) over samples with speed &gt; 0.
  final double averageSpeedKmh;

  /// Max flood % observed in range.
  final double maxFloodPercent;

  /// Mean risk score in range.
  final double averageRiskScore;

  /// Total history records considered.
  final int totalRecords;

  /// Creates [AnalyticsSummary].
  const AnalyticsSummary({
    required this.trips,
    required this.floodEvents,
    required this.riskEvents,
    required this.highRiskEvents,
    required this.extremeRiskEvents,
    required this.averageSpeedKmh,
    required this.maxFloodPercent,
    required this.averageRiskScore,
    required this.totalRecords,
  });

  /// Empty totals.
  const AnalyticsSummary.empty()
      : trips = 0,
        floodEvents = 0,
        riskEvents = 0,
        highRiskEvents = 0,
        extremeRiskEvents = 0,
        averageSpeedKmh = 0,
        maxFloodPercent = 0,
        averageRiskScore = 0,
        totalRecords = 0;

  @override
  List<Object?> get props => [
        trips,
        floodEvents,
        riskEvents,
        highRiskEvents,
        extremeRiskEvents,
        averageSpeedKmh,
        maxFloodPercent,
        averageRiskScore,
        totalRecords,
      ];
}

/// One chart bucket (day / week / month).
class AnalyticsBucket extends Equatable {
  /// Bucket start (inclusive, local day-aligned).
  final DateTime start;

  /// Bucket end (exclusive).
  final DateTime end;

  /// Axis label (e.g. Mon, W1, Jan).
  final String label;

  /// Flood events in bucket.
  final int floodEvents;

  /// Risk events in bucket.
  final int riskEvents;

  /// Trip days in bucket.
  final int trips;

  /// Average speed in bucket.
  final double averageSpeedKmh;

  /// Snapshot count.
  final int recordCount;

  /// Creates [AnalyticsBucket].
  const AnalyticsBucket({
    required this.start,
    required this.end,
    required this.label,
    required this.floodEvents,
    required this.riskEvents,
    required this.trips,
    required this.averageSpeedKmh,
    required this.recordCount,
  });

  @override
  List<Object?> get props => [
        start,
        end,
        label,
        floodEvents,
        riskEvents,
        trips,
        averageSpeedKmh,
        recordCount,
      ];
}

/// Full analytics report for a selected period.
class AnalyticsReport extends Equatable {
  /// Selected period.
  final AnalyticsPeriod period;

  /// Range start (inclusive).
  final DateTime rangeStart;

  /// Range end (exclusive / now).
  final DateTime rangeEnd;

  /// KPI summary.
  final AnalyticsSummary summary;

  /// Time-series buckets for charts.
  final List<AnalyticsBucket> buckets;

  /// When the report was computed.
  final DateTime generatedAt;

  /// Creates [AnalyticsReport].
  const AnalyticsReport({
    required this.period,
    required this.rangeStart,
    required this.rangeEnd,
    required this.summary,
    required this.buckets,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        period,
        rangeStart,
        rangeEnd,
        summary,
        buckets,
        generatedAt,
      ];
}

/// Thresholds used by the analytics aggregator.
class AnalyticsConfig {
  AnalyticsConfig._();

  /// Flood event when coverage at or above this percent.
  static const double floodEventThresholdPercent = 8;

  /// Medium+ counts as a risk event (see RiskLevel.rank).
  static const int riskEventMinRank = 1; // medium
}
