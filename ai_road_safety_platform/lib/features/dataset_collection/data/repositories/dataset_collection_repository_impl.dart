import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_collection_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';

/// Maps dataset local datasource exceptions to domain [Result]s.
class DatasetCollectionRepositoryImpl implements DatasetCollectionRepository {
  final DatasetCollectionLocalDataSource _local;
  final ErrorHandler _errorHandler;

  /// Creates [DatasetCollectionRepositoryImpl].
  DatasetCollectionRepositoryImpl({
    required DatasetCollectionLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _errorHandler = errorHandler;

  @override
  Future<Result<DatasetSession>> createSession(
    CreateDatasetSessionParams params,
  ) {
    return _guard(() => _local.createSession(params));
  }

  @override
  Future<Result<DatasetSession>> startSession(
    CreateDatasetSessionParams params,
  ) {
    return _guard(() async {
      final active = await _local.getActiveSession();
      if (active != null) {
        throw const CacheException(
          message:
              'A recording session is already active. Pause or stop it first.',
        );
      }
      final name = params.sessionName.trim();
      if (name.isEmpty) {
        throw const CacheException(message: 'Session name cannot be empty.');
      }
      final saved = await _local.startRecordingSession(params);
      await _local.setCurrentSessionId(saved.id);
      return saved;
    });
  }

  @override
  Future<Result<DatasetSession>> pauseSession({required Duration elapsed}) {
    return _guard(() async {
      final active = await _requireUnfinished();
      if (!active.isRecording) {
        throw const CacheException(
          message: 'Only a recording session can be paused.',
        );
      }
      final updated = active.copyWith(
        status: DatasetSessionStatus.paused,
        duration: elapsed,
        updatedAt: DateTime.now(),
      );
      return _local.updateSession(updated);
    });
  }

  @override
  Future<Result<DatasetSession>> resumeSession() {
    return _guard(() async {
      final active = await _requireUnfinished();
      if (active.status.isTerminal) {
        throw const CacheException(
          message: 'Cannot resume a completed session.',
        );
      }
      if (!active.isPaused) {
        throw const CacheException(
          message: 'Only a paused session can be resumed.',
        );
      }
      final updated = active.copyWith(
        status: DatasetSessionStatus.recording,
        updatedAt: DateTime.now(),
      );
      await _local.setCurrentSessionId(updated.id);
      return _local.updateSession(updated);
    });
  }

  @override
  Future<Result<DatasetSession>> stopSession({required Duration elapsed}) {
    return _finalize(
      elapsed: elapsed,
      status: DatasetSessionStatus.stopped,
    );
  }

  @override
  Future<Result<DatasetSession>> cancelSession({required Duration elapsed}) {
    return _finalize(
      elapsed: elapsed,
      status: DatasetSessionStatus.cancelled,
    );
  }

  @override
  Future<Result<DatasetSession>> completeSession({required Duration elapsed}) {
    return _finalize(
      elapsed: elapsed,
      status: DatasetSessionStatus.completed,
    );
  }

  @override
  Future<Result<DatasetSession>> renameSession(
    RenameDatasetSessionParams params,
  ) {
    return _guard(() async {
      final existing = await _local.getSession(params.id);
      final name = params.sessionName.trim();
      if (name.isEmpty) {
        throw const CacheException(message: 'Session name cannot be empty.');
      }
      final updated = existing.copyWith(
        sessionName: name,
        updatedAt: DateTime.now(),
      );
      return _local.updateSession(updated);
    });
  }

  @override
  Future<Result<void>> deleteSession(String id) {
    return _guard(() async {
      final existing = await _local.getSession(id);
      if (existing.status.isUnfinished) {
        throw const CacheException(
          message: 'Cannot delete an active recording session. Stop it first.',
        );
      }
      await _local.deleteSession(id);
    });
  }

  @override
  Future<Result<List<DatasetSession>>> getAllSessions() => getSessions();

  @override
  Future<Result<List<DatasetSession>>> getSessions() {
    return _guard(_local.getSessions);
  }

  @override
  Future<Result<DatasetSession>> getSession(String id) {
    return _guard(() => _local.getSession(id));
  }

  @override
  Future<Result<DatasetSession?>> getActiveSession() {
    return _guard(_local.getActiveSession);
  }

  @override
  Future<Result<DatasetSession?>> loadCurrentSession() => getActiveSession();

  @override
  Future<Result<DatasetSession>> updateSession(DatasetSession session) {
    return _guard(() => _local.updateSession(session));
  }

  @override
  Future<Result<DatasetStatistics>> getStatistics() {
    return _guard(_local.getStatistics);
  }

  @override
  Future<Result<DatasetStorage>> getStorageInformation() {
    return _guard(_local.getStorageInformation);
  }

  Future<Result<DatasetSession>> _finalize({
    required Duration elapsed,
    required DatasetSessionStatus status,
  }) {
    return _guard(() async {
      final active = await _requireUnfinished();
      final now = DateTime.now();
      final updated = active.copyWith(
        status: status,
        endedAt: now,
        duration: elapsed,
        updatedAt: now,
      );
      final saved = await _local.updateSession(updated);
      await _local.setCurrentSessionId(null);
      return saved;
    });
  }

  Future<DatasetSession> _requireUnfinished() async {
    final active = await _local.getActiveSession();
    if (active == null) {
      throw const CacheException(
        message: 'No active recording session.',
      );
    }
    return active;
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
