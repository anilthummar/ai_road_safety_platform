import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_benchmark_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_benchmark_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_benchmark_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'model_benchmark_event.dart';
export 'model_benchmark_state.dart';

/// Offline benchmark / eval orchestration (Phase 13.4).
class ModelBenchmarkBloc
    extends Bloc<ModelBenchmarkEvent, ModelBenchmarkState> {
  final LoadBenchmarkSnapshotUseCase _load;
  final RunBenchmarkUseCase _run;
  final DeleteBenchmarkReportUseCase _delete;
  final CreateDemoBenchmarkUseCase _demo;
  final AppLogger _logger;

  ModelBenchmarkBloc({
    required LoadBenchmarkSnapshotUseCase loadBenchmarkSnapshot,
    required RunBenchmarkUseCase runBenchmark,
    required DeleteBenchmarkReportUseCase deleteBenchmarkReport,
    required CreateDemoBenchmarkUseCase createDemoBenchmark,
    required AppLogger logger,
  })  : _load = loadBenchmarkSnapshot,
        _run = runBenchmark,
        _delete = deleteBenchmarkReport,
        _demo = createDemoBenchmark,
        _logger = logger,
        super(const ModelBenchmarkInitial()) {
    on<ModelBenchmarkLoad>(_onLoad);
    on<ModelBenchmarkRefresh>(_onLoad);
    on<ModelBenchmarkRun>(_onRun);
    on<ModelBenchmarkDelete>(_onDelete);
    on<ModelBenchmarkCreateDemo>(_onDemo);
  }

  Future<void> _onLoad(
    ModelBenchmarkEvent event,
    Emitter<ModelBenchmarkState> emit,
  ) async {
    emit(const ModelBenchmarkLoading());
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(ModelBenchmarkLoaded(snapshot: snap)),
      onErr: (f) => emit(ModelBenchmarkError(failure: f)),
    );
  }

  Future<void> _onRun(
    ModelBenchmarkRun event,
    Emitter<ModelBenchmarkState> emit,
  ) async {
    emit(const ModelBenchmarkLoading(message: 'Scoring vs ground truth…'));
    final result = await _run(
      RunBenchmarkParams(
        modelId: event.modelId,
        sessionIds: event.sessionIds,
        experimentRunId: event.experimentRunId,
        iouThreshold: event.iouThreshold,
      ),
    );
    await result.fold(
      onOk: (report) async {
        _logger.info('Benchmark done ${report.id}', tag: 'BenchmarkBloc');
        await _reload(
          emit,
          message:
              'mAP≈${report.metrics.mapProxy.toStringAsFixed(2)} · '
              'P=${report.metrics.precision.toStringAsFixed(2)} · '
              'R=${report.metrics.recall.toStringAsFixed(2)}',
        );
      },
      onErr: (f) async => emit(ModelBenchmarkError(failure: f)),
    );
  }

  Future<void> _onDelete(
    ModelBenchmarkDelete event,
    Emitter<ModelBenchmarkState> emit,
  ) async {
    emit(const ModelBenchmarkLoading(message: 'Deleting…'));
    final result = await _delete(DeleteBenchmarkReportParams(event.reportId));
    await result.fold(
      onOk: (_) async => _reload(emit, message: 'Report deleted'),
      onErr: (f) async => emit(ModelBenchmarkError(failure: f)),
    );
  }

  Future<void> _onDemo(
    ModelBenchmarkCreateDemo event,
    Emitter<ModelBenchmarkState> emit,
  ) async {
    emit(const ModelBenchmarkLoading(message: 'Creating demo benchmark…'));
    final result = await _demo(const CreateDemoBenchmarkParams());
    await result.fold(
      onOk: (r) async => _reload(
        emit,
        message:
            'Demo · mAP≈${r.metrics.mapProxy.toStringAsFixed(2)} · '
            '${r.mode.label}',
      ),
      onErr: (f) async => emit(ModelBenchmarkError(failure: f)),
    );
  }

  Future<void> _reload(
    Emitter<ModelBenchmarkState> emit, {
    String? message,
  }) async {
    final result = await _load(const NoParams());
    result.fold(
      onOk: (snap) => emit(
        ModelBenchmarkLoaded(snapshot: snap, statusMessage: message),
      ),
      onErr: (f) => emit(ModelBenchmarkError(failure: f)),
    );
  }
}
