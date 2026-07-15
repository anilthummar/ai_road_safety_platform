import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_analytics_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_analytics_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dataset_analytics_event.dart';
export 'dataset_analytics_state.dart';

/// Orchestrates research analytics loading & filtering (Phase 12.7).
class DatasetAnalyticsBloc
    extends Bloc<DatasetAnalyticsEvent, DatasetAnalyticsState> {
  final LoadAnalyticsUseCase _loadAnalytics;
  final AppLogger _logger;

  AnalyticsFilter _filter = const AnalyticsFilter();

  /// Creates [DatasetAnalyticsBloc].
  DatasetAnalyticsBloc({
    required LoadAnalyticsUseCase loadAnalytics,
    required AppLogger logger,
  })  : _loadAnalytics = loadAnalytics,
        _logger = logger,
        super(const DatasetAnalyticsInitial()) {
    on<DatasetAnalyticsLoad>(_onLoad);
    on<DatasetAnalyticsRefresh>(_onRefresh);
    on<DatasetAnalyticsLoadResearchInsights>(_onSectionReload);
    on<DatasetAnalyticsLoadStorage>(_onSectionReload);
    on<DatasetAnalyticsLoadSession>(_onSectionReload);
    on<DatasetAnalyticsLoadLocation>(_onSectionReload);
    on<DatasetAnalyticsLoadInference>(_onSectionReload);
    on<DatasetAnalyticsFilter>(_onFilter);
  }

  /// Current filter for UI.
  AnalyticsFilter get currentFilter => _filter;

  Future<void> _onLoad(
    DatasetAnalyticsLoad event,
    Emitter<DatasetAnalyticsState> emit,
  ) async {
    if (event.filter != null) {
      _filter = event.filter!;
    }
    await _emitReport(emit);
  }

  Future<void> _onRefresh(
    DatasetAnalyticsRefresh event,
    Emitter<DatasetAnalyticsState> emit,
  ) async {
    await _emitReport(emit);
  }

  Future<void> _onSectionReload(
    DatasetAnalyticsEvent event,
    Emitter<DatasetAnalyticsState> emit,
  ) async {
    await _emitReport(emit);
  }

  Future<void> _onFilter(
    DatasetAnalyticsFilter event,
    Emitter<DatasetAnalyticsState> emit,
  ) async {
    _filter = event.filter;
    _logger.info(
      'Filters Applied date=${_filter.dateFilter} '
      'status=${_filter.status} q="${_filter.searchQuery}"',
      tag: 'DatasetAnalyticsBloc',
    );
    await _emitReport(emit);
  }

  Future<void> _emitReport(Emitter<DatasetAnalyticsState> emit) async {
    emit(const DatasetAnalyticsLoading());
    final result = await _loadAnalytics(AnalyticsFilterParams(_filter));
    result.fold(
      onOk: (report) {
        if (report.isEmpty) {
          emit(DatasetAnalyticsEmpty(filter: _filter));
          return;
        }
        _logger.info(
          'Charts Rendered growth=${report.overview.datasetGrowth.length} '
          'timeline=${report.sessions.sessionTimeline.length}',
          tag: 'DatasetAnalyticsBloc',
        );
        emit(DatasetAnalyticsLoaded(report));
      },
      onErr: (failure) {
        _logger.warning(failure.message, tag: 'DatasetAnalyticsBloc');
        emit(DatasetAnalyticsError(failure));
      },
    );
  }
}
