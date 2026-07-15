import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/session_timer_service.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_collection_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_collection_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_collection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'dataset_collection_event.dart';
export 'dataset_collection_state.dart';

/// Orchestrates dataset recording session lifecycle (Phase 12.2 — no capture).
class DatasetCollectionBloc
    extends Bloc<DatasetCollectionEvent, DatasetCollectionState> {
  final CreateDatasetSessionUseCase _createSession;
  final StartRecordingSessionUseCase _startSession;
  final PauseRecordingSessionUseCase _pauseSession;
  final ResumeRecordingSessionUseCase _resumeSession;
  final StopRecordingSessionUseCase _stopSession;
  final CancelRecordingSessionUseCase _cancelSession;
  final RenameDatasetSessionUseCase _renameSession;
  final DeleteDatasetSessionUseCase _deleteSession;
  final GetDatasetSessionsUseCase _getSessions;
  final GetDatasetStatisticsUseCase _getStatistics;
  final GetStorageInformationUseCase _getStorage;
  final LoadCurrentRecordingSessionUseCase _loadCurrent;
  final SessionTimerService _timer;
  final AppLogger _logger;

  StreamSubscription<Duration>? _timerSub;

  /// Creates [DatasetCollectionBloc].
  DatasetCollectionBloc({
    required CreateDatasetSessionUseCase createSession,
    required StartRecordingSessionUseCase startSession,
    required PauseRecordingSessionUseCase pauseSession,
    required ResumeRecordingSessionUseCase resumeSession,
    required StopRecordingSessionUseCase stopSession,
    required CancelRecordingSessionUseCase cancelSession,
    required RenameDatasetSessionUseCase renameSession,
    required DeleteDatasetSessionUseCase deleteSession,
    required GetDatasetSessionsUseCase getSessions,
    required GetDatasetStatisticsUseCase getStatistics,
    required GetStorageInformationUseCase getStorage,
    required LoadCurrentRecordingSessionUseCase loadCurrent,
    required SessionTimerService timer,
    required AppLogger logger,
  })  : _createSession = createSession,
        _startSession = startSession,
        _pauseSession = pauseSession,
        _resumeSession = resumeSession,
        _stopSession = stopSession,
        _cancelSession = cancelSession,
        _renameSession = renameSession,
        _deleteSession = deleteSession,
        _getSessions = getSessions,
        _getStatistics = getStatistics,
        _getStorage = getStorage,
        _loadCurrent = loadCurrent,
        _timer = timer,
        _logger = logger,
        super(const DatasetCollectionInitial()) {
    on<DatasetCollectionInitialize>(_onInitialize);
    on<DatasetCollectionLoadSessions>(_onLoadSessions);
    on<DatasetCollectionCreateSession>(_onCreate);
    on<DatasetCollectionStartRecording>(_onStart);
    on<DatasetCollectionPauseRecording>(_onPause);
    on<DatasetCollectionResumeRecording>(_onResume);
    on<DatasetCollectionStopRecording>(_onStop);
    on<DatasetCollectionCancelRecording>(_onCancel);
    on<DatasetCollectionRestoreSession>(_onRestore);
    on<DatasetCollectionRenameSession>(_onRename);
    on<DatasetCollectionDeleteSession>(_onDelete);
    on<DatasetCollectionLoadStatistics>(_onLoadStatistics);
    on<DatasetCollectionRefreshStorage>(_onRefreshStorage);
    on<DatasetCollectionTimerTicked>(_onTimerTicked);

    _timerSub = _timer.elapsedStream.listen((elapsed) {
      add(DatasetCollectionTimerTicked(elapsed));
    });
  }

  Future<void> _onInitialize(
    DatasetCollectionInitialize event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    emit(const DatasetCollectionLoading());
    final snapshot = await _loadDashboardSnapshot();
    if (snapshot.failure != null) {
      emit(DatasetCollectionError(snapshot.failure!));
      return;
    }

    final activeResult = await _loadCurrent(const NoParams());
    await activeResult.fold(
      onOk: (active) async {
        var data = snapshot.data!;
        if (active != null && active.status.isUnfinished) {
          data = data.copyWith(
            restoreCandidate: active,
            activeSession: active,
            elapsed: active.duration,
          );
          _timer.reset();
          emit(DatasetCollectionRestorePrompt(data));
          _logger.info(
            'Session Restored candidate: ${active.id} (${active.sessionName})',
            tag: 'DatasetCollectionBloc',
          );
          return;
        }
        _emitIdleDashboard(emit, data);
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onLoadSessions(
    DatasetCollectionLoadSessions event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final previous = state.dashboardOrNull;
    await _refreshDashboard(
      emit,
      loadingMessage: 'Refreshing sessions…',
      keepActive: previous?.activeSession,
      elapsed: previous?.elapsed ?? _timer.elapsed,
      recordingPhase: previous?.activeSession?.status,
    );
  }

  Future<void> _onCreate(
    DatasetCollectionCreateSession event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    emit(const DatasetCollectionBusy(message: 'Creating session…'));
    final result = await _createSession(event.params);
    await result.fold(
      onOk: (session) async {
        await _refreshDashboard(
          emit,
          statusMessage: 'Created “${session.sessionName}”.',
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onStart(
    DatasetCollectionStartRecording event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    emit(const DatasetCollectionBusy(message: 'Starting recording…'));
    final result = await _startSession(event.params);
    await result.fold(
      onOk: (session) async {
        _timer.start();
        _logger.info(
          'Session Started: ${session.id} (${session.sessionName})',
          tag: 'DatasetCollectionBloc',
        );
        await _refreshDashboard(
          emit,
          keepActive: session,
          elapsed: Duration.zero,
          recordingPhase: DatasetSessionStatus.recording,
          statusMessage: 'Recording “${session.sessionName}”.',
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
        await _refreshDashboard(emit);
      },
    );
  }

  Future<void> _onPause(
    DatasetCollectionPauseRecording event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final elapsed = _timer.elapsed;
    _timer.pause();
    final result =
        await _pauseSession(SessionElapsedParams(elapsed));
    await result.fold(
      onOk: (session) async {
        _logger.info(
          'Session Paused: ${session.id}',
          tag: 'DatasetCollectionBloc',
        );
        await _refreshDashboard(
          emit,
          keepActive: session,
          elapsed: elapsed,
          recordingPhase: DatasetSessionStatus.paused,
          statusMessage: 'Recording paused.',
        );
      },
      onErr: (failure) async {
        _timer.resume();
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onResume(
    DatasetCollectionResumeRecording event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final result = await _resumeSession(const NoParams());
    await result.fold(
      onOk: (session) async {
        _timer.resume();
        _logger.info(
          'Session Resumed: ${session.id}',
          tag: 'DatasetCollectionBloc',
        );
        await _refreshDashboard(
          emit,
          keepActive: session,
          elapsed: _timer.elapsed,
          recordingPhase: DatasetSessionStatus.recording,
          statusMessage: 'Recording resumed.',
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onStop(
    DatasetCollectionStopRecording event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final elapsed = _timer.elapsed;
    _timer.stop();
    final result = await _stopSession(SessionElapsedParams(elapsed));
    await result.fold(
      onOk: (session) async {
        _logger.info(
          'Session Stopped: ${session.id}',
          tag: 'DatasetCollectionBloc',
        );
        emit(DatasetCollectionStopped(session));
        _timer.reset();
        await _refreshDashboard(
          emit,
          statusMessage: 'Stopped “${session.sessionName}”.',
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onCancel(
    DatasetCollectionCancelRecording event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final elapsed = _timer.elapsed;
    _timer.stop();
    final result = await _cancelSession(SessionElapsedParams(elapsed));
    await result.fold(
      onOk: (session) async {
        _logger.info(
          'Session Cancelled: ${session.id}',
          tag: 'DatasetCollectionBloc',
        );
        emit(DatasetCollectionCancelled(session));
        _timer.reset();
        await _refreshDashboard(
          emit,
          statusMessage: 'Cancelled “${session.sessionName}”.',
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onRestore(
    DatasetCollectionRestoreSession event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final candidate = state.dashboardOrNull?.restoreCandidate;
    if (candidate == null) {
      await _refreshDashboard(emit);
      return;
    }

    if (!event.continueSession) {
      // Discard unfinished session.
      _timer.reset();
      final result =
          await _cancelSession(SessionElapsedParams(candidate.duration));
      await result.fold(
        onOk: (session) async {
          _logger.info(
            'Session Cancelled (discard restore): ${session.id}',
            tag: 'DatasetCollectionBloc',
          );
          emit(DatasetCollectionCancelled(session));
          await _refreshDashboard(
            emit,
            statusMessage: 'Previous session discarded.',
          );
        },
        onErr: (failure) async {
          _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
          emit(DatasetCollectionError(failure));
        },
      );
      return;
    }

    // Continue: if paused → resume; if recording → seed timer and keep recording.
    _logger.info(
      'Session Restored: ${candidate.id}',
      tag: 'DatasetCollectionBloc',
    );
    if (candidate.isPaused) {
      final result = await _resumeSession(const NoParams());
      await result.fold(
        onOk: (session) async {
          _timer.start(seed: session.duration);
          await _refreshDashboard(
            emit,
            keepActive: session,
            elapsed: session.duration,
            recordingPhase: DatasetSessionStatus.recording,
            statusMessage: 'Previous session resumed.',
          );
        },
        onErr: (failure) async {
          _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
          emit(DatasetCollectionError(failure));
        },
      );
    } else {
      _timer.start(seed: candidate.duration);
      await _refreshDashboard(
        emit,
        keepActive: candidate,
        elapsed: candidate.duration,
        recordingPhase: DatasetSessionStatus.recording,
        statusMessage: 'Previous session continued.',
      );
    }
  }

  Future<void> _onRename(
    DatasetCollectionRenameSession event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    final result = await _renameSession(event.params);
    await result.fold(
      onOk: (session) async {
        final previous = state.dashboardOrNull;
        final active = previous?.activeSession;
        await _refreshDashboard(
          emit,
          keepActive: active?.id == session.id ? session : active,
          elapsed: previous?.elapsed ?? _timer.elapsed,
          recordingPhase: (active?.id == session.id ? session : active)?.status,
          statusMessage: 'Renamed to “${session.sessionName}”.',
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
      },
    );
  }

  Future<void> _onDelete(
    DatasetCollectionDeleteSession event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    emit(const DatasetCollectionBusy(message: 'Deleting…'));
    final result = await _deleteSession(event.id);
    await result.fold(
      onOk: (_) async {
        _logger.info(
          'Session Deleted: ${event.id}',
          tag: 'DatasetCollectionBloc',
        );
        await _refreshDashboard(emit, statusMessage: 'Session deleted.');
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'DatasetCollectionBloc');
        emit(DatasetCollectionError(failure));
        await _refreshDashboard(emit);
      },
    );
  }

  Future<void> _onLoadStatistics(
    DatasetCollectionLoadStatistics event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    await _refreshDashboard(emit);
  }

  Future<void> _onRefreshStorage(
    DatasetCollectionRefreshStorage event,
    Emitter<DatasetCollectionState> emit,
  ) async {
    await _refreshDashboard(emit);
  }

  void _onTimerTicked(
    DatasetCollectionTimerTicked event,
    Emitter<DatasetCollectionState> emit,
  ) {
    final data = state.dashboardOrNull;
    if (data == null) return;
    if (state is! DatasetCollectionRecording &&
        state is! DatasetCollectionPaused) {
      return;
    }
    final next = data.copyWith(elapsed: event.elapsed);
    if (state is DatasetCollectionRecording) {
      emit(DatasetCollectionRecording(next));
    } else if (state is DatasetCollectionPaused) {
      emit(DatasetCollectionPaused(next));
    }
  }

  Future<void> _refreshDashboard(
    Emitter<DatasetCollectionState> emit, {
    String? statusMessage,
    String? loadingMessage,
    DatasetSession? keepActive,
    Duration? elapsed,
    DatasetSessionStatus? recordingPhase,
  }) async {
    if (loadingMessage != null) {
      emit(DatasetCollectionLoading(message: loadingMessage));
    }
    final snapshot = await _loadDashboardSnapshot();
    if (snapshot.failure != null) {
      emit(DatasetCollectionError(snapshot.failure!));
      return;
    }
    final data = snapshot.data!.copyWith(
      activeSession: keepActive,
      elapsed: elapsed ?? _timer.elapsed,
      statusMessage: statusMessage,
      clearActive: keepActive == null && recordingPhase == null,
      clearRestore: true,
    );

    final phase = recordingPhase ?? keepActive?.status;
    if (phase == DatasetSessionStatus.recording && keepActive != null) {
      emit(DatasetCollectionRecording(data.copyWith(activeSession: keepActive)));
      return;
    }
    if (phase == DatasetSessionStatus.paused && keepActive != null) {
      emit(DatasetCollectionPaused(data.copyWith(activeSession: keepActive)));
      return;
    }
    _emitIdleDashboard(emit, data.copyWith(clearActive: true));
  }

  void _emitIdleDashboard(
    Emitter<DatasetCollectionState> emit,
    DatasetCollectionDashboardData data,
  ) {
    if (data.sessions.isEmpty) {
      emit(DatasetCollectionEmpty(data));
    } else {
      emit(DatasetCollectionSessionsLoaded(data));
    }
  }

  Future<_DashboardLoadResult> _loadDashboardSnapshot() async {
    final sessionsResult = await _getSessions(const NoParams());
    final statsResult = await _getStatistics(const NoParams());
    final storageResult = await _getStorage(const NoParams());

    Failure? failure;
    List<DatasetSession>? sessions;
    DatasetStatistics? stats;
    DatasetStorage? storage;

    sessionsResult.fold(
      onOk: (v) => sessions = v,
      onErr: (f) => failure = f,
    );
    if (failure != null) {
      return _DashboardLoadResult.err(failure!);
    }

    statsResult.fold(
      onOk: (v) => stats = v,
      onErr: (f) => failure = f,
    );
    if (failure != null) {
      return _DashboardLoadResult.err(failure!);
    }

    storageResult.fold(
      onOk: (v) => storage = v,
      onErr: (f) => failure = f,
    );
    if (failure != null) {
      return _DashboardLoadResult.err(failure!);
    }

    return _DashboardLoadResult.ok(
      DatasetCollectionDashboardData(
        sessions: sessions!,
        statistics: stats!,
        storage: storage!,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _timerSub?.cancel();
    _timer.dispose();
    return super.close();
  }
}

class _DashboardLoadResult {
  final DatasetCollectionDashboardData? data;
  final Failure? failure;

  _DashboardLoadResult.ok(this.data) : failure = null;
  _DashboardLoadResult.err(this.failure) : data = null;
}
