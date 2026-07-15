import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/history/presentation/bloc/history_bloc.dart';
import 'package:ai_road_safety_platform/features/history/presentation/widgets/history_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// History tab — Hive DB list with search, filters, delete, JSON export.
class HistoryPage extends StatelessWidget {
  /// Creates [HistoryPage].
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HistoryBloc>()..add(const HistoryStarted()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is! HistoryLoaded) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isSelecting) ...[
                    IconButton(
                      tooltip: 'Delete selected',
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => _confirmDeleteSelected(context, state),
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      icon: const Icon(Icons.close),
                      onPressed: () => context
                          .read<HistoryBloc>()
                          .add(const HistorySelectionCleared()),
                    ),
                  ] else ...[
                    IconButton(
                      tooltip: 'Export JSON',
                      icon: const Icon(Icons.ios_share_outlined),
                      onPressed: () => context
                          .read<HistoryBloc>()
                          .add(const HistoryExportRequested()),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'clear') {
                          _confirmClearAll(context);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'clear',
                          child: Text('Clear all history'),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listenWhen: (previous, current) {
          if (current is! HistoryLoaded || current.statusMessage == null) {
            return false;
          }
          if (previous is! HistoryLoaded) return true;
          return previous.statusMessage != current.statusMessage;
        },
        listener: (context, state) {
          if (state is HistoryLoaded && state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            HistoryInitial() => const AppLoadingIndicator.page(
                message: 'Loading history…',
              ),
            HistoryLoading(:final message) => AppLoadingIndicator.page(
                message: message,
              ),
            HistoryError(:final failure) => AppErrorView.fromFailure(
                failure,
                onRetry: () =>
                    context.read<HistoryBloc>().add(const HistoryStarted()),
              ),
            HistoryLoaded() => AppPageContainer(
                child: _HistoryLoadedBody(state: state),
              ),
          };
        },
      ),
    );
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    HistoryLoaded state,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text(
          'Delete ${state.selectedIds.length} record(s) and their images?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<HistoryBloc>().add(
            HistoryDeleteSelectedRequested(state.selectedIds.toList()),
          );
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This permanently deletes all Hive records and saved images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<HistoryBloc>().add(const HistoryClearAllRequested());
    }
  }
}

class _HistoryLoadedBody extends StatelessWidget {
  const _HistoryLoadedBody({required this.state});

  final HistoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HistoryBloc>();

    // Fix pattern for Initial || Loading with message - History page has same issue
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistorySearchBar(
          query: state.filter.searchQuery,
          onChanged: (q) => bloc.add(HistorySearchChanged(q)),
        ),
        const SizedBox(height: AppSpacing.md),
        HistoryFilterBar(
          filter: state.filter,
          onRiskToggle: (level) => bloc.add(HistoryRiskFilterToggled(level)),
          onImagesOnlyToggle: () =>
              bloc.add(const HistoryImagesOnlyToggled()),
          onMinFloodChanged: (v) => bloc.add(HistoryMinFloodChanged(v)),
          onClear: () => bloc.add(const HistoryFiltersCleared()),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${state.visibleRecords.length} of ${state.allRecords.length} records',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: state.visibleRecords.isEmpty
              ? AppEmptyState(
                  icon: Icons.history_outlined,
                  title: state.allRecords.isEmpty
                      ? 'No history yet'
                      : 'No matching records',
                  message: state.allRecords.isEmpty
                      ? 'Save a snapshot from the Driver Dashboard to store flood %, risk, GPS, image, and timestamp in Hive.'
                      : 'Try clearing search or filters.',
                )
              : ListView.separated(
                  itemCount: state.visibleRecords.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final record = state.visibleRecords[index];
                    final selected = state.selectedIds.contains(record.id);
                    return HistoryRecordTile(
                      record: record,
                      selected: selected,
                      onTap: () =>
                          bloc.add(HistorySelectionToggled(record.id)),
                      onLongPress: () =>
                          bloc.add(HistorySelectionToggled(record.id)),
                      onDelete: state.isSelecting
                          ? null
                          : () => _confirmDeleteOne(context, record),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteOne(
    BuildContext context,
    HistoryRecord record,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('Remove this entry and its image from Hive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<HistoryBloc>().add(HistoryDeleteRequested(record.id));
    }
  }
}
