import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';

/// Single pluggable business rule for the risk engine.
///
/// Implementations live under `data/rules/` so domain stays free of thresholds.
abstract class RiskRule {
  /// Stable identifier used in telemetry and recommendation dedupe.
  String get id;

  /// Display name.
  String get name;

  /// Evaluates [input]. Return `null` when the rule does not apply / contribute.
  RiskRuleHit? evaluate(RiskInputSnapshot input);
}

/// Aggregates [RiskRule] hits into a [RiskAssessment].
abstract class RiskRuleEngine {
  /// Registered rules (order does not affect score; max aggregation is used).
  List<RiskRule> get rules;

  /// Runs every rule and builds a fused assessment.
  RiskAssessment evaluate(RiskInputSnapshot input);
}
