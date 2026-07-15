import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Maps vehicle vibration intensity to risk contribution.
class ImuVibrationRule implements RiskRule {
  const ImuVibrationRule();
  @override
  String get id => 'imu_vibration';

  @override
  String get name => 'Vehicle vibration';

  @override
  RiskRuleHit? evaluate(RiskInputSnapshot input) {
    if (!input.hasImuSample) return null;

    final (score, level, tip) = switch (input.vibrationIntensity) {
      VibrationIntensity.severe => (
          78.0,
          RiskLevel.high,
          'Severe vibration — possible rough surface or impact; slow down and scan for hazards.',
        ),
      VibrationIntensity.rough => (
          52.0,
          RiskLevel.high,
          'Rough road vibration — reduce speed and watch for washouts / debris.',
        ),
      VibrationIntensity.moderate => (
          28.0,
          RiskLevel.medium,
          'Moderate vibration — stay alert for uneven pavement.',
        ),
      VibrationIntensity.calm => (0.0, RiskLevel.low, null),
    };
    if (score <= 0) return null;
    return RiskRuleHit(
      ruleId: id,
      ruleName: name,
      score: score,
      level: level,
      reason:
          'Vibration ${input.vibrationIntensity.name} (RMS ${input.vibrationRms.toStringAsFixed(2)})',
      recommendation: tip,
    );
  }
}
