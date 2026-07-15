import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Scores vehicle speed relative to wet/unverified road contexts.
class VehicleSpeedRule implements RiskRule {
  const VehicleSpeedRule();
  @override
  String get id => 'vehicle_speed';

  @override
  String get name => 'Vehicle speed';

  @override
  RiskRuleHit? evaluate(RiskInputSnapshot input) {
    final speed = input.speedKmh;
    if (speed <= 0 && !input.hasGpsFix) {
      return null;
    }
    final (score, level, tip) = switch (speed) {
      >= 90 => (
          70.0,
          RiskLevel.high,
          'High speed — reduce speed in flooding / low-visibility conditions.',
        ),
      >= 60 => (
          42.0,
          RiskLevel.medium,
          'Elevated speed — be ready to brake earlier for hazards.',
        ),
      >= 40 => (
          20.0,
          RiskLevel.low,
          'Moderate speed — maintain increased following distance.',
        ),
      _ => (0.0, RiskLevel.low, null),
    };
    if (score <= 0) return null;
    return RiskRuleHit(
      ruleId: id,
      ruleName: name,
      score: score,
      level: level,
      reason: 'Speed ${speed.toStringAsFixed(0)} km/h',
      recommendation: tip,
    );
  }
}
