import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/usecases/imu_usecases.dart';
import 'package:ai_road_safety_platform/features/imu/presentation/bloc/imu_event.dart';
import 'package:ai_road_safety_platform/features/imu/presentation/bloc/imu_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'imu_event.dart';
export 'imu_state.dart';

/// Orchestrates IMU streaming, calibration, and fused sample updates.
class ImuBloc extends Bloc<ImuEvent, ImuState> {
  final StartImuStreamingUseCase _startStreaming;
  final StopImuStreamingUseCase _stopStreaming;
  final CalibrateImuUseCase _calibrate;
  final DisposeImuUseCase _disposeImu;
  final ImuRepository _repository;
  final AppLogger _logger;

  StreamSubscription<ImuSession>? _sessionSub;
  StreamSubscription<ImuSample>? _sampleSub;

  /// Creates [ImuBloc].
  ImuBloc({
    required StartImuStreamingUseCase startStreaming,
    required StopImuStreamingUseCase stopStreaming,
    required CalibrateImuUseCase calibrate,
    required DisposeImuUseCase disposeImu,
    required ImuRepository repository,
    required AppLogger logger,
  })  : _startStreaming = startStreaming,
        _stopStreaming = stopStreaming,
        _calibrate = calibrate,
        _disposeImu = disposeImu,
        _repository = repository,
        _logger = logger,
        super(const ImuInitial()) {
    on<ImuStarted>(_onStarted);
    on<ImuStreamingStarted>(_onStreamingStarted);
    on<ImuStreamingStopped>(_onStreamingStopped);
    on<ImuCalibrationRequested>(_onCalibrationRequested);
    on<ImuDisposed>(_onDisposed);
    on<ImuSessionUpdated>(_onSessionUpdated);
    on<ImuSampleUpdated>(_onSampleUpdated);
  }

  Future<void> _onStarted(
    ImuStarted event,
    Emitter<ImuState> emit,
  ) async {
    emit(const ImuLoading(message: 'Starting IMU sensors…'));
    await _bindStreams();
    final result = await _startStreaming(const NoParams());
    await result.fold(
      onOk: (_) async {
        emit(
          ImuActive(
            session: const ImuSession.idle().copyWith(isStreaming: true),
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'ImuBloc');
        emit(ImuError(failure));
      },
    );
  }

  Future<void> _onStreamingStarted(
    ImuStreamingStarted event,
    Emitter<ImuState> emit,
  ) async {
    emit(const ImuLoading(message: 'Starting IMU sensors…'));
    await _bindStreams();
    final result = await _startStreaming(const NoParams());
    await result.fold(
      onOk: (_) async {
        final current = state;
        final sample = current is ImuActive ? current.sample : null;
        emit(
          ImuActive(
            session: (current is ImuActive
                    ? current.session
                    : const ImuSession.idle())
                .copyWith(isStreaming: true),
            sample: sample,
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'ImuBloc');
        emit(ImuError(failure));
      },
    );
  }

  Future<void> _onStreamingStopped(
    ImuStreamingStopped event,
    Emitter<ImuState> emit,
  ) async {
    final result = await _stopStreaming(const NoParams());
    await result.fold(
      onOk: (_) async {
        final current = state;
        if (current is ImuActive) {
          emit(
            current.copyWith(
              session: current.session.copyWith(
                isStreaming: false,
                isCalibrating: false,
                calibrationProgress: 0,
              ),
            ),
          );
        } else {
          emit(const ImuActive(session: ImuSession.idle()));
        }
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'ImuBloc');
        emit(ImuError(failure));
      },
    );
  }

  Future<void> _onCalibrationRequested(
    ImuCalibrationRequested event,
    Emitter<ImuState> emit,
  ) async {
    final result = await _calibrate(const NoParams());
    await result.fold(
      onOk: (calibration) async {
        _logger.info(
          'IMU calibrated (${calibration.samplesUsed} samples)',
          tag: 'ImuBloc',
        );
        final current = state;
        if (current is ImuActive) {
          emit(
            current.copyWith(
              session: current.session.copyWith(
                isCalibrating: false,
                calibrationProgress: 1,
                calibration: calibration,
              ),
            ),
          );
        }
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'ImuBloc');
        emit(ImuError(failure));
      },
    );
  }

  Future<void> _onDisposed(
    ImuDisposed event,
    Emitter<ImuState> emit,
  ) async {
    await _unbindStreams();
    await _disposeImu(const NoParams());
    emit(const ImuInitial());
  }

  void _onSessionUpdated(
    ImuSessionUpdated event,
    Emitter<ImuState> emit,
  ) {
    final current = state;
    if (current is ImuActive) {
      emit(
        current.copyWith(
          session: event.session,
          sample: event.session.latestSample ?? current.sample,
        ),
      );
    } else if (current is! ImuError) {
      emit(
        ImuActive(
          session: event.session,
          sample: event.session.latestSample,
        ),
      );
    }
  }

  void _onSampleUpdated(
    ImuSampleUpdated event,
    Emitter<ImuState> emit,
  ) {
    final current = state;
    if (current is ImuActive) {
      emit(current.copyWith(sample: event.sample));
    } else if (current is! ImuError) {
      emit(
        ImuActive(
          session: const ImuSession.idle().copyWith(isStreaming: true),
          sample: event.sample,
        ),
      );
    }
  }

  Future<void> _bindStreams() async {
    await _unbindStreams();
    _sessionSub = _repository.sessionStream.listen(
      (session) => add(ImuSessionUpdated(session)),
      onError: (Object error, StackTrace stack) {
        _logger.warning('$error', tag: 'ImuBloc', error: error, stackTrace: stack);
      },
    );
    _sampleSub = _repository.sampleStream.listen(
      (sample) => add(ImuSampleUpdated(sample)),
      onError: (Object error, StackTrace stack) {
        _logger.warning('$error', tag: 'ImuBloc', error: error, stackTrace: stack);
      },
    );
  }

  Future<void> _unbindStreams() async {
    await _sessionSub?.cancel();
    await _sampleSub?.cancel();
    _sessionSub = null;
    _sampleSub = null;
  }

  @override
  Future<void> close() async {
    await _unbindStreams();
    await _disposeImu(const NoParams());
    return super.close();
  }
}
