import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/repositories/driver_dashboard_repository.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/usecases/driver_dashboard_usecases.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/bloc/driver_dashboard_event.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/bloc/driver_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'driver_dashboard_event.dart';
export 'driver_dashboard_state.dart';

/// Orchestrates the fused driver HUD.
class DriverDashboardBloc
    extends Bloc<DriverDashboardEvent, DriverDashboardState> {
  final StartDriverDashboardUseCase _startLive;
  final StopDriverDashboardUseCase _stopLive;
  final DisposeDriverDashboardUseCase _disposeDashboard;
  final DriverDashboardRepository _repository;
  final AppLogger _logger;

  StreamSubscription<DriverDashboardHud>? _hudSub;

  /// Creates [DriverDashboardBloc].
  DriverDashboardBloc({
    required StartDriverDashboardUseCase startLive,
    required StopDriverDashboardUseCase stopLive,
    required DisposeDriverDashboardUseCase disposeDashboard,
    required DriverDashboardRepository repository,
    required AppLogger logger,
  })  : _startLive = startLive,
        _stopLive = stopLive,
        _disposeDashboard = disposeDashboard,
        _repository = repository,
        _logger = logger,
        super(const DriverDashboardInitial()) {
    on<DriverDashboardStarted>(_onStarted);
    on<DriverDashboardStopped>(_onStopped);
    on<DriverDashboardDisposed>(_onDisposed);
    on<DriverDashboardHudUpdated>(_onHudUpdated);
  }

  Future<void> _onStarted(
    DriverDashboardStarted event,
    Emitter<DriverDashboardState> emit,
  ) async {
    emit(const DriverDashboardLoading());
    await _bindHud();
    final result = await _startLive(const NoParams());
    await result.fold(
      onOk: (_) async {
        emit(DriverDashboardActive(hud: DriverDashboardHud.idle()));
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DriverDashboardBloc');
        emit(DriverDashboardError(failure));
      },
    );
  }

  Future<void> _onStopped(
    DriverDashboardStopped event,
    Emitter<DriverDashboardState> emit,
  ) async {
    final result = await _stopLive(const NoParams());
    await result.fold(
      onOk: (_) async {
        final current = state;
        final hud = current is DriverDashboardActive
            ? current.hud.copyWith(isLive: false)
            : DriverDashboardHud.idle();
        emit(DriverDashboardActive(hud: hud));
      },
      onErr: (failure) async {
        emit(DriverDashboardError(failure));
      },
    );
  }

  Future<void> _onDisposed(
    DriverDashboardDisposed event,
    Emitter<DriverDashboardState> emit,
  ) async {
    await _hudSub?.cancel();
    _hudSub = null;
    await _disposeDashboard(const NoParams());
    emit(const DriverDashboardInitial());
  }

  void _onHudUpdated(
    DriverDashboardHudUpdated event,
    Emitter<DriverDashboardState> emit,
  ) {
    final current = state;
    if (current is DriverDashboardActive &&
        _sameHudContent(current.hud, event.hud)) {
      return;
    }
    emit(DriverDashboardActive(hud: event.hud));
  }

  bool _sameHudContent(DriverDashboardHud a, DriverDashboardHud b) {
    return a.floodCoveragePercent == b.floodCoveragePercent &&
        a.hasFloodSample == b.hasFloodSample &&
        a.riskLevel == b.riskLevel &&
        a.riskScore == b.riskScore &&
        a.hasRiskAssessment == b.hasRiskAssessment &&
        a.speedKmh == b.speedKmh &&
        a.hasGpsFix == b.hasGpsFix &&
        a.latitude == b.latitude &&
        a.longitude == b.longitude &&
        a.gpsAccuracyMeters == b.gpsAccuracyMeters &&
        a.isLive == b.isLive &&
        a.warnings == b.warnings;
  }

  Future<void> _bindHud() async {
    await _hudSub?.cancel();
    _hudSub = _repository.watchHud().listen(
      (hud) => add(DriverDashboardHudUpdated(hud)),
      onError: (Object error, StackTrace stack) {
        _logger.warning(
          '$error',
          tag: 'DriverDashboardBloc',
          error: error,
          stackTrace: stack,
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _hudSub?.cancel();
    await _disposeDashboard(const NoParams());
    return super.close();
  }
}
