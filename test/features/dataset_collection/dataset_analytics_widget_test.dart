import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_analytics_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatisticsGrid renders KPIs', (tester) async {
    const overview = DatasetAnalyticsOverview(
      totalSessions: 4,
      totalFrames: 400,
      totalRecordingTime: Duration(minutes: 40),
      totalFloodEvents: 12,
      averageRecordingDuration: Duration(minutes: 10),
      averageSpeed: 28,
      averageFloodConfidence: 0.77,
      averageWaterCoverage: 9,
      storageUsedBytes: 4096,
      storageRemainingSoftBytes: 100000,
      datasetGrowth: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: StatisticsGrid(overview: overview),
          ),
        ),
      ),
    );

    expect(find.text('4'), findsWidgets);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Frames'), findsOneWidget);
  });

  testWidgets('DatasetQualityCard shows completeness', (tester) async {
    const quality = DatasetQualityMetrics(
      framesPerSession: 10,
      framesPerMinute: 5,
      captureFrequencyHz: 0.1,
      captureSuccessRate: 0.9,
      averageCaptureIntervalSeconds: 10,
      completenessScore: 72,
      missingMetadataCount: 1,
      corruptedFrameCount: 0,
      emptySessionCount: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DatasetQualityCard(quality: quality),
          ),
        ),
      ),
    );

    expect(find.textContaining('72'), findsOneWidget);
    expect(find.text('Empty sessions'), findsOneWidget);
  });

  testWidgets('AnalyticsPieChart empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: AnalyticsPieChart(points: []),
          ),
        ),
      ),
    );
    expect(find.text('No chart data'), findsOneWidget);
  });

  testWidgets('AnalyticsEmptyState', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalyticsEmptyState(),
        ),
      ),
    );
    expect(find.text('No analytics data'), findsOneWidget);
  });
}
