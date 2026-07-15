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

/// Session explorer with search / filter / sort / infinite scroll.
class SessionExplorerPage extends StatelessWidget {
  /// Creates [SessionExplorerPage].
  const SessionExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DatasetExplorerBloc>()
        ..add(const DatasetExplorerLoadSessions()),
      child: const _SessionExplorerView(),
    );
  }
}

class _SessionExplorerView extends StatefulWidget {
  const _SessionExplorerView();

  @override
  State<_SessionExplorerView> createState() => _SessionExplorerViewState();
}

class _SessionExplorerViewState extends State<_SessionExplorerView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      context.read<DatasetExplorerBloc>().add(const DatasetExplorerLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DatasetExplorerBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session explorer'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: () => showFilterBottomSheet(
              context: context,
              current: bloc.currentQuery,
              onApply: ({
                required dateFilter,
                status,
                minStorageBytes,
                minFloodEvents,
              }) {
                bloc.add(
                  DatasetExplorerFilterSession(
                    dateFilter: dateFilter,
                    status: status,
                    minStorageBytes: minStorageBytes,
                    minFloodEvents: minFloodEvents,
                  ),
                );
              },
            ),
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: 'Sort',
            onPressed: () => showSortBottomSheet(
              context: context,
              current: bloc.currentQuery.sort,
              onApply: (sort) =>
                  bloc.add(DatasetExplorerSortSession(sort)),
            ),
            icon: const Icon(Icons.sort),
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
          return AppPageContainer(
            child: Column(
              children: [
                ExplorerSearchBar(
                  initialQuery: bloc.currentQuery.searchQuery,
                  onSearch: (q) =>
                      bloc.add(DatasetExplorerSearchSession(q)),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DatasetExplorerState state) {
    if (state is DatasetExplorerLoading || state is DatasetExplorerInitial) {
      return ExplorerLoadingState(
        message:
            state is DatasetExplorerLoading ? state.message : 'Loading…',
      );
    }
    if (state is DatasetExplorerEmpty) {
      return ExplorerEmptyState(
        onStartRecording: () =>
            context.push(RouteNames.datasetCollectionRecording),
      );
    }
    if (state is DatasetExplorerError) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load sessions',
        message: state.failure.message,
        actionLabel: 'Retry',
        onAction: () => context
            .read<DatasetExplorerBloc>()
            .add(const DatasetExplorerLoadSessions()),
      );
    }
    if (state is! DatasetExplorerSessionsLoaded) {
      return const SizedBox.shrink();
    }

    final sessions = state.accumulated;
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<DatasetExplorerBloc>()
            .add(const DatasetExplorerLoadSessions());
      },
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            '${state.page.totalCount} session(s)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          SessionGrid(
            sessions: sessions,
            onOpen: (s) => context.push(
              RouteNames.datasetCollectionSessionPath(s.id),
            ),
            onAction: (s, action) => _handleAction(context, s, action),
          ),
          if (state.page.hasMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    DatasetSession session,
    String action,
  ) async {
    final bloc = context.read<DatasetExplorerBloc>();
    switch (action) {
      case 'continue':
        context.push(RouteNames.datasetCollectionRecording);
      case 'details':
        context.push(RouteNames.datasetCollectionSessionPath(session.id));
      case 'rename':
        final name = await promptExplorerSessionRename(context, session);
        if (name == null || !context.mounted) return;
        bloc.add(
          DatasetExplorerRenameSession(
            RenameDatasetSessionParams(id: session.id, sessionName: name),
          ),
        );
      case 'duplicate':
        bloc.add(DatasetExplorerDuplicateSession(session.id));
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete session?'),
            content: Text(
              'Permanently remove "${session.sessionName}" and on-disk files.',
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
          ),
        );
        if (ok == true && context.mounted) {
          bloc.add(DatasetExplorerDeleteSession(session.id));
        }
      default:
        break;
    }
  }
}
