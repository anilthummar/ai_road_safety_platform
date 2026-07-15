import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Excessive vehicle bank / tip raises instability risk.
///
/// Uses [RiskInputSnapshot.tiltDegrees] which is relative to the mount pose
/// captured when IMU streaming starts. Ignored while stationary so desk / idle
/// phone use does not trigger Extreme risk.
class ImuTiltRule implements RiskRule {
  const ImuTiltRule();

  /// Minimum speed before vehicle-tilt risk is considered.
  static const double minSpeedKmh = 8;

  @override
  String get id => 'imu_tilt';

  @override
  String get name => 'Vehicle tilt';

  @override
  RiskRuleHit? evaluate(RiskInputSnapshot input) {
    if (!input.hasImuSample) return null;
    // Desk / parked phone mount lean must not create embankment alarms.
    if (!input.hasGpsFix || input.speedKmh < minSpeedKmh) return null;

    final tilt = input.tiltDegrees.abs();

    final (score, level, tip) = switch (tilt) {
      >= 40 => (
          80.0,
          RiskLevel.extreme,
          'Extreme tilt — stop when safe; check for embankment or instability.',
        ),
      >= 25 => (
          55.0,
          RiskLevel.high,
          'High tilt detected — reduce speed and avoid sudden maneuvers.',
        ),
      >= 15 => (
          30.0,
          RiskLevel.medium,
          'Noticeable tilt — proceed cautiously on uneven / flooded grades.',
        ),
      _ => (0.0, RiskLevel.low, null),
    };
    if (score <= 0) return null;
    return RiskRuleHit(
      ruleId: id,
      ruleName: name,
      score: score,
      level: level,
      reason: 'Tilt ${tilt.toStringAsFixed(1)}°',
      recommendation: tip,
    );
  }
}
