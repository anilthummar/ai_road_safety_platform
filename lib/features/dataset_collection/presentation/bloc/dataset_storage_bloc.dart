import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_storage_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_storage_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_storage_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dataset_storage_event.dart';
export 'dataset_storage_state.dart';

/// Orchestrates local dataset file persistence (Phase 12.5).
class DatasetStorageBloc
    extends Bloc<DatasetStorageEvent, DatasetStorageState> {
  final SaveCapturedImageUseCase _saveImage;
  final SaveFrameMetadataUseCase _saveMetadata;
  final LoadCapturedImageUseCase _loadImage;
  final LoadFrameMetadataUseCase _loadMetadata;
  final DeleteDatasetSessionStorageUseCase _deleteSession;
  final CalculateStorageUsageUseCase _calculate;
  final CleanupCacheUseCase _cleanupCache;
  final CleanupTemporaryFilesUseCase _cleanupTemp;
  final RecoverRecordingSessionUseCase _recover;
  final DatasetStorageRepository _repository;
  final AppLogger _logger;

  /// Creates [DatasetStorageBloc].
  DatasetStorageBloc({
    required SaveCapturedImageUseCase saveCapturedImage,
    required SaveFrameMetadataUseCase saveFrameMetadata,
    required LoadCapturedImageUseCase loadCapturedImage,
    required LoadFrameMetadataUseCase loadFrameMetadata,
    required DeleteDatasetSessionStorageUseCase deleteDatasetSession,
    required CalculateStorageUsageUseCase calculateStorageUsage,
    required CleanupCacheUseCase cleanupCache,
    required CleanupTemporaryFilesUseCase cleanupTemporaryFiles,
    required RecoverRecordingSessionUseCase recoverRecordingSession,
    required DatasetStorageRepository repository,
    required AppLogger logger,
  })  : _saveImage = saveCapturedImage,
        _saveMetadata = saveFrameMetadata,
        _loadImage = loadCapturedImage,
        _loadMetadata = loadFrameMetadata,
        _deleteSession = deleteDatasetSession,
        _calculate = calculateStorageUsage,
        _cleanupCache = cleanupCache,
        _cleanupTemp = cleanupTemporaryFiles,
        _recover = recoverRecordingSession,
        _repository = repository,
        _logger = logger,
        super(const DatasetStorageInitial()) {
    on<DatasetStorageSaveImage>(_onSaveImage);
    on<DatasetStorageSaveMetadata>(_onSaveMetadata);
    on<DatasetStorageLoadImage>(_onLoadImage);
    on<DatasetStorageLoadMetadata>(_onLoadMetadata);
    on<DatasetStorageDeleteSession>(_onDeleteSession);
    on<DatasetStorageCalculateStorage>(_onCalculate);
    on<DatasetStorageCleanupStorage>(_onCleanup);
    on<DatasetStorageRecoverSession>(_onRecover);
  }

  Future<void> _onSaveImage(
    DatasetStorageSaveImage event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageSaving(message: 'Saving image…'));
    final result = await _saveImage(event.params);
    await result.fold(
      onOk: (paths) async {
        emit(
          DatasetStorageSaved(
            imagePaths: paths,
            message: 'Image saved (frame ${paths.frameNumber})',
          ),
        );
        await _emitCalculated(emit);
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetStorageBloc');
        emit(DatasetStorageError(failure));
      },
    );
  }

  Future<void> _onSaveMetadata(
    DatasetStorageSaveMetadata event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageSaving(message: 'Saving metadata…'));
    final result = await _saveMetadata(SaveMetadataParams(event.metadata));
    await result.fold(
      onOk: (path) async {
        emit(
          DatasetStorageSaved(
            metadataPath: path,
            message:
                'Metadata saved (frame ${event.metadata.session.frameNumber})',
          ),
        );
        await _emitCalculated(emit);
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetStorageBloc');
        emit(DatasetStorageError(failure));
      },
    );
  }

  Future<void> _onLoadImage(
    DatasetStorageLoadImage event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageLoading(message: 'Loading image…'));
    final result = await _loadImage(
      SessionFrameParams(
        sessionId: event.sessionId,
        frameNumber: event.frameNumber,
      ),
    );
    await result.fold(
      onOk: (bytes) async => emit(DatasetStorageImageLoaded(bytes)),
      onErr: (failure) async => emit(DatasetStorageError(failure)),
    );
  }

  Future<void> _onLoadMetadata(
    DatasetStorageLoadMetadata event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageLoading(message: 'Loading metadata…'));
    final result = await _loadMetadata(
      SessionFrameParams(
        sessionId: event.sessionId,
        frameNumber: event.frameNumber,
      ),
    );
    await result.fold(
      onOk: (meta) async => emit(DatasetStorageMetadataLoaded(meta)),
      onErr: (failure) async => emit(DatasetStorageError(failure)),
    );
  }

  Future<void> _onDeleteSession(
    DatasetStorageDeleteSession event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageDeleting());
    final result = await _deleteSession(event.sessionId);
    await result.fold(
      onOk: (_) async => _emitCalculated(emit),
      onErr: (failure) async => emit(DatasetStorageError(failure)),
    );
  }

  Future<void> _onCalculate(
    DatasetStorageCalculateStorage event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageLoading(message: 'Calculating storage…'));
    await _emitCalculated(emit);
  }

  Future<void> _onCleanup(
    DatasetStorageCleanupStorage event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageSaving(message: 'Cleaning storage…'));
    final cache = await _cleanupCache(const NoParams());
    if (cache.isErr) {
      emit(
        DatasetStorageError(
          cache.fold(onOk: (_) => throw StateError(''), onErr: (f) => f),
        ),
      );
      return;
    }
    final temp = await _cleanupTemp(const NoParams());
    await temp.fold(
      onOk: (n) async {
        emit(
          DatasetStorageSaved(message: 'Cleanup complete ($n temp entries)'),
        );
        await _emitCalculated(emit);
      },
      onErr: (failure) async => emit(DatasetStorageError(failure)),
    );
  }

  Future<void> _onRecover(
    DatasetStorageRecoverSession event,
    Emitter<DatasetStorageState> emit,
  ) async {
    emit(const DatasetStorageLoading(message: 'Recovering sessions…'));
    final result = await _recover(event.sessionId);
    await result.fold(
      onOk: (list) async {
        emit(DatasetStorageRecovered(list));
        await _emitCalculated(emit);
      },
      onErr: (failure) async => emit(DatasetStorageError(failure)),
    );
  }

  Future<void> _emitCalculated(Emitter<DatasetStorageState> emit) async {
    final usageResult = await _calculate(const NoParams());
    final foldersResult = await _repository.listFolderInfo();
    final recentResult = await _repository.listRecentFiles();

    Failure? failure;
    StorageUsage? usage;
    List<FolderInfo> folders = const [];
    List<RecentStorageFile> recent = const [];

    usageResult.fold(
      onOk: (v) => usage = v,
      onErr: (f) => failure = f,
    );
    if (failure != null) {
      emit(DatasetStorageError(failure!));
      return;
    }
    foldersResult.fold(
      onOk: (v) => folders = v,
      onErr: (f) => failure = f,
    );
    if (failure != null) {
      emit(DatasetStorageError(failure!));
      return;
    }
    recentResult.fold(
      onOk: (v) => recent = v,
      onErr: (f) => failure = f,
    );
    if (failure != null) {
      emit(DatasetStorageError(failure!));
      return;
    }

    emit(
      DatasetStorageCalculated(
        usage: usage!,
        folders: folders,
        recentFiles: recent,
      ),
    );
  }
}
