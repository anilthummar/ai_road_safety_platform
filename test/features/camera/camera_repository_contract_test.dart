import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  late _MockCameraRepository repository;

  setUp(() {
    repository = _MockCameraRepository();
  });

  test('repository initialize maps to Ok session', () async {
    const session = CameraSession(
      sessionId: '1',
      cameraName: '0',
      lens: CameraLensPreference.rear,
      previewWidth: 1280,
      previewHeight: 720,
      sensorOrientation: 90,
    );

    when(() => repository.initialize(lens: CameraLensPreference.rear))
        .thenAnswer((_) async => const Ok(session));

    final result = await repository.initialize();
    expect(result.isOk, isTrue);
    expect(result.getOrThrow().lens, CameraLensPreference.rear);
  });

  test('permission failure returns Err', () async {
    when(() => repository.requestPermission()).thenAnswer(
      (_) async => const Err(
        PermissionFailure(message: 'denied'),
      ),
    );

    final result = await repository.requestPermission();
    expect(result.isErr, isTrue);
  });
}
