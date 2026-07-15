import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/experiment_tracking_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExperimentTrackerSummaryCard shows counts', (tester) async {
    final now = DateTime.utc(2026, 7, 14);
    final snap = ExperimentTrackerSnapshot(
      runs: [
        ExperimentRun(
          id: 'r1',
          name: 'Run Alpha',
          experimentName: 'road-detection',
          status: ExperimentRunStatus.completed,
          metrics: const {'mAP50': 0.62},
          createdAt: now,
          updatedAt: now,
        ),
      ],
      generatedAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExperimentTrackerSummaryCard(snapshot: snap),
        ),
      ),
    );
    expect(find.textContaining('runs'), findsOneWidget);
    expect(find.textContaining('Run Alpha'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}
