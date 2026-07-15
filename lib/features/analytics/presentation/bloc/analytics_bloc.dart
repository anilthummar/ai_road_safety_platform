import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/usecases/analytics_usecases.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'analytics_event.dart';
export 'analytics_state.dart';

/// Loads and watches analytics reports for weekly / monthly / yearly views.
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetAnalyticsReportUseCase _getReport;
  final AnalyticsRepository _repository;
  final AppLogger _logger;

  StreamSubscription<AnalyticsReport>? _watchSub;
  AnalyticsPeriod _period = AnalyticsPeriod.weekly;

  /// Creates [AnalyticsBloc].
  AnalyticsBloc({
    required GetAnalyticsReportUseCase getReport,
    required AnalyticsRepository repository,
    required AppLogger logger,
  })  : _getReport = getReport,
        _repository = repository,
        _logger = logger,
        super(const AnalyticsInitial()) {
    on<AnalyticsStarted>(_onStarted);
    on<AnalyticsPeriodChanged>(_onPeriodChanged);
    on<AnalyticsRefreshed>(_onRefreshed);
    on<AnalyticsReportUpdated>(_onReportUpdated);
  }

  Future<void> _onStarted(
    AnalyticsStarted event,
    Emitter<AnalyticsState> emit,
  ) async {
    _period = AnalyticsPeriod.weekly;
    await _loadAndWatch(emit);
  }

  Future<void> _onPeriodChanged(
    AnalyticsPeriodChanged event,
    Emitter<AnalyticsState> emit,
  ) async {
    _period = event.period;
    await _loadAndWatch(emit);
  }

  Future<void> _onRefreshed(
    AnalyticsRefreshed event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadAndWatch(emit);
  }

  void _onReportUpdated(
    AnalyticsReportUpdated event,
    Emitter<AnalyticsState> emit,
  ) {
    emit(AnalyticsLoaded(period: _period, report: event.report));
  }

  Future<void> _loadAndWatch(Emitter<AnalyticsState> emit) async {
    emit(const AnalyticsLoading());
    await _watchSub?.cancel();

    final result = await _getReport(_period);
    await result.fold(
      onOk: (report) async {
        emit(AnalyticsLoaded(period: _period, report: report));
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'AnalyticsBloc');
        emit(AnalyticsError(failure));
      },
    );

    _watchSub = _repository.watchReport(_period).listen(
      (report) => add(AnalyticsReportUpdated(report)),
      onError: (Object e, StackTrace st) {
        _logger.warning('$e', tag: 'AnalyticsBloc', error: e, stackTrace: st);
      },
    );
  }

  @override
  Future<void> close() async {
    await _watchSub?.cancel();
    return super.close();
  }
}
