import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/flood_coverage_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/flood_speed_compound_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/gps_accuracy_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/imu_tilt_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/imu_vibration_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/vehicle_speed_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Factory for the production business-rule set (separate from engine wiring).
List<RiskRule> createDefaultRiskRules() {
  return const [
    FloodCoverageRule(),
    VehicleSpeedRule(),
    GpsAccuracyRule(),
    ImuVibrationRule(),
    ImuTiltRule(),
    FloodSpeedCompoundRule(),
  ];
}
