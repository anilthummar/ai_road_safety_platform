import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';

/// Domain contract for fused risk evaluation.
abstract class RiskAnalysisRepository {
  /// Session stream (monitoring flag + latest assessment).
  Stream<RiskSession> watchSession();

  /// Live assessments while monitoring.
  Stream<RiskAssessment> watchAssessments();

  /// Pure one-shot evaluation of [snapshot] via the rule engine.
  Future<Result<RiskAssessment>> evaluate(RiskInputSnapshot snapshot);

  /// Starts fusing flood / GPS / IMU streams into continuous assessments.
  Future<Result<RiskSession>> startMonitoring();

  /// Stops continuous fusion (keeps last assessment).
  Future<Result<RiskSession>> stopMonitoring();

  /// Releases subscriptions.
  Future<Result<void>> dispose();
}
