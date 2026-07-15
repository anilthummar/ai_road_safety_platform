import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/frame_capture_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/frame_capture_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/frame_capture_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'frame_capture_event.dart';
export 'frame_capture_state.dart';

/// Orchestrates the intelligent data acquisition engine (Phase 12.3).
class FrameCaptureBloc extends Bloc<FrameCaptureEvent, FrameCaptureState> {
  final StartFrameCaptureUseCase _start;
  final StopFrameCaptureUseCase _stop;
  final PauseFrameCaptureUseCase _pause;
  final ResumeFrameCaptureUseCase _resume;
  final CaptureSingleFrameUseCase _manual;
  final ClearFrameQueueUseCase _clearQueue;
  final FrameCaptureRepository _repository;
  final AppLogger _logger;

  StreamSubscription<FrameQueueSnapshot>? _queueSub;
  StreamSubscription<CapturedFrame>? _frameSub;
  String? _sessionId;
  FrameQueueSnapshot _queue = const FrameQueueSnapshot.empty();

  /// Creates [FrameCaptureBloc].
  FrameCaptureBloc({
    required StartFrameCaptureUseCase startCapture,
    required StopFrameCaptureUseCase stopCapture,
    required PauseFrameCaptureUseCase pauseCapture,
    required ResumeFrameCaptureUseCase resumeCapture,
    required CaptureSingleFrameUseCase captureSingleFrame,
    required ClearFrameQueueUseCase clearFrameQueue,
    required FrameCaptureRepository repository,
    required AppLogger logger,
  })  : _start = startCapture,
        _stop = stopCapture,
        _pause = pauseCapture,
        _resume = resumeCapture,
        _manual = captureSingleFrame,
        _clearQueue = clearFrameQueue,
        _repository = repository,
        _logger = logger,
        super(const FrameCaptureInitial()) {
    on<FrameCaptureStartCapture>(_onStart);
    on<FrameCaptureStopCapture>(_onStop);
    on<FrameCapturePauseCapture>(_onPause);
    on<FrameCaptureResumeCapture>(_onResume);
    on<FrameCaptureManualCapture>(_onManual);
    on<FrameCaptureFrameReceived>(_onFrameReceived);
    on<FrameCaptureQueueUpdated>(_onQueueUpdated);
    on<FrameCaptureClearQueue>(_onClearQueue);

    _queueSub = _repository.watchQueue().listen((snapshot) {
      add(FrameCaptureQueueUpdated(snapshot));
    });
    _frameSub = _repository.watchCapturedFrames().listen((frame) {
      add(FrameCaptureFrameReceived(frame));
    });
  }

  Future<void> _onStart(
    FrameCaptureStartCapture event,
    Emitter<FrameCaptureState> emit,
  ) async {
    final result = await _start(event.params);
    await result.fold(
      onOk: (_) async {
        _sessionId = event.params.sessionId;
        emit(
          FrameCaptureCapturing(
            sessionId: event.params.sessionId,
            queue: _queue,
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'FrameCaptureBloc');
        emit(FrameCaptureError(failure));
      },
    );
  }

  Future<void> _onStop(
    FrameCaptureStopCapture event,
    Emitter<FrameCaptureState> emit,
  ) async {
    final result = await _stop(const NoParams());
    await result.fold(
      onOk: (_) async {
        _sessionId = null;
        emit(FrameCaptureStopped(queue: _queue));
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'FrameCaptureBloc');
        emit(FrameCaptureError(failure));
      },
    );
  }

  Future<void> _onPause(
    FrameCapturePauseCapture event,
    Emitter<FrameCaptureState> emit,
  ) async {
    final result = await _pause(const NoParams());
    await result.fold(
      onOk: (_) async {
        final sid = _sessionId ?? '';
        emit(FrameCapturePaused(sessionId: sid, queue: _queue));
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'FrameCaptureBloc');
        emit(FrameCaptureError(failure));
      },
    );
  }

  Future<void> _onResume(
    FrameCaptureResumeCapture event,
    Emitter<FrameCaptureState> emit,
  ) async {
    final result = await _resume(const NoParams());
    await result.fold(
      onOk: (_) async {
        final sid = _sessionId ?? '';
        emit(FrameCaptureCapturing(sessionId: sid, queue: _queue));
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'FrameCaptureBloc');
        emit(FrameCaptureError(failure));
      },
    );
  }

  Future<void> _onManual(
    FrameCaptureManualCapture event,
    Emitter<FrameCaptureState> emit,
  ) async {
    final result = await _manual(const NoParams());
    await result.fold(
      onOk: (frame) async {
        emit(FrameCaptureFrameCaptured(frame: frame, queue: _queue));
        final sid = _sessionId;
        if (sid != null) {
          emit(FrameCaptureCapturing(
            sessionId: sid,
            queue: _queue,
            lastFrame: frame,
          ));
        }
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'FrameCaptureBloc');
        emit(FrameCaptureError(failure));
      },
    );
  }

  void _onFrameReceived(
    FrameCaptureFrameReceived event,
    Emitter<FrameCaptureState> emit,
  ) {
    emit(FrameCaptureFrameCaptured(frame: event.frame, queue: _queue));
    final sid = _sessionId;
    if (sid == null) return;
    if (state is FrameCapturePaused || _repository.isPaused) {
      emit(FrameCapturePaused(sessionId: sid, queue: _queue));
    } else {
      emit(
        FrameCaptureCapturing(
          sessionId: sid,
          queue: _queue,
          lastFrame: event.frame,
        ),
      );
    }
  }

  void _onQueueUpdated(
    FrameCaptureQueueUpdated event,
    Emitter<FrameCaptureState> emit,
  ) {
    _queue = event.snapshot;
    final sid = _sessionId;
    if (sid == null) {
      if (state is FrameCaptureStopped || state is FrameCaptureInitial) {
        emit(FrameCaptureStopped(queue: _queue));
      }
      return;
    }
    if (_repository.isPaused || state is FrameCapturePaused) {
      emit(FrameCapturePaused(sessionId: sid, queue: _queue));
    } else if (_repository.isCapturing || state is FrameCaptureCapturing) {
      final last = state is FrameCaptureCapturing
          ? (state as FrameCaptureCapturing).lastFrame
          : null;
      emit(
        FrameCaptureCapturing(
          sessionId: sid,
          queue: _queue,
          lastFrame: last,
        ),
      );
    }
  }

  Future<void> _onClearQueue(
    FrameCaptureClearQueue event,
    Emitter<FrameCaptureState> emit,
  ) async {
    final result = await _clearQueue(const NoParams());
    await result.fold(
      onOk: (_) async {
        final sid = _sessionId;
        if (sid != null && _repository.isPaused) {
          emit(FrameCapturePaused(sessionId: sid, queue: _queue));
        } else if (sid != null && _repository.isCapturing) {
          emit(FrameCaptureCapturing(sessionId: sid, queue: _queue));
        } else {
          emit(FrameCaptureStopped(queue: _queue));
        }
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'FrameCaptureBloc');
        emit(FrameCaptureError(failure));
      },
    );
  }

  @override
  Future<void> close() async {
    await _queueSub?.cancel();
    await _frameSub?.cancel();
    return super.close();
  }
}
