import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/model_benchmark_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BenchmarkSummaryCard shows counts', (tester) async {
    final snap = BenchmarkSnapshot(
      reports: [
        BenchmarkReport(
          id: 'b1',
          modelId: 'bundled-yolov8n',
          createdAt: DateTime.utc(2026, 7, 14),
          metrics: const BenchmarkMetrics(
            truePositives: 2,
            falsePositives: 1,
            falseNegatives: 1,
            precision: 0.67,
            recall: 0.67,
            f1: 0.67,
            meanIou: 0.7,
            mapProxy: 0.55,
          ),
        ),
      ],
      generatedAt: DateTime.utc(2026, 7, 14),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BenchmarkSummaryCard(snapshot: snap)),
      ),
    );
    expect(find.textContaining('reports'), findsOneWidget);
    expect(find.textContaining('bundled-yolov8n'), findsOneWidget);
  });
}
