import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_explorer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DatasetSession _session() {
  final now = DateTime.utc(2026, 7, 14);
  return DatasetSession(
    id: '1',
    sessionName: 'Night Drive',
    description: 'Urban flood check',
    createdAt: now,
    updatedAt: now,
    duration: const Duration(minutes: 12),
    status: DatasetSessionStatus.completed,
    frameCount: 100,
    floodEventCount: 4,
    totalStorage: 2048,
    averageSpeed: 32,
    averageConfidence: 0.88,
    averageFloodCoverage: 12,
    deviceName: 'Pixel',
    appVersion: '1',
    modelVersion: 'm1',
  );
}

void main() {
  testWidgets('ExplorerSessionCard renders metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ExplorerSessionCard(session: _session()),
          ),
        ),
      ),
    );

    expect(find.text('Night Drive'), findsOneWidget);
    expect(find.textContaining('100 frames'), findsOneWidget);
    expect(find.textContaining('4 floods'), findsOneWidget);
  });

  testWidgets('StatisticsCards shows session count', (tester) async {
    final data = DatasetDashboardData(
      statistics: const DatasetStatistics(
        totalSessions: 3,
        totalFrames: 300,
        totalFloodEvents: 9,
        totalStorage: 4096,
        averageSpeed: 25,
        averageConfidence: 0.7,
      ),
      collectionStorage: const DatasetStorage(
        totalDiskSpace: 0,
        usedDiskSpace: 4096,
        remainingDiskSpace: 0,
        datasetFolder: '/tmp',
      ),
      diskUsage: const StorageUsage(
        datasetRoot: '/tmp',
        usedBytes: 4096,
        freeBytes: 0,
        totalBytes: 0,
        softLimitBytes: 1 << 30,
        isLowStorage: false,
      ),
      recentSessions: [_session()],
      totalRecordingTime: const Duration(minutes: 30),
      framesPerMinute: 10,
      averageFloodCoverage: 8,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatisticsCards(data: data),
          ),
        ),
      ),
    );

    expect(find.text('3'), findsWidgets);
    expect(find.text('Sessions'), findsOneWidget);
  });

  testWidgets('ThumbnailGrid empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ThumbnailGrid(previews: []),
        ),
      ),
    );

    expect(find.text('No preview images'), findsOneWidget);
  });

  testWidgets('ExplorerLoadingState shows message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExplorerLoadingState(message: 'Loading dashboard…'),
        ),
      ),
    );

    expect(find.text('Loading dashboard…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
