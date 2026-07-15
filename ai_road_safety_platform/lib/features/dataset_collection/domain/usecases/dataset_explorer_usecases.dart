import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_explorer_repository.dart';
import 'package:equatable/equatable.dart';

/// Loads the research dashboard.
class LoadDashboardUseCase
    extends UseCase<Result<DatasetDashboardData>, NoParams> {
  final DatasetExplorerRepository _repository;

  /// Creates [LoadDashboardUseCase].
  LoadDashboardUseCase(this._repository);

  @override
  Future<Result<DatasetDashboardData>> call(NoParams params) {
    return _repository.loadDashboard();
  }
}

/// Loads all sessions.
class LoadExplorerSessionsUseCase
    extends UseCase<Result<List<DatasetSession>>, NoParams> {
  final DatasetExplorerRepository _repository;

  /// Creates [LoadExplorerSessionsUseCase].
  LoadExplorerSessionsUseCase(this._repository);

  @override
  Future<Result<List<DatasetSession>>> call(NoParams params) {
    return _repository.loadSessions();
  }
}

/// Search / filter / sort / paginate sessions.
class SearchSessionsUseCase
    extends UseCase<Result<SessionPage>, SessionQuery> {
  final DatasetExplorerRepository _repository;

  /// Creates [SearchSessionsUseCase].
  SearchSessionsUseCase(this._repository);

  @override
  Future<Result<SessionPage>> call(SessionQuery params) {
    return _repository.searchSessions(params);
  }
}

/// Filter alias.
class FilterSessionsUseCase
    extends UseCase<Result<SessionPage>, SessionQuery> {
  final DatasetExplorerRepository _repository;

  /// Creates [FilterSessionsUseCase].
  FilterSessionsUseCase(this._repository);

  @override
  Future<Result<SessionPage>> call(SessionQuery params) {
    return _repository.filterSessions(params);
  }
}

/// Sort alias.
class SortSessionsUseCase
    extends UseCase<Result<SessionPage>, SessionQuery> {
  final DatasetExplorerRepository _repository;

  /// Creates [SortSessionsUseCase].
  SortSessionsUseCase(this._repository);

  @override
  Future<Result<SessionPage>> call(SessionQuery params) {
    return _repository.sortSessions(params);
  }
}

/// Loads session details.
class LoadSessionDetailsUseCase
    extends UseCase<Result<SessionDetails>, String> {
  final DatasetExplorerRepository _repository;

  /// Creates [LoadSessionDetailsUseCase].
  LoadSessionDetailsUseCase(this._repository);

  @override
  Future<Result<SessionDetails>> call(String params) {
    return _repository.loadSessionDetails(params);
  }
}

/// Preview load params.
class LoadPreviewImagesParams extends Equatable {
  /// Session id.
  final String sessionId;

  /// Max previews.
  final int limit;

  /// Creates [LoadPreviewImagesParams].
  const LoadPreviewImagesParams({
    required this.sessionId,
    this.limit = 24,
  });

  @override
  List<Object?> get props => [sessionId, limit];
}

/// Loads preview descriptors.
class LoadPreviewImagesUseCase
    extends UseCase<Result<List<SessionPreviewImage>>, LoadPreviewImagesParams> {
  final DatasetExplorerRepository _repository;

  /// Creates [LoadPreviewImagesUseCase].
  LoadPreviewImagesUseCase(this._repository);

  @override
  Future<Result<List<SessionPreviewImage>>> call(
    LoadPreviewImagesParams params,
  ) {
    return _repository.loadPreviewImages(
      params.sessionId,
      limit: params.limit,
    );
  }
}

/// Rename via explorer.
class RenameExplorerSessionUseCase
    extends UseCase<Result<DatasetSession>, RenameDatasetSessionParams> {
  final DatasetExplorerRepository _repository;

  /// Creates [RenameExplorerSessionUseCase].
  RenameExplorerSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(RenameDatasetSessionParams params) {
    return _repository.renameSession(params);
  }
}

/// Delete via explorer (Hive + disk).
class DeleteExplorerSessionUseCase extends UseCase<Result<void>, String> {
  final DatasetExplorerRepository _repository;

  /// Creates [DeleteExplorerSessionUseCase].
  DeleteExplorerSessionUseCase(this._repository);

  @override
  Future<Result<void>> call(String params) {
    return _repository.deleteSession(params);
  }
}

/// Duplicate session metadata.
class DuplicateExplorerSessionUseCase
    extends UseCase<Result<DatasetSession>, String> {
  final DatasetExplorerRepository _repository;

  /// Creates [DuplicateExplorerSessionUseCase].
  DuplicateExplorerSessionUseCase(this._repository);

  @override
  Future<Result<DatasetSession>> call(String params) {
    return _repository.duplicateSession(params);
  }
}
