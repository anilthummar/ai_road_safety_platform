import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Scores standing-water / flood coverage from segmentation.
class FloodCoverageRule implements RiskRule {
  const FloodCoverageRule();
  @override
  String get id => 'flood_coverage';

  @override
  String get name => 'Flood coverage';

  @override
  RiskRuleHit? evaluate(RiskInputSnapshot input) {
    if (!input.hasFloodSample && input.floodCoveragePercent <= 0) {
      return null;
    }
    final pct = input.floodCoveragePercent;
    final (score, level, tip) = switch (pct) {
      >= 40 => (
          95.0,
          RiskLevel.extreme,
          'Extensive flooding detected — do not enter; seek alternate route.',
        ),
      >= 20 => (
          72.0,
          RiskLevel.high,
          'Significant water on roadway — slow immediately and avoid the flooded lane.',
        ),
      >= 8 => (
          48.0,
          RiskLevel.medium,
          'Possible standing water ahead — reduce speed and stay alert.',
        ),
      >= 3 => (
          22.0,
          RiskLevel.low,
          'Trace water detected — monitor surface conditions.',
        ),
      _ => (0.0, RiskLevel.low, null),
    };
    if (score <= 0) return null;
    return RiskRuleHit(
      ruleId: id,
      ruleName: name,
      score: score,
      level: level,
      reason: 'Flood coverage ${pct.toStringAsFixed(1)}%',
      recommendation: tip,
    );
  }
}
