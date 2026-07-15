import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_collection_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_storage_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/frame_capture_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/metadata_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_collection_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_storage_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/frame_capture_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/metadata_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dataset collection — Sessions · Acquisition · Metadata · Storage.
class DatasetCollectionPage extends StatelessWidget {
  /// Creates [DatasetCollectionPage].
  const DatasetCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<DatasetCollectionBloc>()
            ..add(const DatasetCollectionInitialize()),
        ),
        BlocProvider(create: (_) => sl<FrameCaptureBloc>()),
        BlocProvider(create: (_) => sl<MetadataBloc>()),
        BlocProvider(
          create: (_) => sl<DatasetStorageBloc>()
            ..add(const DatasetStorageCalculateStorage()),
        ),
      ],
      child: const RecordingDashboard(),
    );
  }
}

/// Recording dashboard shell.
class RecordingDashboard extends StatelessWidget {
  /// Creates [RecordingDashboard].
  const RecordingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset recording'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DatasetCollectionBloc>()
                .add(const DatasetCollectionLoadSessions()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<FrameCaptureBloc, FrameCaptureState>(
            listenWhen: (p, n) => n is FrameCaptureError,
            listener: (context, state) {
              if (state is FrameCaptureError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failure.message)),
                );
              }
            },
          ),
          BlocListener<MetadataBloc, MetadataState>(
            listenWhen: (p, n) =>
                n is MetadataError || n is MetadataGenerated,
            listener: (context, state) {
              if (state is MetadataError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failure.message)),
                );
                return;
              }
              if (state is MetadataGenerated) {
                // Persist synchronized metadata locally (Phase 12.5).
                context.read<DatasetStorageBloc>().add(
                      DatasetStorageSaveMetadata(state.metadata),
                    );
              }
            },
          ),
          BlocListener<DatasetStorageBloc, DatasetStorageState>(
            listenWhen: (p, n) =>
                n is DatasetStorageError ||
                n is DatasetStorageSaved ||
                (n is DatasetStorageCalculated && n.usage.isLowStorage),
            listener: (context, state) {
              if (state is DatasetStorageError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failure.message)),
                );
                return;
              }
              if (state is DatasetStorageCalculated &&
                  state.usage.isLowStorage &&
                  state.usage.warningMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.usage.warningMessage!)),
                );
              }
            },
          ),
        ],
        child: BlocConsumer<DatasetCollectionBloc, DatasetCollectionState>(
        listenWhen: (prev, next) {
          if (prev is DatasetCollectionRecording &&
              next is DatasetCollectionRecording) {
            return prev.data.activeSession?.id !=
                    next.data.activeSession?.id ||
                prev.data.activeSession?.status !=
                    next.data.activeSession?.status ||
                prev.data.statusMessage != next.data.statusMessage;
          }
          if (prev is DatasetCollectionPaused &&
              next is DatasetCollectionPaused) {
            return prev.data.activeSession?.id !=
                    next.data.activeSession?.id ||
                prev.data.statusMessage != next.data.statusMessage;
          }
          return next is DatasetCollectionRecording ||
              next is DatasetCollectionPaused ||
              next is DatasetCollectionStopped ||
              next is DatasetCollectionCancelled ||
              next is DatasetCollectionCompleted ||
              next is DatasetCollectionSessionsLoaded ||
              next is DatasetCollectionEmpty ||
              next is DatasetCollectionError ||
              next is DatasetCollectionRestorePrompt ||
              (next.dashboardOrNull?.statusMessage != null &&
                  next.dashboardOrNull?.statusMessage !=
                      prev.dashboardOrNull?.statusMessage);
        },
        listener: (context, state) async {
          _syncFrameCapture(context, state);

          final messenger = ScaffoldMessenger.of(context);

          if (state is DatasetCollectionRestorePrompt) {
            final candidate = state.data.restoreCandidate;
            if (candidate == null) return;
            final action = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Continue Previous Session?'),
                  content: Text(
                    'An unfinished session “${candidate.sessionName}” '
                    '(${candidate.status.label}) was found.\n\n'
                    'Resume to continue, or Discard to cancel it.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Discard'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Resume'),
                    ),
                  ],
                );
              },
            );
            if (!context.mounted) return;
            context.read<DatasetCollectionBloc>().add(
                  DatasetCollectionRestoreSession(
                    continueSession: action == true,
                  ),
                );
            return;
          }

          if (state is DatasetCollectionError) {
            messenger.showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
            return;
          }

          final message = switch (state) {
            DatasetCollectionStopped(:final session) =>
              'Stopped “${session.sessionName}”',
            DatasetCollectionCancelled(:final session) =>
              'Cancelled “${session.sessionName}”',
            DatasetCollectionCompleted(:final session) =>
              'Completed “${session.sessionName}”',
            _ => state.dashboardOrNull?.statusMessage,
          };
          if (message != null && message.isNotEmpty) {
            messenger.showSnackBar(SnackBar(content: Text(message)));
          }
        },
        buildWhen: (prev, next) =>
            next is DatasetCollectionInitial ||
            next is DatasetCollectionLoading ||
            next is DatasetCollectionBusy ||
            next is DatasetCollectionSessionsLoaded ||
            next is DatasetCollectionEmpty ||
            next is DatasetCollectionRecording ||
            next is DatasetCollectionPaused ||
            next is DatasetCollectionRestorePrompt ||
            next is DatasetCollectionError,
        builder: (context, state) {
          if (state is DatasetCollectionLoading ||
              state is DatasetCollectionInitial ||
              state is DatasetCollectionBusy) {
            final message = switch (state) {
              DatasetCollectionLoading(:final message) => message,
              DatasetCollectionBusy(:final message) => message,
              _ => 'Loading…',
            };
            return AppLoadingIndicator.page(message: message);
          }

          if (state is DatasetCollectionError) {
            return AppErrorView.fromFailure(
              state.failure,
              onRetry: () => context
                  .read<DatasetCollectionBloc>()
                  .add(const DatasetCollectionInitialize()),
            );
          }

          final data = state.dashboardOrNull;
          if (data == null) {
            return const AppLoadingIndicator.page(message: 'Loading…');
          }

          return _RecordingDashboardBody(data: data);
        },
      ),
      ),
    );
  }

  /// Keeps [FrameCaptureBloc] aligned with the recording session lifecycle.
  void _syncFrameCapture(
    BuildContext context,
    DatasetCollectionState state,
  ) {
    final capture = context.read<FrameCaptureBloc>();
    if (state is DatasetCollectionRecording) {
      final session = state.data.activeSession;
      if (session == null) return;
      final captureState = capture.state;
      if (captureState is FrameCapturePaused) {
        capture.add(const FrameCaptureResumeCapture());
      } else if (captureState is! FrameCaptureCapturing) {
        capture.add(
          FrameCaptureStartCapture(
            StartFrameCaptureParams(sessionId: session.id),
          ),
        );
      }
      return;
    }
    if (state is DatasetCollectionPaused) {
      if (capture.state is FrameCaptureCapturing) {
        capture.add(const FrameCapturePauseCapture());
      }
      return;
    }
    if (state is DatasetCollectionStopped ||
        state is DatasetCollectionCancelled ||
        state is DatasetCollectionCompleted ||
        state is DatasetCollectionSessionsLoaded ||
        state is DatasetCollectionEmpty) {
      if (capture.state is FrameCaptureCapturing ||
          capture.state is FrameCapturePaused) {
        capture.add(const FrameCaptureStopCapture());
      }
    }
  }
}

