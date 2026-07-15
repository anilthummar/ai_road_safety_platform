import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/services/analytics_aggregator.dart';
import 'package:ai_road_safety_platform/features/history/domain/repositories/history_repository.dart';

/// Aggregates [HistoryRepository] streams into analytics reports.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final HistoryRepository _history;
  final AnalyticsAggregator _aggregator;

  /// Creates [AnalyticsRepositoryImpl].
  AnalyticsRepositoryImpl({
    required HistoryRepository historyRepository,
    AnalyticsAggregator aggregator = const AnalyticsAggregator(),
  })  : _history = historyRepository,
        _aggregator = aggregator;

  @override
  Future<Result<AnalyticsReport>> getReport(AnalyticsPeriod period) async {
    final result = await _history.getRecords();
    return result.map(
      (records) => _aggregator.build(records: records, period: period),
    );
  }

  @override
  Stream<AnalyticsReport> watchReport(AnalyticsPeriod period) {
    return _history.watchRecords().map(
          (records) => _aggregator.build(records: records, period: period),
        );
  }
}
