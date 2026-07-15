import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Poor GNSS accuracy raises uncertainty risk for fused decisions.
class GpsAccuracyRule implements RiskRule {
  const GpsAccuracyRule();
  @override
  String get id => 'gps_accuracy';

  @override
  String get name => 'GPS accuracy';

  @override
  RiskRuleHit? evaluate(RiskInputSnapshot input) {
    // No-fix is covered by the driver HUD gps_missing warning — avoid dupes.
    if (!input.hasGpsFix) return null;
    final accuracy = input.gpsAccuracyMeters;
    if (accuracy == null) return null;

    final (score, level, tip) = switch (accuracy) {
      >= 50 => (
          45.0,
          RiskLevel.medium,
          'GPS accuracy is poor — do not rely solely on navigation near hazards.',
        ),
      >= 25 => (
          28.0,
          RiskLevel.medium,
          'GPS accuracy is fair — double-check lane / turn guidance.',
        ),
      >= 15 => (
          15.0,
          RiskLevel.low,
          null,
        ),
      _ => (0.0, RiskLevel.low, null),
    };
    if (score <= 0) return null;
    return RiskRuleHit(
      ruleId: id,
      ruleName: name,
      score: score,
      level: level,
      reason: 'GPS ±${accuracy.toStringAsFixed(0)} m',
      recommendation: tip,
    );
  }
}
