import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Compound rule: flood water + vehicle speed → elevated / extreme risk.
class FloodSpeedCompoundRule implements RiskRule {
  const FloodSpeedCompoundRule();
  @override
  String get id => 'flood_speed_compound';

  @override
  String get name => 'Flood × speed';

  @override
  RiskRuleHit? evaluate(RiskInputSnapshot input) {
    final flood = input.floodCoveragePercent;
    final speed = input.speedKmh;
    if (flood < 5 || speed < 15) return null;

    if (flood >= 15 && speed >= 40) {
      return RiskRuleHit(
        ruleId: id,
        ruleName: name,
        score: 98,
        level: RiskLevel.extreme,
        reason:
            'Flood ${flood.toStringAsFixed(0)}% at ${speed.toStringAsFixed(0)} km/h',
        recommendation:
            'Extreme risk: flooded roadway at speed — brake gently, stop, and turn around.',
      );
    }
    if (flood >= 8 && speed >= 25) {
      return RiskRuleHit(
        ruleId: id,
        ruleName: name,
        score: 82,
        level: RiskLevel.extreme,
        reason:
            'Flood ${flood.toStringAsFixed(0)}% at ${speed.toStringAsFixed(0)} km/h',
        recommendation:
            'Do not drive through flood water — hydroplaning and hidden hazards likely.',
      );
    }
    if (flood >= 5 && speed >= 40) {
      return RiskRuleHit(
        ruleId: id,
        ruleName: name,
        score: 60,
        level: RiskLevel.high,
        reason:
            'Flood ${flood.toStringAsFixed(0)}% at ${speed.toStringAsFixed(0)} km/h',
        recommendation:
            'Reduce speed sharply — water on road increases stopping distance.',
      );
    }
    return null;
  }
}
