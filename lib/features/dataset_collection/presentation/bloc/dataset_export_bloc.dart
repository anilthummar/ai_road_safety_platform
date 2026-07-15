import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_export_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_export_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_export_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_export_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dataset_export_event.dart';
export 'dataset_export_state.dart';

/// Orchestrates research dataset export workflows (Phase 12.8).
class DatasetExportBloc
    extends Bloc<DatasetExportEvent, DatasetExportState> {
  final ExportDatasetUseCase _exportDataset;
  final ExportSessionUseCase _exportSession;
  final GenerateManifestUseCase _generateManifest;
  final GenerateReadmeUseCase _generateReadme;
  final CompressDatasetUseCase _compressDataset;
  final ValidateExportUseCase _validateExport;
  final DatasetExportRepository _repository;
  final AppLogger _logger;

  ExportSettings _settings = const ExportSettings();

  /// Creates [DatasetExportBloc].
  DatasetExportBloc({
    required ExportDatasetUseCase exportDataset,
    required ExportSessionUseCase exportSession,
    required GenerateManifestUseCase generateManifest,
    required GenerateReadmeUseCase generateReadme,
    required CompressDatasetUseCase compressDataset,
    required ValidateExportUseCase validateExport,
    required DatasetExportRepository repository,
    required AppLogger logger,
  })  : _exportDataset = exportDataset,
        _exportSession = exportSession,
        _generateManifest = generateManifest,
        _generateReadme = generateReadme,
        _compressDataset = compressDataset,
        _validateExport = validateExport,
        _repository = repository,
        _logger = logger,
        super(const DatasetExportInitial()) {
    on<DatasetExportUpdateSettings>(_onUpdateSettings);
    on<DatasetExportRequested>(_onExportDataset);
    on<DatasetExportSessionRequested>(_onExportSession);
    on<DatasetExportGenerateManifest>(_onGenerateManifest);
    on<DatasetExportGenerateReadme>(_onGenerateReadme);
    on<DatasetExportCompress>(_onCompress);
    on<DatasetExportValidate>(_onValidate);
    on<DatasetExportLoadHistory>(_onLoadHistory);
  }

  Future<void> _onUpdateSettings(
    DatasetExportUpdateSettings event,
    Emitter<DatasetExportState> emit,
  ) async {
    _settings = event.settings;
    emit(
      DatasetExportInitial(
        settings: _settings,
        history: await _safeHistory(),
      ),
    );
  }

  Future<void> _onExportDataset(
    DatasetExportRequested event,
    Emitter<DatasetExportState> emit,
  ) async {
    _settings = event.settings;
    await _executeExport(
      emit,
      (onProgress) => _exportDataset(
        ExportDatasetParams(settings: _settings, onProgress: onProgress),
      ),
    );
  }

  Future<void> _onExportSession(
    DatasetExportSessionRequested event,
    Emitter<DatasetExportState> emit,
  ) async {
    _settings = event.settings;
    await _executeExport(
      emit,
      (onProgress) => _exportSession(
        ExportSessionParams(
          sessionId: event.sessionId,
          settings: _settings,
          onProgress: onProgress,
        ),
      ),
    );
  }

  Future<void> _executeExport(
    Emitter<DatasetExportState> emit,
    Future Function(ExportProgressCallback onProgress) run,
  ) async {
    var progress = const ExportProgress(
      progress: 0.02,
      currentStep: 'Preparing…',
      elapsed: Duration.zero,
      logs: ['Export Started'],
    );
    emit(DatasetExportPreparing(settings: _settings, progress: progress));
    emit(
      DatasetExportExporting(
        settings: _settings,
        progress: progress.copyWith(
          progress: 0.15,
          currentStep: 'Exporting…',
        ),
      ),
    );

    final result = await run((p) {
      progress = p;
    });

    // Emit latest progress snapshot before completion / failure.
    if (progress.currentStep.toLowerCase().contains('compress') ||
        progress.currentStep.toLowerCase().contains('zip')) {
      emit(DatasetExportCompressing(settings: _settings, progress: progress));
    } else if (progress.progress > 0.12) {
      emit(DatasetExportExporting(settings: _settings, progress: progress));
    }

    await result.fold(
      onOk: (exportResult) async {
        final validation = await _validateExport(exportResult.exportFolderPath);
        emit(
          DatasetExportCompleted(
            result: exportResult,
            history: await _safeHistory(),
            validation: validation.fold(onOk: (v) => v, onErr: (_) => null),
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetExportBloc');
        emit(
          DatasetExportFailed(
            failure: failure,
            settings: _settings,
            progress: progress,
          ),
        );
      },
    );
  }

  Future<void> _onGenerateManifest(
    DatasetExportGenerateManifest event,
    Emitter<DatasetExportState> emit,
  ) async {
    emit(
      DatasetExportPreparing(
        settings: _settings,
        progress: const ExportProgress(
          progress: 0.4,
          currentStep: 'Generating manifest…',
          elapsed: Duration.zero,
        ),
      ),
    );
    final result = await _generateManifest(event.exportFolderPath);
    await result.fold(
      onOk: (_) async => emit(
        DatasetExportInitial(
          settings: _settings,
          history: await _safeHistory(),
        ),
      ),
      onErr: (f) async =>
          emit(DatasetExportFailed(failure: f, settings: _settings)),
    );
  }

  Future<void> _onGenerateReadme(
    DatasetExportGenerateReadme event,
    Emitter<DatasetExportState> emit,
  ) async {
    emit(
      DatasetExportPreparing(
        settings: _settings,
        progress: const ExportProgress(
          progress: 0.4,
          currentStep: 'Generating README…',
          elapsed: Duration.zero,
        ),
      ),
    );
    final result = await _generateReadme(event.exportFolderPath);
    await result.fold(
      onOk: (_) async => emit(
        DatasetExportInitial(
          settings: _settings,
          history: await _safeHistory(),
        ),
      ),
      onErr: (f) async =>
          emit(DatasetExportFailed(failure: f, settings: _settings)),
    );
  }

  Future<void> _onCompress(
    DatasetExportCompress event,
    Emitter<DatasetExportState> emit,
  ) async {
    emit(
      DatasetExportCompressing(
        settings: _settings,
        progress: const ExportProgress(
          progress: 0.5,
          currentStep: 'Compressing…',
          elapsed: Duration.zero,
        ),
      ),
    );
    final result = await _compressDataset(event.exportFolderPath);
    await result.fold(
      onOk: (_) async => emit(
        DatasetExportInitial(
          settings: _settings,
          history: await _safeHistory(),
        ),
      ),
      onErr: (f) async =>
          emit(DatasetExportFailed(failure: f, settings: _settings)),
    );
  }

  Future<void> _onValidate(
    DatasetExportValidate event,
    Emitter<DatasetExportState> emit,
  ) async {
    final result = await _validateExport(event.exportFolderPath);
    await result.fold(
      onOk: (v) async {
        if (!v.isValid) {
          emit(
            DatasetExportFailed(
              failure: CacheFailure(message: v.errors.join('; ')),
              settings: _settings,
            ),
          );
        } else {
          emit(
            DatasetExportInitial(
              settings: _settings,
              history: await _safeHistory(),
            ),
          );
        }
      },
      onErr: (f) async =>
          emit(DatasetExportFailed(failure: f, settings: _settings)),
    );
  }

  Future<void> _onLoadHistory(
    DatasetExportLoadHistory event,
    Emitter<DatasetExportState> emit,
  ) async {
    emit(
      DatasetExportInitial(
        settings: _settings,
        history: await _safeHistory(),
      ),
    );
  }

  Future<List<ExportHistoryEntry>> _safeHistory() async {
    final result = await _repository.loadExportHistory();
    return result.fold(onOk: (v) => v, onErr: (_) => const []);
  }
}
