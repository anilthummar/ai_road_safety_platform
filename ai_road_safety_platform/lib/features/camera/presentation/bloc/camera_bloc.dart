import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/camera/domain/usecases/camera_usecases.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_event.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'camera_event.dart';
export 'camera_state.dart';

/// Orchestrates camera permission, lifecycle, preview session, and frame stream.
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CheckCameraPermissionUseCase _checkPermission;
  final RequestCameraPermissionUseCase _requestPermission;
  final OpenCameraPermissionSettingsUseCase _openSettings;
  final InitializeCameraUseCase _initializeCamera;
  final PauseCameraUseCase _pauseCamera;
  final ResumeCameraUseCase _resumeCamera;
  final StartFrameStreamingUseCase _startStreaming;
  final StopFrameStreamingUseCase _stopStreaming;
  final DisposeCameraUseCase _disposeCamera;
  final HandleCameraOrientationUseCase _handleOrientation;
  final CameraRepository _repository;
  final AppLogger _logger;

  StreamSubscription<CameraSession>? _sessionSub;

  /// Creates [CameraBloc].
  CameraBloc({
    required CheckCameraPermissionUseCase checkPermission,
    required RequestCameraPermissionUseCase requestPermission,
    required OpenCameraPermissionSettingsUseCase openSettings,
    required InitializeCameraUseCase initializeCamera,
    required PauseCameraUseCase pauseCamera,
    required ResumeCameraUseCase resumeCamera,
    required StartFrameStreamingUseCase startStreaming,
    required StopFrameStreamingUseCase stopStreaming,
    required DisposeCameraUseCase disposeCamera,
    required HandleCameraOrientationUseCase handleOrientation,
    required CameraRepository repository,
    required AppLogger logger,
  })  : _checkPermission = checkPermission,
        _requestPermission = requestPermission,
        _openSettings = openSettings,
        _initializeCamera = initializeCamera,
        _pauseCamera = pauseCamera,
        _resumeCamera = resumeCamera,
        _startStreaming = startStreaming,
        _stopStreaming = stopStreaming,
        _disposeCamera = disposeCamera,
        _handleOrientation = handleOrientation,
        _repository = repository,
        _logger = logger,
        super(const CameraInitial()) {
    on<CameraStarted>(_onStarted);
    on<CameraPermissionRequested>(_onPermissionRequested);
    on<CameraOpenSettingsRequested>(_onOpenSettings);
    on<CameraPaused>(_onPaused);
    on<CameraResumed>(_onResumed);
    on<CameraFrameStreamingStarted>(_onStreamingStarted);
    on<CameraFrameStreamingStopped>(_onStreamingStopped);
    on<CameraOrientationChanged>(_onOrientationChanged);
    on<CameraDisposed>(_onDisposed);
    on<CameraSessionUpdated>(_onSessionUpdated);
  }

  /// Frame metadata stream for HUD / future AI — bypasses Bloc rebuilds.
  Stream<CameraFrameMeta> get frameStream => _repository.watchFrames();

  Future<void> _onStarted(
    CameraStarted event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraLoading(message: 'Checking camera permission…'));

    final permissionResult = await _checkPermission(const NoParams());
    final permission = permissionResult.fold(
      onOk: (status) => status,
      onErr: (failure) {
        emit(CameraError(failure));
        return null;
      },
    );
    if (permission == null) return;

    if (permission == CameraPermissionStatus.denied) {
      emit(const CameraLoading(message: 'Requesting camera permission…'));
      final requested = await _requestPermission(const NoParams());
      final next = requested.fold(
        onOk: (status) => status,
        onErr: (failure) {
          emit(CameraError(failure));
          return null;
        },
      );
      if (next == null) return;
      if (!_isPermissionUsable(next)) {
        emit(
          CameraPermissionDenied(
            isPermanentlyDenied:
                next == CameraPermissionStatus.permanentlyDenied,
          ),
        );
        return;
      }
    } else if (!_isPermissionUsable(permission)) {
      emit(
        CameraPermissionDenied(
          isPermanentlyDenied:
              permission == CameraPermissionStatus.permanentlyDenied,
        ),
      );
      return;
    }

    emit(const CameraLoading(message: 'Starting rear camera…'));
    final initResult = await _initializeCamera(
      InitializeCameraParams(lens: event.lens),
    );

    await initResult.fold(
      onOk: (session) async {
        await _bindSessionStream();
        emit(CameraReady(session: session));
        add(const CameraFrameStreamingStarted());
      },
      onErr: (failure) async {
        if (failure is PermissionFailure) {
          emit(
            CameraPermissionDenied(
              isPermanentlyDenied: true,
              message: failure.message,
            ),
          );
        } else {
          emit(CameraError(failure));
        }
      },
    );
  }

  Future<void> _onPermissionRequested(
    CameraPermissionRequested event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraLoading(message: 'Requesting camera permission…'));
    final result = await _requestPermission(const NoParams());
    await result.fold(
      onOk: (status) async {
        if (_isPermissionUsable(status)) {
          add(const CameraStarted());
        } else {
          emit(
            CameraPermissionDenied(
              isPermanentlyDenied:
                  status == CameraPermissionStatus.permanentlyDenied,
            ),
          );
        }
      },
      onErr: (failure) async => emit(CameraError(failure)),
    );
  }

  Future<void> _onOpenSettings(
    CameraOpenSettingsRequested event,
    Emitter<CameraState> emit,
  ) async {
    await _openSettings(const NoParams());
  }

  Future<void> _onPaused(
    CameraPaused event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final result = await _pauseCamera(const NoParams());
    result.fold(
      onOk: (session) => emit(CameraReady(session: session)),
      onErr: (failure) => _logger.warning(
        'Pause failed: ${failure.message}',
        tag: 'CameraBloc',
      ),
    );
  }

  Future<void> _onResumed(
    CameraResumed event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraPermissionDenied || state is CameraError) {
      add(const CameraStarted());
      return;
    }
    if (state is! CameraReady) return;

    final result = await _resumeCamera(const NoParams());
    await result.fold(
      onOk: (session) async {
        emit(CameraReady(session: session));
        add(const CameraFrameStreamingStarted());
      },
      onErr: (failure) async => emit(CameraError(failure)),
    );
  }

  Future<void> _onStreamingStarted(
    CameraFrameStreamingStarted event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    if (current.isPaused) return;

    final result = await _startStreaming(
      StartFrameStreamingParams(targetFps: event.targetFps),
    );
    result.fold(
      onOk: (session) => emit(current.copyWith(session: session)),
      onErr: (failure) => _logger.warning(
        'Streaming start failed: ${failure.message}',
        tag: 'CameraBloc',
      ),
    );
  }

  Future<void> _onStreamingStopped(
    CameraFrameStreamingStopped event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    final result = await _stopStreaming(const NoParams());
    result.fold(
      onOk: (session) => emit(current.copyWith(session: session)),
      onErr: (failure) => _logger.warning(
        'Streaming stop failed: ${failure.message}',
        tag: 'CameraBloc',
      ),
    );
  }

  Future<void> _onOrientationChanged(
    CameraOrientationChanged event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    final result = await _handleOrientation(
      CameraOrientationParams(event.degrees),
    );
    result.fold(
      onOk: (session) => emit(current.copyWith(session: session)),
      onErr: (_) {},
    );
  }

  Future<void> _onDisposed(
    CameraDisposed event,
    Emitter<CameraState> emit,
  ) async {
    await _unbindSessionStream();
    await _disposeCamera(const NoParams());
    emit(const CameraInitial());
  }

  void _onSessionUpdated(
    CameraSessionUpdated event,
    Emitter<CameraState> emit,
  ) {
    final current = state;
    if (current is CameraReady) {
      emit(current.copyWith(session: event.session));
    }
  }

  Future<void> _bindSessionStream() async {
    await _unbindSessionStream();
    _sessionSub = _repository.watchSession().listen(
      (session) => add(CameraSessionUpdated(session)),
    );
  }

  Future<void> _unbindSessionStream() async {
    await _sessionSub?.cancel();
    _sessionSub = null;
  }

  bool _isPermissionUsable(CameraPermissionStatus status) {
    return status == CameraPermissionStatus.granted ||
        status == CameraPermissionStatus.limited;
  }

  @override
  Future<void> close() async {
    await _unbindSessionStream();
    await _disposeCamera(const NoParams());
    return super.close();
  }
}
