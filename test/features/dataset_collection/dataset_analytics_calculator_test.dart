import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_analytics_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

DatasetSession _session({
  required String id,
  required String name,
  DateTime? createdAt,
  Duration duration = const Duration(minutes: 10),
  int frames = 100,
  int floods = 2,
  int storage = 1024 * 1024,
  double speed = 30,
  double confidence = 0.8,
  double coverage = 12,
  DatasetSessionStatus status = DatasetSessionStatus.completed,
}) {
  final now = createdAt ?? DateTime.utc(2026, 7, 10, 14);
  return DatasetSession(
    id: id,
    sessionName: name,
    description: 'd-$name',
    createdAt: now,
    updatedAt: now,
    startedAt: now,
    duration: duration,
    status: status,
    frameCount: frames,
    floodEventCount: floods,
    totalStorage: storage,
    averageSpeed: speed,
    averageConfidence: confidence,
    averageFloodCoverage: coverage,
    deviceName: 't',
    appVersion: '1',
    modelVersion: 'm',
  );
}

void main() {
  const calc = DatasetAnalyticsCalculator();
  const usage = StorageUsage(
    datasetRoot: '/tmp/dataset',
    usedBytes: 5 * 1024 * 1024,
    freeBytes: 0,
    totalBytes: 0,
    softLimitBytes: 100 * 1024 * 1024,
    isLowStorage: false,
  );

  test('build aggregates overview and insights', () {
    final sessions = [
      _session(id: '1', name: 'A', frames: 60, duration: const Duration(minutes: 2)),
      _session(
        id: '2',
        name: 'B',
        frames: 0,
        floods: 0,
        speed: 0,
        duration: const Duration(minutes: 30),
        createdAt: DateTime.utc(2026, 7, 11, 9),
      ),
      _session(
        id: '3',
        name: 'C',
        frames: 200,
        floods: 9,
        confidence: 0.95,
        storage: 50 * 1024 * 1024,
        createdAt: DateTime.utc(2026, 7, 12, 18),
      ),
    ];

    final report = calc.build(
      sessions: sessions,
      usage: usage,
      folders: const [
        FolderInfo(
          label: 'Images',
          path: '/tmp/dataset/sessions/x/images',
          sizeBytes: 4 * 1024 * 1024,
          fileCount: 10,
        ),
        FolderInfo(
          label: 'Metadata',
          path: '/tmp/dataset/sessions/x/metadata',
          sizeBytes: 1000,
          fileCount: 10,
        ),
      ],
      filter: const AnalyticsFilter(),
      recovery: const [
        AnalyticsRecoverySnapshot(
          sessionId: '1',
          imageCount: 60,
          metadataCount: 58,
          isIncomplete: true,
        ),
      ],
      now: DateTime.utc(2026, 7, 14),
    );

    expect(report.matchedSessionCount, 3);
    expect(report.overview.totalFrames, 260);
    expect(report.overview.totalFloodEvents, 11);
    expect(report.quality.emptySessionCount, 1);
    expect(report.quality.missingMetadataCount, 2);
    expect(report.insights.insights, isNotEmpty);
    expect(report.sessions.durationDistribution, isNotEmpty);
    expect(report.storage.imagesStorageBytes, greaterThan(0));
  });

  test('filter last7Days and search', () {
    final now = DateTime(2026, 7, 14, 12);
    final sessions = [
      _session(id: '1', name: 'Recent Flood', createdAt: now.subtract(const Duration(days: 2))),
      _session(
        id: '2',
        name: 'Old',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];

    final filtered = calc.applyFilter(
      sessions,
      const AnalyticsFilter(
        dateFilter: AnalyticsDateFilter.last7Days,
        searchQuery: 'flood',
      ),
      now: now,
    );
    expect(filtered.map((s) => s.id), ['1']);
  });

  test('empty input yields empty report', () {
    final report = calc.build(
      sessions: const [],
      usage: usage,
      folders: const [],
      filter: const AnalyticsFilter(),
    );
    expect(report.isEmpty, isTrue);
    expect(report.overview.totalSessions, 0);
    expect(report.quality.completenessScore, 0);
  });
}
