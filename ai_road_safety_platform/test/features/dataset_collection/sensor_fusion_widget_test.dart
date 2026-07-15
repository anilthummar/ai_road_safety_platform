import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/sensor_fusion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SensorFusionSummaryCard shows status', (tester) async {
    final snap = SensorFusionSnapshot(
      session: SensorFusionSession(
        id: 's1',
        isRunning: true,
        startedAt: DateTime.utc(2026, 7, 14),
        sampleCount: 3,
      ),
      recentSamples: [
        FusedSample(
          id: 'f1',
          timestamp: DateTime.utc(2026, 7, 14),
          qualityScore: 80,
          qualityBand: FusionQualityBand.high,
          sourcesPresent: const [
            FusionSensorChannel.gps,
            FusionSensorChannel.imu,
          ],
        ),
      ],
      channels: const [],
      generatedAt: DateTime.utc(2026, 7, 14),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SensorFusionSummaryCard(snapshot: snap)),
      ),
    );
    expect(find.textContaining('Running'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
  });
}
