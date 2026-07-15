import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_explorer_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_explorer_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_explorer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dataset_explorer_event.dart';
export 'dataset_explorer_state.dart';

/// Research dashboard / session explorer orchestration (Phase 12.6).
class DatasetExplorerBloc
    extends Bloc<DatasetExplorerEvent, DatasetExplorerState> {
  final LoadDashboardUseCase _loadDashboard;
  final SearchSessionsUseCase _searchSessions;
  final LoadSessionDetailsUseCase _loadSessionDetails;
  final RenameExplorerSessionUseCase _renameSession;
  final DeleteExplorerSessionUseCase _deleteSession;
  final DuplicateExplorerSessionUseCase _duplicateSession;
  final AppLogger _logger;

  SessionQuery _query = const SessionQuery();

  /// Creates [DatasetExplorerBloc].
  DatasetExplorerBloc({
    required LoadDashboardUseCase loadDashboard,
    required SearchSessionsUseCase searchSessions,
    required LoadSessionDetailsUseCase loadSessionDetails,
    required RenameExplorerSessionUseCase renameSession,
    required DeleteExplorerSessionUseCase deleteSession,
    required DuplicateExplorerSessionUseCase duplicateSession,
    required AppLogger logger,
  })  : _loadDashboard = loadDashboard,
        _searchSessions = searchSessions,
        _loadSessionDetails = loadSessionDetails,
        _renameSession = renameSession,
        _deleteSession = deleteSession,
        _duplicateSession = duplicateSession,
        _logger = logger,
        super(const DatasetExplorerInitial()) {
    on<DatasetExplorerLoadDashboard>(_onLoadDashboard);
    on<DatasetExplorerRefreshDashboard>(_onRefreshDashboard);
    on<DatasetExplorerLoadSessions>(_onLoadSessions);
    on<DatasetExplorerSearchSession>(_onSearch);
    on<DatasetExplorerFilterSession>(_onFilter);
    on<DatasetExplorerSortSession>(_onSort);
    on<DatasetExplorerLoadMore>(_onLoadMore);
    on<DatasetExplorerOpenSession>(_onOpenSession);
    on<DatasetExplorerDeleteSession>(_onDelete);
    on<DatasetExplorerRenameSession>(_onRename);
    on<DatasetExplorerDuplicateSession>(_onDuplicate);
  }

  /// Current query (for UI chips).
  SessionQuery get currentQuery => _query;

  Future<void> _onLoadDashboard(
    DatasetExplorerLoadDashboard event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    emit(const DatasetExplorerLoading(message: 'Loading dashboard…'));
    final result = await _loadDashboard(const NoParams());
    result.fold(
      onOk: (data) {
        _logger.info('Dashboard Loaded', tag: 'DatasetExplorerBloc');
        if (data.statistics.totalSessions == 0) {
          emit(DatasetExplorerEmpty(dashboard: data));
        } else {
          emit(DatasetExplorerDashboardLoaded(data));
        }
      },
      onErr: (failure) {
        _logger.warning(failure.message, tag: 'DatasetExplorerBloc');
        emit(DatasetExplorerError(failure));
      },
    );
  }

  Future<void> _onRefreshDashboard(
    DatasetExplorerRefreshDashboard event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    await _onLoadDashboard(const DatasetExplorerLoadDashboard(), emit);
  }

  Future<void> _onLoadSessions(
    DatasetExplorerLoadSessions event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    if (event.query != null) {
      _query = event.query!;
    } else {
      _query = _query.copyWith(page: 0);
    }
    emit(const DatasetExplorerLoading(message: 'Loading sessions…'));
    await _emitSessions(emit, append: false);
  }

  Future<void> _onSearch(
    DatasetExplorerSearchSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    _query = _query.copyWith(searchQuery: event.query, page: 0);
    _logger.info('Search "${event.query}"', tag: 'DatasetExplorerBloc');
    emit(const DatasetExplorerLoading(message: 'Searching…'));
    await _emitSessions(emit, append: false);
  }

  Future<void> _onFilter(
    DatasetExplorerFilterSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    _query = _query.copyWith(
      dateFilter: event.dateFilter,
      status: event.status,
      minStorageBytes: event.minStorageBytes,
      minFloodEvents: event.minFloodEvents,
      page: 0,
      clearStatus: event.status == null,
      clearMinStorage: event.minStorageBytes == null,
      clearMinFlood: event.minFloodEvents == null,
    );
    _logger.info(
      'Filter date=${event.dateFilter} status=${event.status}',
      tag: 'DatasetExplorerBloc',
    );
    emit(const DatasetExplorerLoading(message: 'Filtering…'));
    await _emitSessions(emit, append: false);
  }

  Future<void> _onSort(
    DatasetExplorerSortSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    _query = _query.copyWith(sort: event.sort, page: 0);
    _logger.info('Sort ${event.sort}', tag: 'DatasetExplorerBloc');
    emit(const DatasetExplorerLoading(message: 'Sorting…'));
    await _emitSessions(emit, append: false);
  }

  Future<void> _onLoadMore(
    DatasetExplorerLoadMore event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    final current = state;
    if (current is! DatasetExplorerSessionsLoaded) return;
    if (!current.page.hasMore) return;

    _query = _query.copyWith(page: _query.page + 1);
    await _emitSessions(emit, append: true, previous: current.accumulated);
  }

  Future<void> _onOpenSession(
    DatasetExplorerOpenSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    emit(const DatasetExplorerLoading(message: 'Opening session…'));
    final result = await _loadSessionDetails(event.sessionId);
    result.fold(
      onOk: (details) {
        _logger.info(
          'Session Opened ${event.sessionId}',
          tag: 'DatasetExplorerBloc',
        );
        emit(DatasetExplorerSessionOpened(details));
      },
      onErr: (failure) {
        _logger.warning(failure.message, tag: 'DatasetExplorerBloc');
        emit(DatasetExplorerError(failure));
      },
    );
  }

  Future<void> _onDelete(
    DatasetExplorerDeleteSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    final previous = state;
    emit(const DatasetExplorerLoading(message: 'Deleting…'));
    final result = await _deleteSession(event.sessionId);
    await result.fold(
      onOk: (_) async {
        _logger.info('Delete ${event.sessionId}', tag: 'DatasetExplorerBloc');
        if (previous is DatasetExplorerSessionOpened) {
          // Details page listens and pops.
          emit(const DatasetExplorerEmpty());
        } else if (previous is DatasetExplorerDashboardLoaded ||
            previous is DatasetExplorerEmpty) {
          await _onLoadDashboard(const DatasetExplorerLoadDashboard(), emit);
        } else {
          _query = _query.copyWith(page: 0);
          await _emitSessions(emit, append: false);
        }
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetExplorerBloc');
        emit(DatasetExplorerError(failure));
      },
    );
  }

  Future<void> _onRename(
    DatasetExplorerRenameSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    final previous = state;
    emit(const DatasetExplorerLoading(message: 'Renaming…'));
    final result = await _renameSession(event.params);
    await result.fold(
      onOk: (_) async {
        _logger.info(
          'Rename ${event.params.id}',
          tag: 'DatasetExplorerBloc',
        );
        if (previous is DatasetExplorerSessionOpened) {
          await _onOpenSession(
            DatasetExplorerOpenSession(event.params.id),
            emit,
          );
        } else if (previous is DatasetExplorerDashboardLoaded ||
            previous is DatasetExplorerEmpty) {
          await _onLoadDashboard(const DatasetExplorerLoadDashboard(), emit);
        } else {
          _query = _query.copyWith(page: 0);
          await _emitSessions(emit, append: false);
        }
      },
      onErr: (failure) async {
        emit(DatasetExplorerError(failure));
      },
    );
  }

  Future<void> _onDuplicate(
    DatasetExplorerDuplicateSession event,
    Emitter<DatasetExplorerState> emit,
  ) async {
    final previous = state;
    emit(const DatasetExplorerLoading(message: 'Duplicating…'));
    final result = await _duplicateSession(event.sessionId);
    await result.fold(
      onOk: (copy) async {
        if (previous is DatasetExplorerSessionOpened) {
          await _onOpenSession(
            DatasetExplorerOpenSession(event.sessionId),
            emit,
          );
        } else if (previous is DatasetExplorerDashboardLoaded ||
            previous is DatasetExplorerEmpty) {
          await _onLoadDashboard(const DatasetExplorerLoadDashboard(), emit);
        } else {
          _query = _query.copyWith(page: 0);
          await _emitSessions(emit, append: false);
        }
        _logger.info(
          'Duplicate ${event.sessionId} → ${copy.id}',
          tag: 'DatasetExplorerBloc',
        );
      },
      onErr: (failure) async {
        emit(DatasetExplorerError(failure));
      },
    );
  }

  Future<void> _emitSessions(
    Emitter<DatasetExplorerState> emit, {
    required bool append,
    List<DatasetSession> previous = const [],
  }) async {
    final result = await _searchSessions(_query);
    result.fold(
      onOk: (page) {
        if (!append && page.totalCount == 0) {
          emit(const DatasetExplorerEmpty());
          return;
        }
        final accumulated = append
            ? [...previous, ...page.sessions]
            : List<DatasetSession>.from(page.sessions);
        emit(
          DatasetExplorerSessionsLoaded(
            page: page,
            accumulated: accumulated,
          ),
        );
      },
      onErr: (Failure failure) {
        emit(DatasetExplorerError(failure));
      },
    );
  }
}