class _RecordingDashboardBody extends StatelessWidget {
  final DatasetCollectionDashboardData data;

  const _RecordingDashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final active = data.activeSession;
    final isRecording = active?.isRecording ?? false;
    final isPaused = active?.isPaused ?? false;
    final hasActive = active != null && active.status.isUnfinished;

    return AppPageContainer(
      child: ListView(
        children: [
          const DatasetSessionManagerBanner(),
          const SizedBox(height: AppSpacing.lg),
          RecordingControlsWidget(
            hasActiveSession: hasActive,
            isRecording: isRecording,
            isPaused: isPaused,
            onStart: () => _promptStart(context),
            onPause: () => context
                .read<DatasetCollectionBloc>()
                .add(const DatasetCollectionPauseRecording()),
            onResume: () => context
                .read<DatasetCollectionBloc>()
                .add(const DatasetCollectionResumeRecording()),
            onStop: () => _confirmStop(context),
            onCancel: () => _confirmCancel(context),
            onRename: active == null
                ? null
                : () => _promptRename(context, active),
          ),
          if (active != null && active.status.isUnfinished) ...[
            const SizedBox(height: AppSpacing.lg),
            SessionInformationCard(
              session: active,
              elapsed: data.elapsed,
            ),
            const SizedBox(height: AppSpacing.lg),
            const CaptureStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            const CaptureRateWidget(),
            const SizedBox(height: AppSpacing.lg),
            const QueueStatusWidget(),
            const SizedBox(height: AppSpacing.md),
            ManualCaptureButton(enabled: isRecording),
            const SizedBox(height: AppSpacing.lg),
            const SensorStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            const MetadataCard(),
            const SizedBox(height: AppSpacing.lg),
            const LiveMetadataViewer(),
          ],
          const SizedBox(height: AppSpacing.lg),
          DatasetStatisticsCard(statistics: data.statistics),
          const SizedBox(height: AppSpacing.lg),
          const StorageDashboard(),
          const SizedBox(height: AppSpacing.lg),
          DatasetStorageCard(
            storage: data.storage,
            onRefresh: () {
              context
                  .read<DatasetCollectionBloc>()
                  .add(const DatasetCollectionRefreshStorage());
              context
                  .read<DatasetStorageBloc>()
                  .add(const DatasetStorageCalculateStorage());
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.sessions.isEmpty)
            DatasetEmptyState(onCreateSession: () => _promptStart(context))
          else
            DatasetRecentSessionsList(
              sessions: data.sessions,
              onRename: (s) => _promptRename(context, s),
              onDelete: (s) => _confirmDelete(context, s),
            ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Future<void> _promptStart(BuildContext context) async {
    final bloc = context.read<DatasetCollectionBloc>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Start Recording'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Session name',
                  hintText: 'e.g. Morning Drive',
                ),
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session name cannot be empty.')),
          );
        }
      } else {
        bloc.add(
          DatasetCollectionStartRecording(
            CreateDatasetSessionParams(
              sessionName: name,
              description: descController.text,
            ),
          ),
        );
      }
    }
    nameController.dispose();
    descController.dispose();
  }

