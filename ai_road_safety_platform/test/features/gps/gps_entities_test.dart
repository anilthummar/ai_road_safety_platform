import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGpsRepository extends Mock implements GpsRepository {}

void main() {
  late _MockGpsRepository repository;

  setUp(() {
    repository = _MockGpsRepository();
  });

  test('GpsFix formats coordinates and speed', () {
    final fix = GpsFix(
      latitude: 25.2048,
      longitude: 55.2708,
      accuracyMeters: 4.2,
      altitudeMeters: 12,
      speedMetersPerSecond: 10,
      headingDegrees: 90,
      timestamp: DateTime.utc(2026, 7, 14, 8),
    );

    expect(fix.coordinateLabel, contains('25.204800'));
    expect(fix.speedKmh, closeTo(36, 0.01));
  });

  test('repository getCurrentLocation returns Ok', () async {
    final fix = GpsFix(
      latitude: 1,
      longitude: 2,
      accuracyMeters: 3,
      timestamp: DateTime.utc(2026),
    );
    when(repository.getCurrentLocation).thenAnswer((_) async => Ok(fix));

    final result = await repository.getCurrentLocation();
    expect(result.isOk, isTrue);
    expect(result.getOrThrow().latitude, 1);
  });
}
