import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_quality_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_quality_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_quality_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dataset_quality_event.dart';
export 'dataset_quality_state.dart';

/// Training-gate quality assessment orchestration (Phase 13.1).
class DatasetQualityBloc
    extends Bloc<DatasetQualityEvent, DatasetQualityState> {
  final AssessDatasetQualityUseCase _assess;
  final LoadLastQualityReportUseCase _loadLast;
  final GetQualityThresholdsUseCase _getThresholds;
  final UpdateQualityThresholdsUseCase _updateThresholds;
  final EvaluateQualityGateUseCase _evaluateGate;
  final AppLogger _logger;

  QualityGateThresholds _thresholds = QualityGateThresholds.defaults;

  DatasetQualityBloc({
    required AssessDatasetQualityUseCase assessDatasetQuality,
    required LoadLastQualityReportUseCase loadLastQualityReport,
    required GetQualityThresholdsUseCase getQualityThresholds,
    required UpdateQualityThresholdsUseCase updateQualityThresholds,
    required EvaluateQualityGateUseCase evaluateQualityGate,
    required AppLogger logger,
  })  : _assess = assessDatasetQuality,
        _loadLast = loadLastQualityReport,
        _getThresholds = getQualityThresholds,
        _updateThresholds = updateQualityThresholds,
        _evaluateGate = evaluateQualityGate,
        _logger = logger,
        super(const DatasetQualityInitial()) {
    on<DatasetQualityLoad>(_onLoad);
    on<DatasetQualityAssess>(_onAssess);
    on<DatasetQualityRefresh>(_onRefresh);
    on<DatasetQualityUpdateThresholds>(_onUpdateThresholds);
    on<DatasetQualityEvaluateGate>(_onEvaluateGate);
  }

  QualityGateThresholds get thresholds => _thresholds;

  Future<void> _onLoad(
    DatasetQualityLoad event,
    Emitter<DatasetQualityState> emit,
  ) async {
    emit(const DatasetQualityLoading(message: 'Loading quality gate…'));
    final t = await _getThresholds(const NoParams());
    _thresholds = t.fold(
      onOk: (v) => v,
      onErr: (_) => QualityGateThresholds.defaults,
    );
    final last = await _loadLast(const NoParams());
    await last.fold(
      onOk: (report) async {
        if (report == null) {
          emit(DatasetQualityEmpty(thresholds: _thresholds));
          return;
        }
        emit(DatasetQualityLoaded(report: report, thresholds: _thresholds));
      },
      onErr: (f) async => emit(
        DatasetQualityError(failure: f, thresholds: _thresholds),
      ),
    );
  }

  Future<void> _onAssess(
    DatasetQualityAssess event,
    Emitter<DatasetQualityState> emit,
  ) async {
    emit(const DatasetQualityLoading());
    final result = await _assess(
      AssessDatasetParams(
        thresholds: _thresholds,
        sessionId: event.sessionId,
      ),
    );
    await result.fold(
      onOk: (report) async {
        _logger.info(
          'Gate ${report.decision.name} score=${report.overallScore}',
          tag: 'DatasetQualityBloc',
        );
        if (report.totalSessions == 0) {
          emit(
            DatasetQualityEmpty(
              thresholds: _thresholds,
              message: report.gateSummary,
            ),
          );
          return;
        }
        emit(DatasetQualityLoaded(report: report, thresholds: _thresholds));
      },
      onErr: (f) async => emit(
        DatasetQualityError(failure: f, thresholds: _thresholds),
      ),
    );
  }

  Future<void> _onRefresh(
    DatasetQualityRefresh event,
    Emitter<DatasetQualityState> emit,
  ) =>
      _onAssess(const DatasetQualityAssess(), emit);

  Future<void> _onUpdateThresholds(
    DatasetQualityUpdateThresholds event,
    Emitter<DatasetQualityState> emit,
  ) async {
    final result = await _updateThresholds(event.thresholds);
    await result.fold(
      onOk: (t) async {
        _thresholds = t;
        final current = state;
        if (current is DatasetQualityLoaded) {
          emit(
            DatasetQualityLoaded(report: current.report, thresholds: t),
          );
        } else if (current is DatasetQualityEmpty) {
          emit(DatasetQualityEmpty(thresholds: t, message: current.message));
        }
      },
      onErr: (f) async => emit(
        DatasetQualityError(failure: f, thresholds: _thresholds),
      ),
    );
  }

  Future<void> _onEvaluateGate(
    DatasetQualityEvaluateGate event,
    Emitter<DatasetQualityState> emit,
  ) async {
    final current = state;
    if (current is! DatasetQualityLoaded) return;
    final result = await _evaluateGate(
      EvaluateQualityGateParams(
        report: current.report,
        thresholds: _thresholds,
      ),
    );
    result.fold(
      onOk: (decision) {
        _logger.info('Gate re-eval ${decision.name}', tag: 'DatasetQualityBloc');
        // Re-assess so scores/issues align with new thresholds.
        add(const DatasetQualityAssess());
      },
      onErr: (f) => emit(
        DatasetQualityError(
          failure: f,
          thresholds: _thresholds,
          report: current.report,
        ),
      ),
    );
  }
}
