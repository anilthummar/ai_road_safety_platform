import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/repositories/risk_analysis_repository.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/usecases/risk_analysis_usecases.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/bloc/risk_analysis_event.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/bloc/risk_analysis_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'risk_analysis_event.dart';
export 'risk_analysis_state.dart';

/// Orchestrates rule-engine monitoring and one-shot evaluations.
class RiskAnalysisBloc extends Bloc<RiskAnalysisEvent, RiskAnalysisState> {
  final EvaluateRiskUseCase _evaluateRisk;
  final StartRiskMonitoringUseCase _startMonitoring;
  final StopRiskMonitoringUseCase _stopMonitoring;
  final DisposeRiskAnalysisUseCase _disposeRisk;
  final RiskAnalysisRepository _repository;
  final AppLogger _logger;

  StreamSubscription<RiskSession>? _sessionSub;
  StreamSubscription<RiskAssessment>? _assessmentSub;

  /// Creates [RiskAnalysisBloc].
  RiskAnalysisBloc({
    required EvaluateRiskUseCase evaluateRisk,
    required StartRiskMonitoringUseCase startMonitoring,
    required StopRiskMonitoringUseCase stopMonitoring,
    required DisposeRiskAnalysisUseCase disposeRisk,
    required RiskAnalysisRepository repository,
    required AppLogger logger,
  })  : _evaluateRisk = evaluateRisk,
        _startMonitoring = startMonitoring,
        _stopMonitoring = stopMonitoring,
        _disposeRisk = disposeRisk,
        _repository = repository,
        _logger = logger,
        super(const RiskAnalysisInitial()) {
    on<RiskAnalysisStarted>(_onStarted);
    on<RiskMonitoringStarted>(_onMonitoringStarted);
    on<RiskMonitoringStopped>(_onMonitoringStopped);
    on<RiskEvaluateRequested>(_onEvaluate);
    on<RiskAnalysisDisposed>(_onDisposed);
    on<RiskSessionUpdated>(_onSessionUpdated);
    on<RiskAssessmentUpdated>(_onAssessmentUpdated);
  }

  Future<void> _onStarted(
    RiskAnalysisStarted event,
    Emitter<RiskAnalysisState> emit,
  ) async {
    await _bindStreams();
    emit(const RiskAnalysisActive(session: RiskSession.idle()));
  }

  Future<void> _onMonitoringStarted(
    RiskMonitoringStarted event,
    Emitter<RiskAnalysisState> emit,
  ) async {
    emit(const RiskAnalysisLoading(message: 'Starting risk monitoring…'));
    await _bindStreams();
    final result = await _startMonitoring(const NoParams());
    await result.fold(
      onOk: (session) async {
        emit(RiskAnalysisActive(session: session));
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'RiskAnalysisBloc');
        emit(RiskAnalysisError(failure));
      },
    );
  }

  Future<void> _onMonitoringStopped(
    RiskMonitoringStopped event,
    Emitter<RiskAnalysisState> emit,
  ) async {
    final result = await _stopMonitoring(const NoParams());
    await result.fold(
      onOk: (session) async {
        final current = state;
        final assessment =
            current is RiskAnalysisActive ? current.assessment : null;
        emit(
          RiskAnalysisActive(
            session: session.copyWith(latestAssessment: assessment),
            assessment: assessment,
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'RiskAnalysisBloc');
        emit(RiskAnalysisError(failure));
      },
    );
  }

  Future<void> _onEvaluate(
    RiskEvaluateRequested event,
    Emitter<RiskAnalysisState> emit,
  ) async {
    final result = await _evaluateRisk(event.snapshot);
    await result.fold(
      onOk: (assessment) async {
        final current = state;
        final monitoring = current is RiskAnalysisActive &&
            current.session.isMonitoring;
        emit(
          RiskAnalysisActive(
            session: RiskSession(
              isMonitoring: monitoring,
              latestAssessment: assessment,
            ),
            assessment: assessment,
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'RiskAnalysisBloc');
        emit(RiskAnalysisError(failure));
      },
    );
  }

  Future<void> _onDisposed(
    RiskAnalysisDisposed event,
    Emitter<RiskAnalysisState> emit,
  ) async {
    await _unbindStreams();
    await _disposeRisk(const NoParams());
    emit(const RiskAnalysisInitial());
  }

  void _onSessionUpdated(
    RiskSessionUpdated event,
    Emitter<RiskAnalysisState> emit,
  ) {
    final current = state;
    if (current is RiskAnalysisActive) {
      emit(
        current.copyWith(
          session: event.session,
          assessment: event.session.latestAssessment ?? current.assessment,
        ),
      );
    } else if (current is! RiskAnalysisError) {
      emit(
        RiskAnalysisActive(
          session: event.session,
          assessment: event.session.latestAssessment,
        ),
      );
    }
  }

  void _onAssessmentUpdated(
    RiskAssessmentUpdated event,
    Emitter<RiskAnalysisState> emit,
  ) {
    final current = state;
    if (current is RiskAnalysisActive) {
      emit(
        current.copyWith(
          assessment: event.assessment,
          session: current.session.copyWith(
            latestAssessment: event.assessment,
          ),
        ),
      );
    } else if (current is! RiskAnalysisError) {
      emit(
        RiskAnalysisActive(
          session: RiskSession(
            isMonitoring: false,
            latestAssessment: event.assessment,
          ),
          assessment: event.assessment,
        ),
      );
    }
  }

  Future<void> _bindStreams() async {
    await _unbindStreams();
    _sessionSub = _repository.watchSession().listen(
      (session) => add(RiskSessionUpdated(session)),
      onError: (Object error, StackTrace stack) {
        _logger.warning(
          '$error',
          tag: 'RiskAnalysisBloc',
          error: error,
          stackTrace: stack,
        );
      },
    );
    _assessmentSub = _repository.watchAssessments().listen(
      (assessment) => add(RiskAssessmentUpdated(assessment)),
      onError: (Object error, StackTrace stack) {
        _logger.warning(
          '$error',
          tag: 'RiskAnalysisBloc',
          error: error,
          stackTrace: stack,
        );
      },
    );
  }

  Future<void> _unbindStreams() async {
    await _sessionSub?.cancel();
    await _assessmentSub?.cancel();
    _sessionSub = null;
    _assessmentSub = null;
  }

  @override
  Future<void> close() async {
    await _unbindStreams();
    await _disposeRisk(const NoParams());
    return super.close();
  }
}
