import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/sensor_fusion_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/sensor_fusion_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/sensor_fusion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'sensor_fusion_event.dart';
export 'sensor_fusion_state.dart';

/// Sensor fusion session orchestration (Phase 13.7).
class SensorFusionBloc extends Bloc<SensorFusionEvent, SensorFusionState> {
  final LoadSensorFusionSnapshotUseCase _load;
  final StartSensorFusionUseCase _start;
  final StopSensorFusionUseCase _stop;
  final FuseSensorTickUseCase _tick;
  final CreateDemoFusedSampleUseCase _demo;
  final ClearFusionSamplesUseCase _clear;
  final AppLogger _logger;

  SensorFusionBloc({
    required LoadSensorFusionSnapshotUseCase loadSensorFusionSnapshot,
    required StartSensorFusionUseCase startSensorFusion,
    required StopSensorFusionUseCase stopSensorFusion,
    required FuseSensorTickUseCase fuseSensorTick,
    required CreateDemoFusedSampleUseCase createDemoFusedSample,
    required ClearFusionSamplesUseCase clearFusionSamples,
    required AppLogger logger,
  })  : _load = loadSensorFusionSnapshot,
        _start = startSensorFusion,
        _stop = stopSensorFusion,
        _tick = fuseSensorTick,
        _demo = createDemoFusedSample,
        _clear = clearFusionSamples,
        _logger = logger,
        super(const SensorFusionInitial()) {
    on<SensorFusionLoad>(_onLoad);
    on<SensorFusionRefresh>(_onLoad);
    on<SensorFusionStart>(_onStart);
    on<SensorFusionStop>(_onStop);
    on<SensorFusionTick>(_onTick);
    on<SensorFusionCreateDemo>(_onDemo);
    on<SensorFusionClear>(_onClear);
  }

  Future<void> _onLoad(
    SensorFusionEvent event,
    Emitter<SensorFusionState> emit,
  ) async {
    emit(const SensorFusionLoading());
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(SensorFusionLoaded(snapshot: snap)),
      onErr: (f) => emit(SensorFusionError(failure: f)),
    );
  }

  Future<void> _onStart(
    SensorFusionStart event,
    Emitter<SensorFusionState> emit,
  ) async {
    emit(const SensorFusionLoading(message: 'Starting fusion…'));
    final result = await _start(const StartSensorFusionParams());
    await result.fold(
      onOk: (s) async {
        _logger.info('Fusion started ${s.id}', tag: 'SensorFusionBloc');
        await _reload(emit, message: 'Fusion running');
      },
      onErr: (f) async => emit(SensorFusionError(failure: f)),
    );
  }

  Future<void> _onStop(
    SensorFusionStop event,
    Emitter<SensorFusionState> emit,
  ) async {
    emit(const SensorFusionLoading(message: 'Stopping…'));
    final result = await _stop(const NoParams());
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Fusion stopped'),
      onErr: (f) async => emit(SensorFusionError(failure: f)),
    );
  }

  Future<void> _onTick(
    SensorFusionTick event,
    Emitter<SensorFusionState> emit,
  ) async {
    final result = await _tick(const NoParams());
    await result.fold(
      onOk: (sample) async => _reload(
        emit,
        message:
            'Tick · Q=${sample.qualityScore.toStringAsFixed(0)} · '
            '${sample.qualityBand.label}',
      ),
      onErr: (f) async => emit(SensorFusionError(failure: f)),
    );
  }

  Future<void> _onDemo(
    SensorFusionCreateDemo event,
    Emitter<SensorFusionState> emit,
  ) async {
    emit(const SensorFusionLoading(message: 'Creating demo sample…'));
    final result = await _demo(const NoParams());
    await result.fold(
      onOk: (s) async => _reload(
        emit,
        message:
            'Demo · Q=${s.qualityScore.toStringAsFixed(0)} · '
            '${s.sourcesPresent.length} sources',
      ),
      onErr: (f) async => emit(SensorFusionError(failure: f)),
    );
  }

  Future<void> _onClear(
    SensorFusionClear event,
    Emitter<SensorFusionState> emit,
  ) async {
    emit(const SensorFusionLoading(message: 'Clearing…'));
    final result = await _clear(const NoParams());
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Samples cleared'),
      onErr: (f) async => emit(SensorFusionError(failure: f)),
    );
  }

  Future<void> _reload(
    Emitter<SensorFusionState> emit, {
    String? message,
  }) async {
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        SensorFusionLoaded(snapshot: snap, statusMessage: message),
      ),
      onErr: (f) => emit(SensorFusionError(failure: f)),
    );
  }
}
