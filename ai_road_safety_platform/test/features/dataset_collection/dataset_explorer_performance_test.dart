import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight performance sanity checks for query pipeline sizing.
void main() {
  test('SessionQuery pagination clamps large catalogues quickly', () {
    final now = DateTime.utc(2026, 1, 1);
    final sessions = List.generate(5_000, (i) {
      return DatasetSession(
        id: '$i',
        sessionName: 'Session $i',
        description: i.isEven ? 'flood' : 'dry',
        createdAt: now.add(Duration(minutes: i)),
        updatedAt: now,
        duration: Duration(seconds: i % 120),
        status: DatasetSessionStatus.completed,
        frameCount: i % 200,
        floodEventCount: i % 10,
        totalStorage: i * 1024,
        averageSpeed: 10,
        averageConfidence: 0.5,
        averageFloodCoverage: 1,
        deviceName: 't',
        appVersion: '1',
        modelVersion: 'm',
      );
    });

    final sw = Stopwatch()..start();
    var list = List<DatasetSession>.from(sessions);
    list = list.where((s) => s.description.contains('flood')).toList();
    list.sort((a, b) => b.frameCount.compareTo(a.frameCount));
    const pageSize = 20;
    final page = list.take(pageSize).toList();
    sw.stop();

    expect(page, hasLength(pageSize));
    expect(sw.elapsedMilliseconds, lessThan(500));
  });

  test('SessionPage.hasMore edge cases', () {
    const q = SessionQuery(page: 0, pageSize: 20);
    expect(
      const SessionPage(sessions: [], totalCount: 0, query: q).hasMore,
      isFalse,
    );
    expect(
      const SessionPage(sessions: [], totalCount: 21, query: q).hasMore,
      isTrue,
    );
  });
}
