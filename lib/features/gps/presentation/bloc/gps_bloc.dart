import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/gps/domain/usecases/gps_usecases.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/bloc/gps_event.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/bloc/gps_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'gps_event.dart';
export 'gps_state.dart';

/// Orchestrates GPS permission, one-shot fixes, and continuous tracking.
class GpsBloc extends Bloc<GpsEvent, GpsState> {
  final CheckGpsPermissionUseCase _checkPermission;
  final RequestGpsPermissionUseCase _requestPermission;
  final OpenGpsSettingsUseCase _openSettings;
  final OpenGpsLocationSettingsUseCase _openLocationSettings;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final StartGpsTrackingUseCase _startTracking;
  final StopGpsTrackingUseCase _stopTracking;
  final DisposeGpsUseCase _disposeGps;
  final GpsRepository _repository;
  final AppLogger _logger;

  StreamSubscription<GpsSession>? _sessionSub;
  StreamSubscription<GpsFix>? _fixSub;

  /// Creates [GpsBloc].
  GpsBloc({
    required CheckGpsPermissionUseCase checkPermission,
    required RequestGpsPermissionUseCase requestPermission,
    required OpenGpsSettingsUseCase openSettings,
    required OpenGpsLocationSettingsUseCase openLocationSettings,
    required GetCurrentLocationUseCase getCurrentLocation,
    required StartGpsTrackingUseCase startTracking,
    required StopGpsTrackingUseCase stopTracking,
    required DisposeGpsUseCase disposeGps,
    required GpsRepository repository,
    required AppLogger logger,
  })  : _checkPermission = checkPermission,
        _requestPermission = requestPermission,
        _openSettings = openSettings,
        _openLocationSettings = openLocationSettings,
        _getCurrentLocation = getCurrentLocation,
        _startTracking = startTracking,
        _stopTracking = stopTracking,
        _disposeGps = disposeGps,
        _repository = repository,
        _logger = logger,
        super(const GpsInitial()) {
    on<GpsStarted>(_onStarted);
    on<GpsPermissionRequested>(_onPermissionRequested);
    on<GpsOpenSettingsRequested>(_onOpenSettings);
    on<GpsCurrentLocationRequested>(_onCurrentLocation);
    on<GpsTrackingStarted>(_onTrackingStarted);
    on<GpsTrackingStopped>(_onTrackingStopped);
    on<GpsDisposed>(_onDisposed);
    on<GpsSessionUpdated>(_onSessionUpdated);
    on<GpsFixUpdated>(_onFixUpdated);
  }

  Future<void> _onStarted(
    GpsStarted event,
    Emitter<GpsState> emit,
  ) async {
    emit(const GpsLoading(message: 'Checking location services…'));

    final serviceResult = await _repository.isServiceEnabled();
    final serviceEnabled = serviceResult.fold(
      onOk: (enabled) => enabled,
      onErr: (_) => true, // proceed; getCurrentLocation will surface failure
    );
    if (!serviceEnabled) {
      emit(const GpsServiceDisabled());
      return;
    }

    emit(const GpsLoading(message: 'Checking location permission…'));

    final permissionResult = await _checkPermission(const NoParams());
    final permission = permissionResult.fold(
      onOk: (status) => status,
      onErr: (failure) {
        emit(GpsError(failure));
        return null;
      },
    );
    if (permission == null) return;

    if (permission == GpsPermissionStatus.denied) {
      emit(const GpsLoading(message: 'Requesting location permission…'));
      final requested = await _requestPermission(const NoParams());
      final next = requested.fold(
        onOk: (status) => status,
        onErr: (failure) {
          emit(GpsError(failure));
          return null;
        },
      );
      if (next == null) return;
      if (!_isUsable(next)) {
        emit(
          GpsPermissionDenied(
            isPermanentlyDenied: next == GpsPermissionStatus.permanentlyDenied,
          ),
        );
        return;
      }
    } else if (!_isUsable(permission)) {
      emit(
        GpsPermissionDenied(
          isPermanentlyDenied:
              permission == GpsPermissionStatus.permanentlyDenied ||
                  permission == GpsPermissionStatus.restricted,
        ),
      );
      return;
    }

    await _bindStreams();
    emit(const GpsLoading(message: 'Acquiring GPS fix…'));
    final fixResult = await _getCurrentLocation(const NoParams());
    await fixResult.fold(
      onOk: (fix) async {
        emit(
          GpsActive(
            session: GpsSession(
              isStreaming: false,
              isServiceEnabled: true,
              latestFix: fix,
              fixCount: 1,
            ),
          ),
        );
        add(const GpsTrackingStarted());
      },
      onErr: (failure) async {
        _emitMappedFailure(emit, failure);
      },
    );
  }

