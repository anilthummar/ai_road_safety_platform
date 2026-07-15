import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:equatable/equatable.dart';

/// History presentation states.
sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial.
final class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

/// Loading.
final class HistoryLoading extends HistoryState {
  /// Message.
  final String message;

  /// Creates [HistoryLoading].
  const HistoryLoading({this.message = 'Loading history…'});

  @override
  List<Object?> get props => [message];
}

/// Loaded list + filters.
final class HistoryLoaded extends HistoryState {
  /// All records from Hive.
  final List<HistoryRecord> allRecords;

  /// Filtered view.
  final List<HistoryRecord> visibleRecords;

  /// Active filter.
  final HistoryFilter filter;

  /// Selected ids (multi-delete).
  final Set<String> selectedIds;

  /// Optional status banner (export path, save ok).
  final String? statusMessage;

  /// Creates [HistoryLoaded].
  const HistoryLoaded({
    required this.allRecords,
    required this.visibleRecords,
    required this.filter,
    this.selectedIds = const {},
    this.statusMessage,
  });

  /// Whether selection mode is active.
  bool get isSelecting => selectedIds.isNotEmpty;

  /// Copy helper.
  HistoryLoaded copyWith({
    List<HistoryRecord>? allRecords,
    List<HistoryRecord>? visibleRecords,
    HistoryFilter? filter,
    Set<String>? selectedIds,
    String? statusMessage,
    bool clearStatus = false,
  }) {
    return HistoryLoaded(
      allRecords: allRecords ?? this.allRecords,
      visibleRecords: visibleRecords ?? this.visibleRecords,
      filter: filter ?? this.filter,
      selectedIds: selectedIds ?? this.selectedIds,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
        allRecords,
        visibleRecords,
        filter,
        selectedIds,
        statusMessage,
      ];
}

/// Failure.
final class HistoryError extends HistoryState {
  /// Failure.
  final Failure failure;

  /// Creates [HistoryError].
  const HistoryError(this.failure);

  @override
  List<Object?> get props => [failure];
}
