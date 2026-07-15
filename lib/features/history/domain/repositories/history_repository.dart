import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';

/// Domain contract for Hive-backed detection history.
abstract class HistoryRepository {
  /// Emits whenever the history box changes (sorted newest first).
  Stream<List<HistoryRecord>> watchRecords();

  /// One-shot load (all records, newest first).
  Future<Result<List<HistoryRecord>>> getRecords();

  /// Filtered view of current records.
  Future<Result<List<HistoryRecord>>> queryRecords(HistoryFilter filter);

  /// Persists a new draft (optional camera JPEG).
  Future<Result<HistoryRecord>> saveRecord(HistoryRecordDraft draft);

  /// Deletes one record and its image file if present.
  Future<Result<void>> deleteRecord(String id);

  /// Deletes many records by id.
  Future<Result<void>> deleteRecords(List<String> ids);

  /// Deletes all history + images.
  Future<Result<void>> clearAll();

  /// Writes filtered (or all) records to a JSON file.
  Future<Result<HistoryExportResult>> exportJson({HistoryFilter? filter});
}
