import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_warning_builder.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = DriverWarningBuilder();

  test('clear conditions produce no critical warnings', () {
    final warnings = builder.build(
      floodCoveragePercent: 1,
      hasFloodSample: true,
      speedKmh: 30,
      hasGpsFix: true,
      gpsAccuracyMeters: 5,
      riskLevel: RiskLevel.low,
      hasRiskAssessment: true,
    );

    expect(
      warnings.any((w) => w.severity == DriverWarningSeverity.critical),
      isFalse,
    );
  });

  test('high flood and speed create critical flood_speed warning', () {
    final warnings = builder.build(
      floodCoveragePercent: 12,
      hasFloodSample: true,
      speedKmh: 55,
      hasGpsFix: true,
      gpsAccuracyMeters: 8,
      riskLevel: RiskLevel.medium,
      hasRiskAssessment: true,
    );

    expect(warnings.any((w) => w.id == 'flood_speed'), isTrue);
    expect(
      warnings.first.severity,
      DriverWarningSeverity.critical,
    );
  });

  test('missing GPS yields info warning', () {
    final warnings = builder.build(
      floodCoveragePercent: 0,
      hasFloodSample: false,
      speedKmh: 0,
      hasGpsFix: false,
      gpsAccuracyMeters: null,
      riskLevel: RiskLevel.low,
      hasRiskAssessment: false,
    );

    expect(warnings.any((w) => w.id == 'gps_missing'), isTrue);
  });

  test('extreme risk is ranked first', () {
    final warnings = builder.build(
      floodCoveragePercent: 5,
      hasFloodSample: true,
      speedKmh: 20,
      hasGpsFix: true,
      gpsAccuracyMeters: 10,
      riskLevel: RiskLevel.extreme,
      hasRiskAssessment: true,
      recommendations: const [
        RiskRecommendation(
          priority: 50,
          ruleId: 'x',
          message: 'Minor tip',
        ),
      ],
    );

    expect(warnings.first.id, 'risk_extreme');
  });
}
