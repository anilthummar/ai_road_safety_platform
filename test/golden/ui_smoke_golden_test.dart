import 'package:ai_road_safety_platform/features/analytics/presentation/widgets/analytics_stats_widgets.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/widgets/risk_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('RiskLevelChip golden — medium', (tester) async {
    await tester.pumpWidget(wrap(const RiskLevelChip(level: RiskLevel.medium)));
    await expectLater(
      find.byType(RiskLevelChip),
      matchesGoldenFile('goldens/risk_level_chip_medium.png'),
    );
  });

  testWidgets('AnalyticsPeriodSelector golden — weekly selected', (tester) async {
    await tester.pumpWidget(
      wrap(
        AnalyticsPeriodSelector(
          period: AnalyticsPeriod.weekly,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AnalyticsPeriodSelector),
      matchesGoldenFile('goldens/analytics_period_selector_weekly.png'),
    );
  });

  testWidgets('RiskLevelBadge golden — high', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RiskLevelBadge(level: RiskLevel.high, score: 62),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RiskLevelBadge),
      matchesGoldenFile('goldens/risk_level_badge_high.png'),
    );
  });
}
