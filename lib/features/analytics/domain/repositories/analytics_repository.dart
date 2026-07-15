import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';

/// Domain contract for analytics reports derived from history.
abstract class AnalyticsRepository {
  /// Builds a report for [period] from persisted history.
  Future<Result<AnalyticsReport>> getReport(AnalyticsPeriod period);

  /// Emits a fresh report when history changes.
  Stream<AnalyticsReport> watchReport(AnalyticsPeriod period);
}
