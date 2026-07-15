import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig exposes research identity', () {
    expect(AppConfig.appName, 'AI Road Safety Platform');
    expect(AppConfig.researchTitle, contains('Flooded Road'));
  });
}
