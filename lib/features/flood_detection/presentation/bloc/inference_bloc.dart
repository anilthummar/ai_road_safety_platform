import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/inference_repository.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/usecases/inference_usecases.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/inference_event.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/inference_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'inference_event.dart';
export 'inference_state.dart';

/// Orchestrates YOLOv8 TFLite real-time inference for flood / hazard detection.
class InferenceBloc extends Bloc<InferenceEvent, InferenceState> {
  final InitializeInferenceUseCase _initialize;
  final StartInferenceUseCase _start;
  final StopInferenceUseCase _stop;
  final DisposeInferenceUseCase _dispose;
  final InferenceRepository _repository;
  final AppLogger _logger;

  StreamSubscription<InferenceSession>? _sessionSub;
  StreamSubscription<InferenceResult>? _resultSub;

  /// Creates [InferenceBloc].
  InferenceBloc({
    required InitializeInferenceUseCase initialize,
    required StartInferenceUseCase start,
    required StopInferenceUseCase stop,
    required DisposeInferenceUseCase dispose,
    required InferenceRepository repository,
    required AppLogger logger,
  })  : _initialize = initialize,
        _start = start,
        _stop = stop,
        _dispose = dispose,
        _repository = repository,
        _logger = logger,
        super(const InferenceInitial()) {
    on<InferenceStarted>(_onStarted);
    on<InferenceStreamStarted>(_onStreamStarted);
    on<InferenceStreamStopped>(_onStreamStopped);
    on<InferenceDisposed>(_onDisposed);
    on<InferenceSessionUpdated>(_onSessionUpdated);
    on<InferenceResultUpdated>(_onResultUpdated);
  }

  Future<void> _onStarted(
    InferenceStarted event,
    Emitter<InferenceState> emit,
  ) async {
    emit(const InferenceLoading());
    final result = await _initialize(const NoParams());
    await result.fold(
      onOk: (session) async {
        await _bindStreams();
        emit(InferenceActive(session: session));
        add(const InferenceStreamStarted());
      },
      onErr: (failure) async {
        _logger.error(failure.message, tag: 'InferenceBloc');
        emit(InferenceError(failure));
      },
    );
  }

  Future<void> _onStreamStarted(
    InferenceStreamStarted event,
    Emitter<InferenceState> emit,
  ) async {
    // Ignore lifecycle-resume requests before the engine is bootstrapped —
    // the camera-readiness listener drives the initial InferenceStarted.
    if (state is! InferenceActive) return;

    final result = await _start(const NoParams());
    result.fold(
      onOk: (session) {
        final current = state;
        if (current is InferenceActive) {
          emit(current.copyWith(session: session));
        } else {
          emit(InferenceActive(session: session));
        }
      },
      onErr: (failure) => emit(InferenceError(failure)),
    );
  }

  Future<void> _onStreamStopped(
    InferenceStreamStopped event,
    Emitter<InferenceState> emit,
  ) async {
    final result = await _stop(const NoParams());
    result.fold(
      onOk: (session) {
        final current = state;
        if (current is InferenceActive) {
          emit(current.copyWith(session: session, clearResult: true));
        }
      },
      onErr: (failure) => _logger.warning(failure.message, tag: 'InferenceBloc'),
    );
  }

  Future<void> _onDisposed(
    InferenceDisposed event,
    Emitter<InferenceState> emit,
  ) async {
    await _unbindStreams();
    await _dispose(const NoParams());
    emit(const InferenceInitial());
  }

  void _onSessionUpdated(
    InferenceSessionUpdated event,
    Emitter<InferenceState> emit,
  ) {
    final current = state;
    if (current is InferenceActive) {
      emit(current.copyWith(session: event.session));
    }
  }

  void _onResultUpdated(
    InferenceResultUpdated event,
    Emitter<InferenceState> emit,
  ) {
    final current = state;
    if (current is InferenceActive) {
      emit(
        current.copyWith(
          latestResult: event.result,
          session: current.session,
        ),
      );
    }
  }

  Future<void> _bindStreams() async {
    await _unbindStreams();
    _sessionSub = _repository.watchSession().listen(
      (session) => add(InferenceSessionUpdated(session)),
    );
    _resultSub = _repository.watchResults().listen(
      (result) => add(InferenceResultUpdated(result)),
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
