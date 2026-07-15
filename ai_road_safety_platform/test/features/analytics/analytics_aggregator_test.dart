import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/services/analytics_aggregator.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const aggregator = AnalyticsAggregator();
  final now = DateTime(2026, 7, 14, 15);

  HistoryRecord rec({
    required DateTime at,
    double flood = 0,
    RiskLevel risk = RiskLevel.low,
    double speed = 0,
    double? lat = 25.2,
    double? lng = 55.2,
  }) {
    return HistoryRecord(
      id: at.toIso8601String(),
      timestamp: at,
      floodPercent: flood,
      riskLevel: risk,
      riskScore: risk.index * 25,
      speedKmh: speed,
      latitude: lat,
      longitude: lng,
    );
  }

  test('weekly report counts flood, risk, trips, avg speed', () {
    final records = [
      rec(
        at: DateTime(2026, 7, 13, 10),
        flood: 12,
        risk: RiskLevel.high,
        speed: 40,
      ),
      rec(
        at: DateTime(2026, 7, 13, 18),
        flood: 2,
        risk: RiskLevel.medium,
        speed: 50,
      ),
      rec(
        at: DateTime(2026, 7, 12, 9),
        flood: 25,
        risk: RiskLevel.extreme,
        speed: 30,
      ),
      rec(
        at: DateTime(2026, 7, 1, 9),
        flood: 40,
        risk: RiskLevel.extreme,
        speed: 99,
      ), // outside weekly
    ];

    final report = aggregator.build(
      records: records,
      period: AnalyticsPeriod.weekly,
      now: now,
    );

    expect(report.summary.totalRecords, 3);
    expect(report.summary.floodEvents, 2); // 12 and 25
    expect(report.summary.riskEvents, 3);
    expect(report.summary.extremeRiskEvents, 1);
    expect(report.summary.trips, 2); // Jul 12 and 13
    expect(report.summary.averageSpeedKmh, closeTo(40, 0.01));
    expect(report.buckets.length, 7);
  });

  test('empty history yields empty summary', () {
    final report = aggregator.build(
      records: const [],
      period: AnalyticsPeriod.monthly,
      now: now,
    );
    expect(report.summary, const AnalyticsSummary.empty());
    expect(report.buckets, isNotEmpty);
  });

  test('yearly buckets span months', () {
    final report = aggregator.build(
      records: [
        rec(at: DateTime(2026, 1, 5), flood: 10, risk: RiskLevel.medium),
      ],
      period: AnalyticsPeriod.yearly,
      now: now,
    );
    expect(report.buckets.length, greaterThanOrEqualTo(12));
    expect(report.summary.floodEvents, 1);
  });
}
