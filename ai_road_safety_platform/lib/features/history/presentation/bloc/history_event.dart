import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:equatable/equatable.dart';

/// History presentation events.
sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Load + subscribe to Hive box.
final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

/// Update free-text search.
final class HistorySearchChanged extends HistoryEvent {
  /// Query text.
  final String query;

  /// Creates [HistorySearchChanged].
  const HistorySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Toggle a risk-level filter chip.
final class HistoryRiskFilterToggled extends HistoryEvent {
  /// Level to toggle.
  final RiskLevel level;

  /// Creates [HistoryRiskFilterToggled].
  const HistoryRiskFilterToggled(this.level);

  @override
  List<Object?> get props => [level];
}

/// Set minimum flood percent filter (null clears).
final class HistoryMinFloodChanged extends HistoryEvent {
  /// Minimum flood % or null.
  final double? minFloodPercent;

  /// Creates [HistoryMinFloodChanged].
  const HistoryMinFloodChanged(this.minFloodPercent);

  @override
  List<Object?> get props => [minFloodPercent];
}

/// Toggle images-only filter.
final class HistoryImagesOnlyToggled extends HistoryEvent {
  const HistoryImagesOnlyToggled();
}

/// Clear all filters / search.
final class HistoryFiltersCleared extends HistoryEvent {
  const HistoryFiltersCleared();
}

/// Save a draft record.
final class HistorySaveRequested extends HistoryEvent {
  /// Draft to persist.
  final HistoryRecordDraft draft;

  /// Creates [HistorySaveRequested].
  const HistorySaveRequested(this.draft);

  @override
  List<Object?> get props => [draft];
}

/// Delete one record.
final class HistoryDeleteRequested extends HistoryEvent {
  /// Record id.
  final String id;

  /// Creates [HistoryDeleteRequested].
  const HistoryDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Delete selected ids.
final class HistoryDeleteSelectedRequested extends HistoryEvent {
  /// Ids.
  final List<String> ids;

  /// Creates [HistoryDeleteSelectedRequested].
  const HistoryDeleteSelectedRequested(this.ids);

  @override
  List<Object?> get props => [ids];
}

/// Clear entire database.
final class HistoryClearAllRequested extends HistoryEvent {
  const HistoryClearAllRequested();
}

/// Export filtered (or all) JSON and share.
final class HistoryExportRequested extends HistoryEvent {
  const HistoryExportRequested();
}

/// Toggle selection mode / id.
final class HistorySelectionToggled extends HistoryEvent {
  /// Record id.
  final String id;

  /// Creates [HistorySelectionToggled].
  const HistorySelectionToggled(this.id);

  @override
  List<Object?> get props => [id];
}

/// Exit selection mode.
final class HistorySelectionCleared extends HistoryEvent {
  const HistorySelectionCleared();
}

/// Internal: box updated.
final class HistoryRecordsUpdated extends HistoryEvent {
  /// All records from Hive.
  final List<HistoryRecord> records;

  /// Creates [HistoryRecordsUpdated].
  const HistoryRecordsUpdated(this.records);

  @override
  List<Object?> get props => [records];
}
