import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_explorer_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/dataset_explorer_page_helpers.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_collection_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_explorer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Session details + preview / AI stats / storage.
class SessionDetailsPage extends StatelessWidget {
  /// Session id from route.
  final String sessionId;

  /// Creates [SessionDetailsPage].
  const SessionDetailsPage({required this.sessionId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DatasetExplorerBloc>()
        ..add(DatasetExplorerOpenSession(sessionId)),
      child: _SessionDetailsView(sessionId: sessionId),
    );
  }
}

class _SessionDetailsView extends StatelessWidget {
  final String sessionId;

  const _SessionDetailsView({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DatasetExplorerBloc>()
                .add(DatasetExplorerOpenSession(sessionId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<DatasetExplorerBloc, DatasetExplorerState>(
        listenWhen: (p, n) =>
            n is DatasetExplorerError || n is DatasetExplorerEmpty,
        listener: (context, state) {
          if (state is DatasetExplorerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
            return;
          }
          if (state is DatasetExplorerEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session deleted')),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.datasetCollection);
            }
          }
        },
        builder: (context, state) {
          if (state is DatasetExplorerLoading ||
              state is DatasetExplorerInitial ||
              state is DatasetExplorerEmpty) {
            return ExplorerLoadingState(
              message: state is DatasetExplorerLoading
                  ? state.message
                  : 'Opening…',
            );
          }
          if (state is DatasetExplorerError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Session unavailable',
              message: state.failure.message,
              actionLabel: 'Retry',
              onAction: () => context
                  .read<DatasetExplorerBloc>()
                  .add(DatasetExplorerOpenSession(sessionId)),
            );
          }
          if (state is! DatasetExplorerSessionOpened) {
            return const SizedBox.shrink();
          }

          final d = state.details;
          final s = d.session;
          return AppPageContainer(
            child: ListView(
              children: [
                AppSectionCard(
                  title: s.sessionName,
                  subtitle: s.description.isEmpty
                      ? 'No description'
                      : s.description,
                  trailing: RecordingStatusBadge(status: s.status),
                  children: [
                    _row(context, 'Created', s.createdAt.toLocal().toString()),
                    _row(context, 'Started',
                        s.startedAt?.toLocal().toString() ?? '—'),
                    _row(context, 'Ended',
                        s.endedAt?.toLocal().toString() ?? '—'),
                    _row(
                      context,
                      'Duration',
                      formatExplorerDuration(s.duration),
                    ),
                    _row(context, 'Frames', '${s.frameCount}'),
                    _row(context, 'Flood events', '${s.floodEventCount}'),
                    _row(
                      context,
                      'Attributed storage',
                      formatExplorerBytes(s.totalStorage),
                    ),
                    _row(context, 'Disk folder', formatExplorerBytes(d.diskBytes)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionCard(
                  title: 'Session timeline',
                  children: [
                    Text(
                      'Created → ${s.startedAt == null ? 'not started' : 'recording'} '
                      '→ ${s.status.label}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Updated ${s.updatedAt.toLocal()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ExplorerMetadataCard(details: d),
                const SizedBox(height: AppSpacing.lg),
                AppSectionCard(
                  title: 'AI statistics',
                  children: [
                    _row(
                      context,
                      'Average confidence',
                      s.averageConfidence.toStringAsFixed(2),
                    ),
                    _row(
                      context,
                      'Average flood coverage',
                      '${s.averageFloodCoverage.toStringAsFixed(1)}%',
                    ),
                    _row(
                      context,
                      'Capture rate',
                      '${d.captureRateFpm.toStringAsFixed(1)} fpm',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionCard(
                  title: 'Preview images',
                  subtitle: 'Lazy thumbnails from local disk',
                  children: [
                    ThumbnailGrid(previews: d.previews),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (s.status.isUnfinished)
                      FilledButton.icon(
                        onPressed: () => context
                            .push(RouteNames.datasetCollectionRecording),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Continue session'),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: () => _rename(context, s),
                      icon: const Icon(Icons.drive_file_rename_outline),
                      label: const Text('Rename'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context
                          .read<DatasetExplorerBloc>()
                          .add(DatasetExplorerDuplicateSession(s.id)),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Duplicate'),
                    ),
                    if (!s.status.isUnfinished)
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<DatasetExplorerBloc>()
                            .add(DatasetExplorerDeleteSession(s.id)),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Export'),
                    ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Annotate'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, DatasetSession session) async {
    final name = await promptExplorerSessionRename(context, session);
    if (name == null || !context.mounted) return;
    context.read<DatasetExplorerBloc>().add(
          DatasetExplorerRenameSession(
            RenameDatasetSessionParams(id: session.id, sessionName: name),
          ),
        );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
