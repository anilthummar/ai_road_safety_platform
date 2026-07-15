import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/history/domain/repositories/history_repository.dart';
import 'package:ai_road_safety_platform/features/history/domain/usecases/history_usecases.dart';
import 'package:ai_road_safety_platform/features/history/presentation/bloc/history_event.dart';
import 'package:ai_road_safety_platform/features/history/presentation/bloc/history_state.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

export 'history_event.dart';
export 'history_state.dart';

/// Orchestrates Hive history: search, filters, delete, export.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistoryRecordsUseCase _getRecords;
  final SaveHistoryRecordUseCase _saveRecord;
  final DeleteHistoryRecordUseCase _deleteRecord;
  final DeleteHistoryRecordsUseCase _deleteRecords;
  final ClearHistoryUseCase _clearHistory;
  final ExportHistoryJsonUseCase _exportJson;
  final HistoryRepository _repository;
  final AppLogger _logger;

  StreamSubscription<List<HistoryRecord>>? _watchSub;
  HistoryFilter _filter = const HistoryFilter.empty();

  /// Creates [HistoryBloc].
  HistoryBloc({
    required GetHistoryRecordsUseCase getRecords,
    required SaveHistoryRecordUseCase saveRecord,
    required DeleteHistoryRecordUseCase deleteRecord,
    required DeleteHistoryRecordsUseCase deleteRecords,
    required ClearHistoryUseCase clearHistory,
    required ExportHistoryJsonUseCase exportJson,
    required HistoryRepository repository,
    required AppLogger logger,
  })  : _getRecords = getRecords,
        _saveRecord = saveRecord,
        _deleteRecord = deleteRecord,
        _deleteRecords = deleteRecords,
        _clearHistory = clearHistory,
        _exportJson = exportJson,
        _repository = repository,
        _logger = logger,
        super(const HistoryInitial()) {
    on<HistoryStarted>(_onStarted);
    on<HistorySearchChanged>(_onSearchChanged);
    on<HistoryRiskFilterToggled>(_onRiskFilterToggled);
    on<HistoryMinFloodChanged>(_onMinFloodChanged);
    on<HistoryImagesOnlyToggled>(_onImagesOnlyToggled);
    on<HistoryFiltersCleared>(_onFiltersCleared);
    on<HistorySaveRequested>(_onSave);
    on<HistoryDeleteRequested>(_onDelete);
    on<HistoryDeleteSelectedRequested>(_onDeleteSelected);
    on<HistoryClearAllRequested>(_onClearAll);
    on<HistoryExportRequested>(_onExport);
    on<HistorySelectionToggled>(_onSelectionToggled);
    on<HistorySelectionCleared>(_onSelectionCleared);
    on<HistoryRecordsUpdated>(_onRecordsUpdated);
  }

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    await _watchSub?.cancel();
    _watchSub = _repository.watchRecords().listen(
      (records) => add(HistoryRecordsUpdated(records)),
      onError: (Object e, StackTrace st) {
        _logger.warning('$e', tag: 'HistoryBloc', error: e, stackTrace: st);
      },
    );

    final result = await _getRecords(const NoParams());
    await result.fold(
      onOk: (records) async {
        emit(_buildLoaded(records));
      },
      onErr: (failure) async {
        emit(HistoryError(failure));
      },
    );
  }

  void _onSearchChanged(
    HistorySearchChanged event,
    Emitter<HistoryState> emit,
  ) {
    _filter = _filter.copyWith(searchQuery: event.query);
    _refilter(emit);
  }

  void _onRiskFilterToggled(
    HistoryRiskFilterToggled event,
    Emitter<HistoryState> emit,
  ) {
    final next = Set<RiskLevel>.from(_filter.riskLevels);
    if (next.contains(event.level)) {
      next.remove(event.level);
    } else {
      next.add(event.level);
    }
    _filter = _filter.copyWith(riskLevels: next);
    _refilter(emit);
  }

  void _onMinFloodChanged(
    HistoryMinFloodChanged event,
    Emitter<HistoryState> emit,
  ) {
    _filter = event.minFloodPercent == null
        ? _filter.copyWith(clearMinFlood: true)
        : _filter.copyWith(minFloodPercent: event.minFloodPercent);
    _refilter(emit);
  }

  void _onImagesOnlyToggled(
    HistoryImagesOnlyToggled event,
    Emitter<HistoryState> emit,
  ) {
    final enabled = _filter.hasImageOnly != true;
    _filter = enabled
        ? _filter.copyWith(hasImageOnly: true)
        : _filter.copyWith(clearHasImage: true);
    _refilter(emit);
  }

  void _onFiltersCleared(
    HistoryFiltersCleared event,
    Emitter<HistoryState> emit,
  ) {
    _filter = const HistoryFilter.empty();
    _refilter(emit);
  }

  Future<void> _onSave(
    HistorySaveRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _saveRecord(event.draft);
    await result.fold(
      onOk: (record) async {
        _logger.info('History saved ${record.id}', tag: 'HistoryBloc');
        final current = state;
        if (current is HistoryLoaded) {
          emit(
            current.copyWith(
              statusMessage: 'Saved to history',
            ),
          );
        }
      },
      onErr: (failure) async {
        emit(HistoryError(failure));
      },
    );
  }

  Future<void> _onDelete(
    HistoryDeleteRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _deleteRecord(event.id);
    await result.fold(
      onOk: (_) async {},
      onErr: (failure) async => emit(HistoryError(failure)),
    );
  }

  Future<void> _onDeleteSelected(
    HistoryDeleteSelectedRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _deleteRecords(event.ids);
    await result.fold(
      onOk: (_) async {
        final current = state;
        if (current is HistoryLoaded) {
          emit(current.copyWith(selectedIds: {}, clearStatus: true));
        }
      },
      onErr: (failure) async => emit(HistoryError(failure)),
    );
  }

  Future<void> _onClearAll(
    HistoryClearAllRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _clearHistory(const NoParams());
    await result.fold(
      onOk: (_) async {
        _filter = const HistoryFilter.empty();
        emit(
          const HistoryLoaded(
            allRecords: [],
            visibleRecords: [],
            filter: HistoryFilter.empty(),
            statusMessage: 'History cleared',
          ),
        );
      },
      onErr: (failure) async => emit(HistoryError(failure)),
    );
  }

  Future<void> _onExport(
    HistoryExportRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _exportJson(_filter.isActive ? _filter : null);
    await result.fold(
      onOk: (exported) async {
        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(exported.filePath)],
              text:
                  'History export (${exported.recordCount} records)',
            ),
          );
        } catch (e) {
          _logger.warning('Share failed: $e', tag: 'HistoryBloc');
        }
        final current = state;
        if (current is HistoryLoaded) {
          emit(
            current.copyWith(
              statusMessage:
                  'Exported ${exported.recordCount} records',
            ),
          );
        }
      },
      onErr: (failure) async => emit(HistoryError(failure)),
    );
  }

  void _onSelectionToggled(
    HistorySelectionToggled event,
    Emitter<HistoryState> emit,
  ) {
    final current = state;
    if (current is! HistoryLoaded) return;
    final next = Set<String>.from(current.selectedIds);
    if (next.contains(event.id)) {
      next.remove(event.id);
    } else {
      next.add(event.id);
    }
    emit(current.copyWith(selectedIds: next));
  }

  void _onSelectionCleared(
    HistorySelectionCleared event,
    Emitter<HistoryState> emit,
  ) {
    final current = state;
    if (current is HistoryLoaded) {
      emit(current.copyWith(selectedIds: {}));
    }
  }

  void _onRecordsUpdated(
    HistoryRecordsUpdated event,
    Emitter<HistoryState> emit,
  ) {
    emit(_buildLoaded(event.records, keepSelection: true));
  }

  void _refilter(Emitter<HistoryState> emit) {
    final current = state;
    if (current is! HistoryLoaded) return;
    emit(
      current.copyWith(
        filter: _filter,
        visibleRecords: _filter.apply(current.allRecords),
        clearStatus: true,
      ),
    );
  }

  HistoryLoaded _buildLoaded(
    List<HistoryRecord> all, {
    bool keepSelection = false,
  }) {
    final current = state;
    final selected = keepSelection && current is HistoryLoaded
        ? current.selectedIds.intersection(all.map((e) => e.id).toSet())
        : <String>{};
    return HistoryLoaded(
      allRecords: all,
      visibleRecords: _filter.apply(all),
      filter: _filter,
      selectedIds: selected,
    );
  }

  @override
  Future<void> close() async {
    await _watchSub?.cancel();
    return super.close();
  }
}
