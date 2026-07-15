import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_storage_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';

/// Maps storage DS exceptions to [Result]s.
class DatasetStorageRepositoryImpl implements DatasetStorageRepository {
  final DatasetStorageLocalDataSource _local;
  final ErrorHandler _errorHandler;

  /// Creates [DatasetStorageRepositoryImpl].
  DatasetStorageRepositoryImpl({
    required DatasetStorageLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _errorHandler = errorHandler;

  @override
  Future<Result<SavedImagePaths>> saveImage(SaveImageParams params) {
    return _guard(() => _local.saveImage(params));
  }

  @override
  Future<Result<String>> saveMetadata(SaveMetadataParams params) {
    return _guard(() => _local.saveMetadata(params.metadata));
  }

  @override
  Future<Result<Uint8List>> loadImage({
    required String sessionId,
    required int frameNumber,
  }) {
    return _guard(
      () => _local.loadImage(sessionId: sessionId, frameNumber: frameNumber),
    );
  }

  @override
  Future<Result<FrameMetadata>> loadMetadata({
    required String sessionId,
    required int frameNumber,
  }) {
    return _guard(
      () =>
          _local.loadMetadata(sessionId: sessionId, frameNumber: frameNumber),
    );
  }

  @override
  Future<Result<void>> deleteImage({
    required String sessionId,
    required int frameNumber,
  }) {
    return _guard(
      () => _local.deleteImage(sessionId: sessionId, frameNumber: frameNumber),
    );
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) {
    return _guard(() => _local.deleteSession(sessionId));
  }

  @override
  Future<Result<StorageUsage>> calculateStorage() {
    return _guard(_local.calculateStorage);
  }

  @override
  Future<Result<StorageUsage>> getStorageUsage() => calculateStorage();

  @override
  Future<Result<void>> clearCache() => _guard(_local.clearCache);

  @override
  Future<Result<int>> cleanupTemporaryFiles() {
    return _guard(_local.cleanupTemporaryFiles);
  }

  @override
  Future<Result<List<SessionRecoveryInfo>>> recoverSession({
    String? sessionId,
  }) {
    return _guard(() => _local.recoverSessions(sessionId: sessionId));
  }

  @override
  Future<Result<List<FolderInfo>>> listFolderInfo() {
    return _guard(_local.listFolderInfo);
  }

  @override
  Future<Result<List<RecentStorageFile>>> listRecentFiles({int limit = 20}) {
    return _guard(() => _local.listRecentFiles(limit: limit));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
