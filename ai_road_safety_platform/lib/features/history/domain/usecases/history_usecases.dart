import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/history/domain/repositories/history_repository.dart';

/// Loads all history records.
class GetHistoryRecordsUseCase
    extends UseCase<Result<List<HistoryRecord>>, NoParams> {
  final HistoryRepository _repository;

  /// Creates [GetHistoryRecordsUseCase].
  GetHistoryRecordsUseCase(this._repository);

  @override
  Future<Result<List<HistoryRecord>>> call(NoParams params) {
    return _repository.getRecords();
  }
}

/// Queries history with search / filters.
class QueryHistoryRecordsUseCase
    extends UseCase<Result<List<HistoryRecord>>, HistoryFilter> {
  final HistoryRepository _repository;

  /// Creates [QueryHistoryRecordsUseCase].
  QueryHistoryRecordsUseCase(this._repository);

  @override
  Future<Result<List<HistoryRecord>>> call(HistoryFilter params) {
    return _repository.queryRecords(params);
  }
}

/// Saves a new history record (optional image capture).
class SaveHistoryRecordUseCase
    extends UseCase<Result<HistoryRecord>, HistoryRecordDraft> {
  final HistoryRepository _repository;

  /// Creates [SaveHistoryRecordUseCase].
  SaveHistoryRecordUseCase(this._repository);

  @override
  Future<Result<HistoryRecord>> call(HistoryRecordDraft params) {
    return _repository.saveRecord(params);
  }
}

/// Deletes a single history record.
class DeleteHistoryRecordUseCase extends UseCase<Result<void>, String> {
  final HistoryRepository _repository;

  /// Creates [DeleteHistoryRecordUseCase].
  DeleteHistoryRecordUseCase(this._repository);

  @override
  Future<Result<void>> call(String params) {
    return _repository.deleteRecord(params);
  }
}

/// Deletes multiple history records.
class DeleteHistoryRecordsUseCase
    extends UseCase<Result<void>, List<String>> {
  final HistoryRepository _repository;

  /// Creates [DeleteHistoryRecordsUseCase].
  DeleteHistoryRecordsUseCase(this._repository);

  @override
  Future<Result<void>> call(List<String> params) {
    return _repository.deleteRecords(params);
  }
}

/// Clears the entire history database.
class ClearHistoryUseCase extends UseCase<Result<void>, NoParams> {
  final HistoryRepository _repository;

  /// Creates [ClearHistoryUseCase].
  ClearHistoryUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.clearAll();
  }
}

/// Exports history (optionally filtered) as JSON.
class ExportHistoryJsonUseCase
    extends UseCase<Result<HistoryExportResult>, HistoryFilter?> {
  final HistoryRepository _repository;

  /// Creates [ExportHistoryJsonUseCase].
  ExportHistoryJsonUseCase(this._repository);

  @override
  Future<Result<HistoryExportResult>> call(HistoryFilter? params) {
    return _repository.exportJson(filter: params);
  }
}
