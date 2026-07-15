import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/experiment_tracking_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExperimentTrackerSummaryCard extends StatelessWidget {
  final ExperimentTrackerSnapshot snapshot;

  const ExperimentTrackerSummaryCard({required this.snapshot, super.key});

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.latestRun;
    return AppSectionCard(
      title: 'Experiment tracker',
      subtitle:
          '${snapshot.totalCount} runs · ${snapshot.experimentNames.length} experiments',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Running', '${snapshot.runningCount}'),
            _kv(context, 'Completed', '${snapshot.completedCount}'),
            _kv(context, 'Failed', '${snapshot.failedCount}'),
            _kv(
              context,
              'Latest',
              latest?.displayName ?? '—',
            ),
          ],
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.labelSmall),
        Text(v, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class ExperimentRunListCard extends StatelessWidget {
  final List<ExperimentRun> runs;

  const ExperimentRunListCard({required this.runs, super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = [...runs]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return AppSectionCard(
      title: 'Runs',
      subtitle: 'Params · metrics · lifecycle',
      children: [
        if (sorted.isEmpty)
          const Text('No experiment runs yet')
        else
          for (final run in sorted) _RunTile(run: run),
      ],
    );
  }
}

class _RunTile extends StatelessWidget {
  final ExperimentRun run;

  const _RunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    final metricPreview = run.metrics.entries.take(3).map((e) {
      final v = e.value;
      final formatted =
          v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(3);
      return '${e.key}=$formatted';
    }).join(' · ');
    final paramPreview = run.params.entries
        .take(3)
        .map((e) => '${e.key}=${e.value}')
        .join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        switch (run.status) {
          ExperimentRunStatus.running => Icons.play_circle_outline,
          ExperimentRunStatus.completed => Icons.check_circle_outline,
          ExperimentRunStatus.failed => Icons.error_outline,
          ExperimentRunStatus.cancelled => Icons.cancel_outlined,
          ExperimentRunStatus.draft => Icons.edit_note_outlined,
        },
        color: switch (run.status) {
          ExperimentRunStatus.running => Colors.blue.shade700,
          ExperimentRunStatus.completed => Colors.green.shade700,
          ExperimentRunStatus.failed => Colors.red.shade700,
          _ => null,
        },
      ),
      title: Text(run.displayName),
      subtitle: Text(
        '${run.experimentName} · ${run.status.label}'
        '${run.modelId != null ? ' · ${run.modelId}' : ''}\n'
        '${paramPreview.isEmpty ? 'no params' : paramPreview}'
        '${metricPreview.isEmpty ? '' : '\n$metricPreview'}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          final bloc = context.read<ExperimentTrackingBloc>();
          switch (v) {
            case 'start':
              bloc.add(ExperimentTrackingStart(run.id));
            case 'metric':
              bloc.add(
                ExperimentTrackingLogMetric(
                  runId: run.id,
                  key: 'loss',
                  value: 0.25,
                  step: run.metricHistory.length + 1,
                ),
              );
            case 'complete':
              bloc.add(ExperimentTrackingComplete(run.id));
            case 'fail':
              bloc.add(ExperimentTrackingFail(run.id));
            case 'cancel':
              bloc.add(ExperimentTrackingCancel(run.id));
            case 'delete':
              bloc.add(ExperimentTrackingDelete(run.id));
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'start', child: Text('Start')),
          const PopupMenuItem(
            value: 'metric',
            child: Text('Log sample metric'),
          ),
          const PopupMenuItem(value: 'complete', child: Text('Complete')),
          const PopupMenuItem(value: 'fail', child: Text('Fail')),
          const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class ExperimentTrackingControls extends StatelessWidget {
  const ExperimentTrackingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Actions',
      subtitle: 'Create runs and attach params / metrics',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context
                  .read<ExperimentTrackingBloc>()
                  .add(const ExperimentTrackingRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: () => context.read<ExperimentTrackingBloc>().add(
                    ExperimentTrackingCreateDraft(
                      name:
                          'Draft · ${DateTime.now().toUtc().toIso8601String().substring(11, 19)}',
                      experimentName: 'road-detection',
                      modelId: 'bundled-yolov8n',
                      params: const {
                        'epochs': '5',
                        'batch_size': '4',
                        'lr': '0.001',
                      },
                    ),
                  ),
              icon: const Icon(Icons.add),
              label: const Text('New draft'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ExperimentTrackingBloc>()
                  .add(const ExperimentTrackingCreateDemo()),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Demo completed run'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Links to model registry ids (Phase 13.2). Benchmarks in 13.4 will '
          'consume completed run metrics.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