  Future<void> _onPermissionRequested(
    GpsPermissionRequested event,
    Emitter<GpsState> emit,
  ) async {
    emit(const GpsLoading(message: 'Requesting location permission…'));
    final result = await _requestPermission(const NoParams());
    await result.fold(
      onOk: (status) async {
        if (_isUsable(status)) {
          add(const GpsStarted());
        } else {
          emit(
            GpsPermissionDenied(
              isPermanentlyDenied:
                  status == GpsPermissionStatus.permanentlyDenied,
            ),
          );
        }
      },
      onErr: (failure) async => emit(GpsError(failure)),
    );
  }

  Future<void> _onOpenSettings(
    GpsOpenSettingsRequested event,
    Emitter<GpsState> emit,
  ) async {
    if (event.locationServices) {
      await _openLocationSettings(const NoParams());
    } else {
      await _openSettings(const NoParams());
    }
  }

  Future<void> _onCurrentLocation(
    GpsCurrentLocationRequested event,
    Emitter<GpsState> emit,
  ) async {
    emit(const GpsLoading(message: 'Refreshing location…'));
    final result = await _getCurrentLocation(const NoParams());
    result.fold(
      onOk: (fix) {
        final current = state;
        final base = current is GpsActive
            ? current.session
            : const GpsSession(isStreaming: false, isServiceEnabled: true);
        emit(
          GpsActive(
            session: base.copyWith(
              latestFix: fix,
              fixCount: base.fixCount + 1,
              isServiceEnabled: true,
            ),
          ),
        );
      },
      onErr: (failure) => _emitMappedFailure(emit, failure),
    );
  }

  Future<void> _onTrackingStarted(
    GpsTrackingStarted event,
    Emitter<GpsState> emit,
  ) async {
    final result = await _startTracking(const NoParams());
    result.fold(
      onOk: (session) {
        final current = state;
        if (current is GpsActive && current.latestFix != null) {
          emit(
            GpsActive(
              session: session.copyWith(latestFix: current.latestFix),
            ),
          );
        } else {
          emit(GpsActive(session: session));
        }
      },
      onErr: (failure) => _emitMappedFailure(emit, failure),
    );
  }

  Future<void> _onTrackingStopped(
    GpsTrackingStopped event,
    Emitter<GpsState> emit,
  ) async {
    final result = await _stopTracking(const NoParams());
    result.fold(
      onOk: (session) {
        final current = state;
        if (current is GpsActive) {
          emit(
            GpsActive(
              session: session.copyWith(latestFix: current.latestFix),
            ),
          );
        }
      },
      onErr: (failure) =>
          _logger.warning(failure.message, tag: 'GpsBloc'),
    );
  }

  Future<void> _onDisposed(
    GpsDisposed event,
    Emitter<GpsState> emit,
  ) async {
    await _unbindStreams();
    await _disposeGps(const NoParams());
    emit(const GpsInitial());
  }

  void _onSessionUpdated(
    GpsSessionUpdated event,
    Emitter<GpsState> emit,
  ) {
    final current = state;
    if (current is GpsActive) {
      emit(current.copyWith(session: event.session));
    } else if (event.session.latestFix != null) {
      emit(GpsActive(session: event.session));
    }
  }

  void _onFixUpdated(
    GpsFixUpdated event,
    Emitter<GpsState> emit,
  ) {
    final current = state;
    if (current is GpsActive) {
      emit(
        current.copyWith(
          session: current.session.copyWith(latestFix: event.fix),
        ),
      );
    }
  }

  void _emitMappedFailure(Emitter<GpsState> emit, Failure failure) {
    if (failure is PermissionFailure) {
      emit(
        GpsPermissionDenied(
          isPermanentlyDenied: failure.message.toLowerCase().contains(
                'permanently',
              ),
          message: failure.message,
        ),
      );
      return;
    }
    if (failure is GpsFailure &&
        failure.message.toLowerCase().contains('disabled')) {
      emit(GpsServiceDisabled(message: failure.message));
      return;
    }
    emit(GpsError(failure));
  }

  Future<void> _bindStreams() async {
    await _unbindStreams();
    _sessionSub = _repository.watchSession().listen(
      (session) => add(GpsSessionUpdated(session)),
    );
    _fixSub = _repository.watchFixes().listen(
      (fix) => add(GpsFixUpdated(fix)),
    );
  }

  Future<void> _unbindStreams() async {
    await _sessionSub?.cancel();
    await _fixSub?.cancel();
    _sessionSub = null;
    _fixSub = null;
  }

  bool _isUsable(GpsPermissionStatus status) {
    return status == GpsPermissionStatus.granted;
  }

  @override
  Future<void> close() async {
    await _unbindStreams();
    await _disposeGps(const NoParams());
    return super.close();
  }
}
