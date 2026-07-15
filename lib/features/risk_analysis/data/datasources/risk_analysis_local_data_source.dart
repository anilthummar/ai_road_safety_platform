import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';

/// Local risk engine + sensor fusion contract.
abstract class RiskAnalysisLocalDataSource {
  /// Session stream.
  Stream<RiskSession> get sessionStream;

  /// Assessment stream.
  Stream<RiskAssessment> get assessmentStream;

  /// Whether continuous monitoring is active.
  bool get isMonitoring;

  /// Runs the rule engine once on [snapshot].
  RiskAssessment evaluate(RiskInputSnapshot snapshot);

  /// Subscribes to flood / GPS / IMU and emits throttled assessments.
  Future<void> startMonitoring();

  /// Cancels fusion subscriptions.
  Future<void> stopMonitoring();

  /// Stops monitoring (singleton-safe).
  Future<void> dispose();
}
