import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/repositories/risk_analysis_repository.dart';

/// One-shot rule-engine evaluation.
class EvaluateRiskUseCase
    extends UseCase<Result<RiskAssessment>, RiskInputSnapshot> {
  final RiskAnalysisRepository _repository;

  /// Creates [EvaluateRiskUseCase].
  EvaluateRiskUseCase(this._repository);

  @override
  Future<Result<RiskAssessment>> call(RiskInputSnapshot params) {
    return _repository.evaluate(params);
  }
}

/// Starts continuous flood / GPS / IMU fusion.
class StartRiskMonitoringUseCase
    extends UseCase<Result<RiskSession>, NoParams> {
  final RiskAnalysisRepository _repository;

  /// Creates [StartRiskMonitoringUseCase].
  StartRiskMonitoringUseCase(this._repository);

  @override
  Future<Result<RiskSession>> call(NoParams params) {
    return _repository.startMonitoring();
  }
}

/// Stops continuous fusion.
class StopRiskMonitoringUseCase
    extends UseCase<Result<RiskSession>, NoParams> {
  final RiskAnalysisRepository _repository;

  /// Creates [StopRiskMonitoringUseCase].
  StopRiskMonitoringUseCase(this._repository);

  @override
  Future<Result<RiskSession>> call(NoParams params) {
    return _repository.stopMonitoring();
  }
}

/// Releases risk monitoring resources.
class DisposeRiskAnalysisUseCase extends UseCase<Result<void>, NoParams> {
  final RiskAnalysisRepository _repository;

  /// Creates [DisposeRiskAnalysisUseCase].
  DisposeRiskAnalysisUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.dispose();
  }
}
