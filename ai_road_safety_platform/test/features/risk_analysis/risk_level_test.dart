import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RiskLevel.fromScore boundaries stay stable', () {
    expect(RiskLevelX.fromScore(24.9), RiskLevel.low);
    expect(RiskLevelX.fromScore(25), RiskLevel.medium);
    expect(RiskLevelX.fromScore(49.9), RiskLevel.medium);
    expect(RiskLevelX.fromScore(50), RiskLevel.high);
    expect(RiskLevelX.fromScore(74.9), RiskLevel.high);
    expect(RiskLevelX.fromScore(75), RiskLevel.extreme);
  });

  test('RiskLevel labels are production-facing', () {
    expect(RiskLevel.low.label, 'Low');
    expect(RiskLevel.extreme.label, 'Extreme');
  });
}
