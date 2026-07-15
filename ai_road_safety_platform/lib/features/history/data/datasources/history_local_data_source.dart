import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';

/// Local Hive + filesystem access for history.
abstract class HistoryLocalDataSource {
  /// Watch box mutations mapped to domain records.
  Stream<List<HistoryRecord>> watchRecords();

  /// All records newest first.
  Future<List<HistoryRecord>> getRecords();

  /// Persist draft (+ optional JPEG capture).
  Future<HistoryRecord> saveRecord(HistoryRecordDraft draft);

  /// Delete by id.
  Future<void> deleteRecord(String id);

  /// Delete many.
  Future<void> deleteRecords(List<String> ids);

  /// Clear box + image directory files referenced.
  Future<void> clearAll();

  /// Write JSON export file; returns path + count.
  Future<HistoryExportResult> exportJson(List<HistoryRecord> records);
}
