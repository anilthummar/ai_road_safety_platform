import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryRecord record({
    required String id,
    RiskLevel level = RiskLevel.low,
    double flood = 0,
    DateTime? at,
    String? notes,
    String? imagePath,
  }) {
    return HistoryRecord(
      id: id,
      timestamp: at ?? DateTime.utc(2026, 7, 14, 10),
      floodPercent: flood,
      riskLevel: level,
      riskScore: level.index * 25.0,
      speedKmh: 40,
      latitude: 25.2,
      longitude: 55.27,
      notes: notes,
      imagePath: imagePath,
    );
  }

  test('searchBlob matches risk and coords', () {
    final r = record(id: 'abc', level: RiskLevel.high, notes: 'washout');
    expect(r.searchBlob, contains('high'));
    expect(r.searchBlob, contains('25.2000'));
    expect(r.searchBlob, contains('washout'));
  });

  test('toJson includes required persistence fields', () {
    final json = record(
      id: '1',
      level: RiskLevel.extreme,
      flood: 22,
      imagePath: '/tmp/a.jpg',
    ).toJson();

    expect(json['floodPercent'], 22);
    expect(json['riskLevel'], 'extreme');
    expect(json['timestamp'], isA<String>());
    expect(json['imagePath'], '/tmp/a.jpg');
    expect(json['latitude'], 25.2);
  });

  test('HistoryFilter search + risk + flood', () {
    final records = [
      record(id: 'a', level: RiskLevel.low, flood: 2),
      record(id: 'b', level: RiskLevel.high, flood: 12, notes: 'bridge'),
      record(id: 'c', level: RiskLevel.extreme, flood: 30, imagePath: 'x.jpg'),
    ];

    final filtered = const HistoryFilter(
      searchQuery: 'bridge',
      riskLevels: {RiskLevel.high},
      minFloodPercent: 8,
    ).apply(records);

    expect(filtered.map((e) => e.id), ['b']);
  });

  test('images-only filter', () {
    final records = [
      record(id: 'a'),
      record(id: 'b', imagePath: '/img.jpg'),
    ];
    final filtered =
        const HistoryFilter(hasImageOnly: true).apply(records);
    expect(filtered.single.id, 'b');
  });
}
