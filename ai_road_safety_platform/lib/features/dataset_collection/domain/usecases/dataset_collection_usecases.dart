import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:equatable/equatable.dart';

/// Creates a new idle dataset session row.
class CreateDatasetSessionUseCase
    extends UseCase<Result<DatasetSession>, CreateDatasetSessionParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [CreateDatasetSessionUseCase].
  CreateDatasetSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(CreateDatasetSessionParams params) {
    return _repository.createSession(params);
  }
}

/// Starts a new recording session (one active at a time).
class StartRecordingSessionUseCase
    extends UseCase<Result<DatasetSession>, CreateDatasetSessionParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [StartRecordingSessionUseCase].
  StartRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(CreateDatasetSessionParams params) {
    return _repository.startSession(params);
  }
}

/// Parameters for finalizing / pausing with elapsed time.
class SessionElapsedParams extends Equatable {
  /// Accumulated timer elapsed.
  final Duration elapsed;

  /// Creates [SessionElapsedParams].
  const SessionElapsedParams(this.elapsed);

  @override
  List<Object?> get props => [elapsed];
}

/// Pauses the active recording session.
class PauseRecordingSessionUseCase
    extends UseCase<Result<DatasetSession>, SessionElapsedParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [PauseRecordingSessionUseCase].
  PauseRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(SessionElapsedParams params) {
    return _repository.pauseSession(elapsed: params.elapsed);
  }
}

/// Resumes a paused recording session.
class ResumeRecordingSessionUseCase
    extends UseCase<Result<DatasetSession>, NoParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [ResumeRecordingSessionUseCase].
  ResumeRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(NoParams params) {
    return _repository.resumeSession();
  }
}

/// Stops the active/paused session.
class StopRecordingSessionUseCase
    extends UseCase<Result<DatasetSession>, SessionElapsedParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [StopRecordingSessionUseCase].
  StopRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(SessionElapsedParams params) {
    return _repository.stopSession(elapsed: params.elapsed);
  }
}

/// Cancels the active/paused session.
class CancelRecordingSessionUseCase
    extends UseCase<Result<DatasetSession>, SessionElapsedParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [CancelRecordingSessionUseCase].
  CancelRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(SessionElapsedParams params) {
    return _repository.cancelSession(elapsed: params.elapsed);
  }
}

/// Marks the unfinished session as completed.
class CompleteRecordingSessionUseCase
    extends UseCase<Result<DatasetSession>, SessionElapsedParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [CompleteRecordingSessionUseCase].
  CompleteRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(SessionElapsedParams params) {
    return _repository.completeSession(elapsed: params.elapsed);
  }
}

/// Renames a dataset session.
class RenameDatasetSessionUseCase
    extends UseCase<Result<DatasetSession>, RenameDatasetSessionParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [RenameDatasetSessionUseCase].
  RenameDatasetSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(RenameDatasetSessionParams params) {
    return _repository.renameSession(params);
  }
}

/// Alias matching Phase 12.2 naming.
typedef RenameRecordingSessionUseCase = RenameDatasetSessionUseCase;

/// Deletes a dataset session by id.
class DeleteDatasetSessionUseCase extends UseCase<Result<void>, String> {
  final DatasetCollectionRepository _repository;

  /// Creates [DeleteDatasetSessionUseCase].
  DeleteDatasetSessionUseCase(this._repository);

  @override
  Future<Result<void>> call(String params) {
    return _repository.deleteSession(params);
  }
}

/// Alias matching Phase 12.2 naming.
typedef DeleteRecordingSessionUseCase = DeleteDatasetSessionUseCase;

/// Loads all dataset sessions.
class GetDatasetSessionsUseCase
    extends UseCase<Result<List<DatasetSession>>, NoParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [GetDatasetSessionsUseCase].
  GetDatasetSessionsUseCase(this._repository);

  @override
  Future<Result<List<DatasetSession>>> call(NoParams params) {
    return _repository.getAllSessions();
  }
}

/// Alias matching Phase 12.2 naming.
typedef GetAllRecordingSessionsUseCase = GetDatasetSessionsUseCase;

/// Loads one dataset session.
class GetDatasetSessionUseCase extends UseCase<Result<DatasetSession>, String> {
  final DatasetCollectionRepository _repository;

  /// Creates [GetDatasetSessionUseCase].
  GetDatasetSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(String params) {
    return _repository.getSession(params);
  }
}

/// Updates a full session entity.
class UpdateDatasetSessionUseCase
    extends UseCase<Result<DatasetSession>, DatasetSession> {
  final DatasetCollectionRepository _repository;

  /// Creates [UpdateDatasetSessionUseCase].
  UpdateDatasetSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(DatasetSession params) {
    return _repository.updateSession(params);
  }
}

/// Loads the unfinished recording session if any.
class LoadCurrentRecordingSessionUseCase
    extends UseCase<Result<DatasetSession?>, NoParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [LoadCurrentRecordingSessionUseCase].
  LoadCurrentRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession?>> call(NoParams params) {
    return _repository.loadCurrentSession();
  }
}

/// Loads the active unfinished session (recording or paused).
class GetActiveRecordingSessionUseCase
    extends UseCase<Result<DatasetSession?>, NoParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [GetActiveRecordingSessionUseCase].
  GetActiveRecordingSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession?>> call(NoParams params) {
    return _repository.getActiveSession();
  }
}

/// Loads aggregate dataset statistics.
class GetDatasetStatisticsUseCase
    extends UseCase<Result<DatasetStatistics>, NoParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [GetDatasetStatisticsUseCase].
  GetDatasetStatisticsUseCase(this._repository);

  @override
  Future<Result<DatasetStatistics>> call(NoParams params) {
    return _repository.getStatistics();
  }
}

/// Loads dataset storage information.
class GetStorageInformationUseCase
    extends UseCase<Result<DatasetStorage>, NoParams> {
  final DatasetCollectionRepository _repository;

  /// Creates [GetStorageInformationUseCase].
  GetStorageInformationUseCase(this._repository);

  @override
  Future<Result<DatasetStorage>> call(NoParams params) {
    return _repository.getStorageInformation();
  }
}
