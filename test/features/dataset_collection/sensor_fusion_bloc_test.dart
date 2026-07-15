import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/sensor_fusion_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/sensor_fusion_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoad extends Mock implements LoadSensorFusionSnapshotUseCase {}

class _MockStart extends Mock implements StartSensorFusionUseCase {}

class _MockStop extends Mock implements StopSensorFusionUseCase {}

class _MockTick extends Mock implements FuseSensorTickUseCase {}

class _MockDemo extends Mock implements CreateDemoFusedSampleUseCase {}

class _MockClear extends Mock implements ClearFusionSamplesUseCase {}

void main() {
  late _MockLoad load;
  late _MockStart start;
  late _MockStop stop;
  late _MockTick tick;
  late _MockDemo demo;
  late _MockClear clear;

  final now = DateTime.utc(2026, 7, 14);
  final sample = FusedSample(
    id: 'f1',
    timestamp: now,
    qualityScore: 82,
    qualityBand: FusionQualityBand.high,
    sourcesPresent: const [
      FusionSensorChannel.camera,
      FusionSensorChannel.gps,
      FusionSensorChannel.imu,
    ],
  );
  final snap = SensorFusionSnapshot(
    recentSamples: [sample],
    channels: const [
      FusionChannelStatus(
        channel: FusionSensorChannel.sonar,
        health: FusionChannelHealth.disabled,
        ageMs: 0,
      ),
    ],
    generatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const StartSensorFusionParams());
  });

  setUp(() {
    load = _MockLoad();
    start = _MockStart();
    stop = _MockStop();
    tick = _MockTick();
    demo = _MockDemo();
    clear = _MockClear();
    when(() => load(any())).thenAnswer((_) async => Ok(snap));
  });

  SensorFusionBloc build() => SensorFusionBloc(
        loadSensorFusionSnapshot: load,
        startSensorFusion: start,
        stopSensorFusion: stop,
        fuseSensorTick: tick,
        createDemoFusedSample: demo,
        clearFusionSamples: clear,
        logger: AppLogger(),
      );

  blocTest<SensorFusionBloc, SensorFusionState>(
    'load emits loaded snapshot',
    build: build,
    act: (b) => b.add(const SensorFusionLoad()),
    expect: () => [
      isA<SensorFusionLoading>(),
      isA<SensorFusionLoaded>().having(
        (s) => s.snapshot.recentSamples.length,
        'samples',
        1,
      ),
    ],
  );

  blocTest<SensorFusionBloc, SensorFusionState>(
    'demo then reloads',
    build: build,
    setUp: () {
      when(() => demo(any())).thenAnswer((_) async => Ok(sample));
    },
    act: (b) => b.add(const SensorFusionCreateDemo()),
    expect: () => [
      isA<SensorFusionLoading>(),
      isA<SensorFusionLoaded>().having(
        (s) => s.statusMessage,
        'msg',
        contains('Demo'),
      ),
    ],
  );
}
