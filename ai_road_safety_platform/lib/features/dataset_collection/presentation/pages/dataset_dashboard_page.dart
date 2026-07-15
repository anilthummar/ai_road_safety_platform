import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_explorer_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/dataset_explorer_page_helpers.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_explorer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Phase 12.6 research dashboard — central workspace before annotation.
class DatasetDashboardPage extends StatelessWidget {
  /// Creates [DatasetDashboardPage].
  const DatasetDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DatasetExplorerBloc>()
        ..add(const DatasetExplorerLoadDashboard()),
      child: const _DatasetDashboardView(),
    );
  }
}

class _DatasetDashboardView extends StatelessWidget {
  const _DatasetDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DatasetExplorerBloc>()
                .add(const DatasetExplorerRefreshDashboard()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<DatasetExplorerBloc, DatasetExplorerState>(
        listenWhen: (p, n) => n is DatasetExplorerError,
        listener: (context, state) {
          if (state is DatasetExplorerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is DatasetExplorerLoading ||
              state is DatasetExplorerInitial) {
            return ExplorerLoadingState(
              message: state is DatasetExplorerLoading
                  ? state.message
                  : 'Loading dashboard…',
            );
          }
          if (state is DatasetExplorerError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Dashboard unavailable',
              message: state.failure.message,
              actionLabel: 'Retry',
              onAction: () => context
                  .read<DatasetExplorerBloc>()
                  .add(const DatasetExplorerLoadDashboard()),
            );
          }

          final data = switch (state) {
            DatasetExplorerDashboardLoaded(:final data) => data,
            DatasetExplorerEmpty(:final dashboard) => dashboard,
            _ => null,
          };

          if (data == null) {
            return ExplorerEmptyState(
              onStartRecording: () =>
                  context.push(RouteNames.datasetCollectionRecording),
            );
          }

          return AppPageContainer(
            child: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<DatasetExplorerBloc>()
                    .add(const DatasetExplorerRefreshDashboard());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DashboardHeader(
                    data: data,
                    onContinueRecording: () =>
                        context.push(RouteNames.datasetCollectionRecording),
                    onBrowseSessions: () =>
                        context.push(RouteNames.datasetCollectionSessions),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StatisticsCards(data: data),
                  const SizedBox(height: AppSpacing.lg),
                  ExplorerStorageCard(
                    diskUsage: data.diskUsage,
                    collectionStorage: data.collectionStorage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionCard(
                    title: 'Recent sessions',
                    subtitle: data.recentSessions.isEmpty
                        ? 'None yet'
                        : '${data.recentSessions.length} latest',
                    trailing: TextButton(
                      onPressed: () =>
                          context.push(RouteNames.datasetCollectionSessions),
                      child: const Text('Browse all'),
                    ),
                    children: [
                      if (data.recentSessions.isEmpty)
                        const Text('Start a recording to populate the corpus.')
                      else
                        for (final s in data.recentSessions) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.sessionName),
                            subtitle: Text(
                              '${s.status.label} · ${s.frameCount} frames · '
                              '${s.createdAt.toLocal().toString().split('.').first}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              RouteNames.datasetCollectionSessionPath(s.id),
                            ),
                            onLongPress: () => _sessionActions(context, s),
                          ),
                        ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionCard(
                    title: 'Quick actions',
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionRecording),
                            icon: const Icon(Icons.fiber_manual_record),
                            label: const Text('Record'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionSessions),
                            icon: const Icon(Icons.search),
                            label: const Text('Explore'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionAnalytics),
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Analytics'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionExport),
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Export'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionAnnotate),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('Annotate'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionPipeline),
                            icon: const Icon(Icons.account_tree_outlined),
                            label: const Text('Pipeline'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionQuality),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Quality'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionModels),
                            icon: const Icon(Icons.memory_outlined),
                            label: const Text('Models'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionExperiments),
                            icon: const Icon(Icons.science_outlined),
                            label: const Text('Experiments'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionBenchmark),
                            icon: const Icon(Icons.speed_outlined),
                            label: const Text('Benchmark'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              RouteNames.datasetCollectionActiveLearning,
                            ),
                            icon: const Icon(Icons.psychology_outlined),
                            label: const Text('Active learning'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context
                                .push(RouteNames.datasetCollectionDeploy),
                            icon: const Icon(Icons.rocket_launch_outlined),
                            label: const Text('Deploy'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              RouteNames.datasetCollectionSensorFusion,
                            ),
                            icon: const Icon(Icons.merge_type),
                            label: const Text('Fusion'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sessionActions(
    BuildContext context,
    DatasetSession session,
  ) async {
    final bloc = context.read<DatasetExplorerBloc>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(session.sessionName),
                subtitle: const Text('Quick actions'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View details'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    RouteNames.datasetCollectionSessionPath(session.id),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('Rename'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final name = await promptExplorerSessionRename(context, session);
                  if (name == null || !context.mounted) return;
                  bloc.add(
                    DatasetExplorerRenameSession(
                      RenameDatasetSessionParams(
                        id: session.id,
                        sessionName: name,
                      ),
                    ),
                  );
                },
              ),
              if (!session.status.isUnfinished)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(ctx);
                    bloc.add(DatasetExplorerDeleteSession(session.id));
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
