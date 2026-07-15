import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/default_risk_rule_engine.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/risk_rules.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DefaultRiskRuleEngine engine;

  setUp(() {
    engine = DefaultRiskRuleEngine(rules: createDefaultRiskRules());
  });

  RiskInputSnapshot snapshot({
    double flood = 0,
    double speed = 0,
    double? gpsAccuracy = 5,
    double tilt = 0,
    VibrationIntensity vibration = VibrationIntensity.calm,
    double rms = 0.05,
    bool hasFlood = true,
    bool hasGps = true,
    bool hasImu = true,
  }) {
    return RiskInputSnapshot(
      floodCoveragePercent: flood,
      speedKmh: speed,
      gpsAccuracyMeters: gpsAccuracy,
      latitude: 25.2,
      longitude: 55.27,
      tiltDegrees: tilt,
      vibrationIntensity: vibration,
      vibrationRms: rms,
      hasGpsFix: hasGps,
      hasImuSample: hasImu,
      hasFloodSample: hasFlood,
      timestamp: DateTime.utc(2026, 7, 14),
    );
  }

  test('low flood and calm sensors → Low', () {
    final result = engine.evaluate(snapshot(flood: 1, speed: 25));
    expect(result.level, RiskLevel.low);
    expect(result.score, lessThan(25));
  });

  test('moderate flood water → Medium or higher', () {
    final result = engine.evaluate(snapshot(flood: 10, speed: 20));
    expect(result.level.rank, greaterThanOrEqualTo(RiskLevel.medium.rank));
    expect(
      result.triggeredRules.any((r) => r.ruleId == 'flood_coverage'),
      isTrue,
    );
    expect(result.recommendations, isNotEmpty);
  });

  test('flood at speed compound → Extreme', () {
    final result = engine.evaluate(snapshot(flood: 22, speed: 50));
    expect(result.level, RiskLevel.extreme);
    expect(
      result.triggeredRules.any((r) => r.ruleId == 'flood_speed_compound'),
      isTrue,
    );
    expect(
      result.recommendations.first.message.toLowerCase(),
      contains('flood'),
    );
  });

  test('severe vibration contributes High', () {
    final result = engine.evaluate(
      snapshot(
        flood: 0,
        speed: 30,
        vibration: VibrationIntensity.severe,
        rms: 2.5,
      ),
    );
    expect(result.level.rank, greaterThanOrEqualTo(RiskLevel.high.rank));
  });

  test('RiskLevel.fromScore boundaries', () {
    expect(RiskLevelX.fromScore(0), RiskLevel.low);
    expect(RiskLevelX.fromScore(25), RiskLevel.medium);
    expect(RiskLevelX.fromScore(50), RiskLevel.high);
    expect(RiskLevelX.fromScore(75), RiskLevel.extreme);
  });

  test('default rules set is non-empty and unique ids', () {
    final rules = createDefaultRiskRules();
    expect(rules.length, greaterThanOrEqualTo(5));
    final ids = rules.map((r) => r.id).toSet();
    expect(ids.length, rules.length);
  });

  test('tilt while stationary does not raise Extreme', () {
    final result = engine.evaluate(
      snapshot(flood: 0, speed: 0, tilt: 50, hasGps: false, gpsAccuracy: null),
    );
    expect(result.level, isNot(RiskLevel.extreme));
    expect(
      result.triggeredRules.any((r) => r.ruleId == 'imu_tilt'),
      isFalse,
    );
  });

  test('extreme relative tilt while moving raises Extreme', () {
    final result = engine.evaluate(
      snapshot(flood: 0, speed: 40, tilt: 45),
    );
    expect(result.level, RiskLevel.extreme);
    expect(
      result.triggeredRules.any((r) => r.ruleId == 'imu_tilt'),
      isTrue,
    );
  });
}
