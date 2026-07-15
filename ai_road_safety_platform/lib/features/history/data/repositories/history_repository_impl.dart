import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/history/data/datasources/history_local_data_source.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/history/domain/repositories/history_repository.dart';

/// Maps Hive history operations to domain [Result]s.
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource _local;
  final ErrorHandler _errorHandler;

  /// Creates [HistoryRepositoryImpl].
  HistoryRepositoryImpl({
    required HistoryLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _errorHandler = errorHandler;

  @override
  Stream<List<HistoryRecord>> watchRecords() => _local.watchRecords();

  @override
  Future<Result<List<HistoryRecord>>> getRecords() {
    return _guard(_local.getRecords);
  }

  @override
  Future<Result<List<HistoryRecord>>> queryRecords(HistoryFilter filter) {
    return _guard(() async {
      final all = await _local.getRecords();
      return filter.apply(all);
    });
  }

  @override
  Future<Result<HistoryRecord>> saveRecord(HistoryRecordDraft draft) {
    return _guard(() => _local.saveRecord(draft));
  }

  @override
  Future<Result<void>> deleteRecord(String id) {
    return _guard(() => _local.deleteRecord(id));
  }

  @override
  Future<Result<void>> deleteRecords(List<String> ids) {
    return _guard(() => _local.deleteRecords(ids));
  }

  @override
  Future<Result<void>> clearAll() {
    return _guard(_local.clearAll);
  }

  @override
  Future<Result<HistoryExportResult>> exportJson({HistoryFilter? filter}) {
    return _guard(() async {
      final all = await _local.getRecords();
      final records = filter == null ? all : filter.apply(all);
      return _local.exportJson(records);
    });
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
