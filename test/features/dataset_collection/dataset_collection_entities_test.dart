import 'package:ai_road_safety_platform/features/dataset_collection/data/models/dataset_collection_models.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DatasetSessionModel json round trip', () {
    final now = DateTime.utc(2026, 7, 14, 10);
    final session = DatasetSession(
      id: 'abc',
      sessionName: 'Coastal',
      description: 'morning',
      createdAt: now,
      updatedAt: now,
      duration: const Duration(seconds: 12),
      status: DatasetSessionStatus.idle,
      frameCount: 0,
      floodEventCount: 0,
      totalStorage: 1024,
      averageSpeed: 12.5,
      averageConfidence: 0.4,
      averageFloodCoverage: 3.2,
      deviceName: 'android device',
      appVersion: '1.0.0',
      modelVersion: 'pending',
    );

    final model = DatasetSessionModel.fromDomain(session);
    final decoded = DatasetSessionModel.fromJson(model.toJson()).toDomain();

    expect(decoded.id, session.id);
    expect(decoded.sessionName, session.sessionName);
    expect(decoded.duration, session.duration);
    expect(decoded.status, DatasetSessionStatus.idle);
    expect(decoded.totalStorage, 1024);
    expect(decoded.floodEvents, 0);
    expect(decoded.storageUsed, 1024);
  });

  test('legacy status names map correctly', () {
    expect(DatasetSessionStatusX.parse('ready'), DatasetSessionStatus.idle);
    expect(
      DatasetSessionStatusX.parse('active'),
      DatasetSessionStatus.recording,
    );
  });

  test('DatasetStatistics.empty defaults', () {
    const stats = DatasetStatistics.empty();
    expect(stats.totalSessions, 0);
    expect(stats.averageConfidence, 0);
  });
}
