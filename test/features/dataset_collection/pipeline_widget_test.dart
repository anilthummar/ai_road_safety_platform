import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/pipeline_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PipelineStatusCard shows status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PipelineStatusCard(
            monitor: PipelineMonitorSnapshot(
              status: PipelineStatus.running,
              currentStage: PipelineStageKind.storage,
              updatedAt: DateTime.utc(2026, 7, 14),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Running'), findsWidgets);
    expect(find.textContaining('Storage'), findsOneWidget);
  });

  testWidgets('ProcessingStatistics shows completed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProcessingStatistics(
            monitor: PipelineMonitorSnapshot(
              status: PipelineStatus.running,
              completedTasks: 7,
              failedTasks: 1,
              retryCount: 2,
              processingSpeedPerSec: 3.5,
              averageTaskTime: const Duration(milliseconds: 40),
              updatedAt: DateTime.utc(2026, 7, 14),
            ),
          ),
        ),
      ),
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.textContaining('3.5/s'), findsOneWidget);
  });
}
