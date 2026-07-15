import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/repositories/analytics_repository.dart';

/// Loads an analytics report for a period.
class GetAnalyticsReportUseCase
    extends UseCase<Result<AnalyticsReport>, AnalyticsPeriod> {
  final AnalyticsRepository _repository;

  /// Creates [GetAnalyticsReportUseCase].
  GetAnalyticsReportUseCase(this._repository);

  @override
  Future<Result<AnalyticsReport>> call(AnalyticsPeriod params) {
    return _repository.getReport(params);
  }
}
