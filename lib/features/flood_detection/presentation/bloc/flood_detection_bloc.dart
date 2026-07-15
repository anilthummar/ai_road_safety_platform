import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/usecases/flood_detection_usecases.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/flood_detection_event.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/flood_detection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'flood_detection_event.dart';
export 'flood_detection_state.dart';

/// Orchestrates flooded-road semantic segmentation.
class FloodDetectionBloc
    extends Bloc<FloodDetectionEvent, FloodDetectionState> {
  final InitializeFloodDetectionUseCase _initialize;
  final StartFloodDetectionUseCase _start;
  final StopFloodDetectionUseCase _stop;
  final DisposeFloodDetectionUseCase _dispose;
  final FloodDetectionRepository _repository;
  final AppLogger _logger;

  StreamSubscription<FloodDetectionSession>? _sessionSub;
  StreamSubscription<FloodSegmentationResult>? _resultSub;

  /// Creates [FloodDetectionBloc].
  FloodDetectionBloc({
    required InitializeFloodDetectionUseCase initialize,
    required StartFloodDetectionUseCase start,
    required StopFloodDetectionUseCase stop,
    required DisposeFloodDetectionUseCase dispose,
    required FloodDetectionRepository repository,
    required AppLogger logger,
  })  : _initialize = initialize,
        _start = start,
        _stop = stop,
        _dispose = dispose,
        _repository = repository,
        _logger = logger,
        super(const FloodDetectionInitial()) {
    on<FloodDetectionStarted>(_onStarted);
    on<FloodDetectionStreamStarted>(_onStreamStarted);
    on<FloodDetectionStreamStopped>(_onStreamStopped);
    on<FloodDetectionDisposed>(_onDisposed);
    on<FloodDetectionSessionUpdated>(_onSessionUpdated);
    on<FloodDetectionResultUpdated>(_onResultUpdated);
  }

  Future<void> _onStarted(
    FloodDetectionStarted event,
    Emitter<FloodDetectionState> emit,
  ) async {
    emit(const FloodDetectionLoading());
    final result = await _initialize(const NoParams());
    await result.fold(
      onOk: (session) async {
        await _bindStreams();
        emit(FloodDetectionActive(session: session));
        add(const FloodDetectionStreamStarted());
      },
      onErr: (failure) async {
        _logger.error(failure.message, tag: 'FloodDetectionBloc');
        emit(FloodDetectionError(failure));
      },
    );
  }

  Future<void> _onStreamStarted(
    FloodDetectionStreamStarted event,
    Emitter<FloodDetectionState> emit,
  ) async {
    // Lifecycle resume can fire before the engine is bootstrapped (e.g. the
    // OS permission dialog on fresh installs triggers inactive → resumed
    // while the camera is still initializing). The CameraReady listener
    // drives the initial FloodDetectionStarted, so ignore early requests.
    if (state is! FloodDetectionActive) return;

    final result = await _start(const NoParams());
    result.fold(
      onOk: (session) {
        final current = state;
        if (current is FloodDetectionActive) {
          emit(current.copyWith(session: session));
        } else {
          emit(FloodDetectionActive(session: session));
        }
      },
      onErr: (failure) => emit(FloodDetectionError(failure)),
    );
  }

  Future<void> _onStreamStopped(
    FloodDetectionStreamStopped event,
    Emitter<FloodDetectionState> emit,
  ) async {
    final result = await _stop(const NoParams());
    result.fold(
      onOk: (session) {
        final current = state;
        if (current is FloodDetectionActive) {
          emit(current.copyWith(session: session, clearResult: true));
        }
      },
      onErr: (failure) =>
          _logger.warning(failure.message, tag: 'FloodDetectionBloc'),
    );
  }

  Future<void> _onDisposed(
    FloodDetectionDisposed event,
    Emitter<FloodDetectionState> emit,
  ) async {
    await _unbindStreams();
    await _dispose(const NoParams());
    emit(const FloodDetectionInitial());
  }

  void _onSessionUpdated(
    FloodDetectionSessionUpdated event,
    Emitter<FloodDetectionState> emit,
  ) {
    final current = state;
    if (current is FloodDetectionActive) {
      emit(current.copyWith(session: event.session));
    }
  }

  void _onResultUpdated(
    FloodDetectionResultUpdated event,
    Emitter<FloodDetectionState> emit,
  ) {
    final current = state;
    if (current is FloodDetectionActive) {
      emit(current.copyWith(latestResult: event.result));
    }
  }

  Future<void> _bindStreams() async {
    await _unbindStreams();
    _sessionSub = _repository.watchSession().listen(
      (s) => add(FloodDetectionSessionUpdated(s)),
    );
    _resultSub = _repository.watchResults().listen(
      (r) => add(FloodDetectionResultUpdated(r)),
    );
  }

  Future<void> _unbindStreams() async {
    await _sessionSub?.cancel();
    await _resultSub?.cancel();
    _sessionSub = null;
    _resultSub = null;
  }

  @override
  Future<void> close() async {
    await _unbindStreams();
    await _dispose(const NoParams());
    return super.close();
  }
}