  Future<void> _promptRename(
    BuildContext context,
    DatasetSession session,
  ) async {
    final bloc = context.read<DatasetCollectionBloc>();
    final controller = TextEditingController(text: session.sessionName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename session'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Session name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      final name = controller.text.trim();
      if (name.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session name cannot be empty.')),
          );
        }
      } else {
        bloc.add(
          DatasetCollectionRenameSession(
            RenameDatasetSessionParams(
              id: session.id,
              sessionName: name,
            ),
          ),
        );
      }
    }
    controller.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DatasetSession session,
  ) async {
    if (session.status.isUnfinished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop or cancel the active session before deleting.'),
        ),
      );
      return;
    }
    final bloc = context.read<DatasetCollectionBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete session?'),
          content: Text(
            'Delete “${session.sessionName}”? This removes the session '
            'record (no frame files exist in this phase).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      bloc.add(DatasetCollectionDeleteSession(session.id));
    }
  }

  Future<void> _confirmStop(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Stop recording?'),
          content: const Text(
            'Stop will end this session and mark it as Stopped.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep recording'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context
          .read<DatasetCollectionBloc>()
          .add(const DatasetCollectionStopRecording());
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel recording?'),
          content: const Text(
            'Cancel will discard this unfinished session (status → Cancelled).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep recording'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel session'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context
          .read<DatasetCollectionBloc>()
          .add(const DatasetCollectionCancelRecording());
    }
  }
}
