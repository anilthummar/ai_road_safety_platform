import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:equatable/equatable.dart';

/// Saves a captured image triad to disk.
class SaveCapturedImageUseCase
    extends UseCase<Result<SavedImagePaths>, SaveImageParams> {
  final DatasetStorageRepository _repository;

  /// Creates [SaveCapturedImageUseCase].
  SaveCapturedImageUseCase(this._repository);

  @override
  Future<Result<SavedImagePaths>> call(SaveImageParams params) {
    return _repository.saveImage(params);
  }
}

/// Saves synchronized frame metadata JSON.
class SaveFrameMetadataUseCase
    extends UseCase<Result<String>, SaveMetadataParams> {
  final DatasetStorageRepository _repository;

  /// Creates [SaveFrameMetadataUseCase].
  SaveFrameMetadataUseCase(this._repository);

  @override
  Future<Result<String>> call(SaveMetadataParams params) {
    return _repository.saveMetadata(params);
  }
}

/// Params for load/delete by session + frame number.
class SessionFrameParams extends Equatable {
  /// Session id.
  final String sessionId;

  /// Frame number.
  final int frameNumber;

  /// Creates [SessionFrameParams].
  const SessionFrameParams({
    required this.sessionId,
    required this.frameNumber,
  });

  @override
  List<Object?> get props => [sessionId, frameNumber];
}

/// Loads original image bytes.
class LoadCapturedImageUseCase
    extends UseCase<Result<Uint8List>, SessionFrameParams> {
  final DatasetStorageRepository _repository;

  /// Creates [LoadCapturedImageUseCase].
  LoadCapturedImageUseCase(this._repository);

  @override
  Future<Result<Uint8List>> call(SessionFrameParams params) {
    return _repository.loadImage(
      sessionId: params.sessionId,
      frameNumber: params.frameNumber,
    );
  }
}

/// Loads frame metadata from disk.
class LoadFrameMetadataUseCase
    extends UseCase<Result<FrameMetadata>, SessionFrameParams> {
  final DatasetStorageRepository _repository;

  /// Creates [LoadFrameMetadataUseCase].
  LoadFrameMetadataUseCase(this._repository);

  @override
  Future<Result<FrameMetadata>> call(SessionFrameParams params) {
    return _repository.loadMetadata(
      sessionId: params.sessionId,
      frameNumber: params.frameNumber,
    );
  }
}

/// Deletes a session folder tree.
class DeleteDatasetSessionStorageUseCase
    extends UseCase<Result<void>, String> {
  final DatasetStorageRepository _repository;

  /// Creates [DeleteDatasetSessionStorageUseCase].
  DeleteDatasetSessionStorageUseCase(this._repository);

  @override
  Future<Result<void>> call(String params) {
    return _repository.deleteSession(params);
  }
}

/// Calculates storage usage.
class CalculateStorageUsageUseCase
    extends UseCase<Result<StorageUsage>, NoParams> {
  final DatasetStorageRepository _repository;

  /// Creates [CalculateStorageUsageUseCase].
  CalculateStorageUsageUseCase(this._repository);

  @override
  Future<Result<StorageUsage>> call(NoParams params) {
    return _repository.calculateStorage();
  }
}

/// Recovers incomplete / crashed sessions.
class RecoverRecordingSessionUseCase
    extends UseCase<Result<List<SessionRecoveryInfo>>, String?> {
  final DatasetStorageRepository _repository;

  /// Creates [RecoverRecordingSessionUseCase].
  RecoverRecordingSessionUseCase(this._repository);

  @override
  Future<Result<List<SessionRecoveryInfo>>> call(String? params) {
    return _repository.recoverSession(sessionId: params);
  }
}

/// Clears dataset cache.
class CleanupCacheUseCase extends UseCase<Result<void>, NoParams> {
  final DatasetStorageRepository _repository;

  /// Creates [CleanupCacheUseCase].
  CleanupCacheUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.clearCache();
}

/// Cleans temp folders + cache content count.
class CleanupTemporaryFilesUseCase extends UseCase<Result<int>, NoParams> {
  final DatasetStorageRepository _repository;

  /// Creates [CleanupTemporaryFilesUseCase].
  CleanupTemporaryFilesUseCase(this._repository);

  @override
  Future<Result<int>> call(NoParams params) {
    return _repository.cleanupTemporaryFiles();
  }
}

/// Deletes a single frame's image triad.
class DeleteStoredImageUseCase
    extends UseCase<Result<void>, SessionFrameParams> {
  final DatasetStorageRepository _repository;

  /// Creates [DeleteStoredImageUseCase].
  DeleteStoredImageUseCase(this._repository);

  @override
  Future<Result<void>> call(SessionFrameParams params) {
    return _repository.deleteImage(
      sessionId: params.sessionId,
      frameNumber: params.frameNumber,
    );
  }
}
