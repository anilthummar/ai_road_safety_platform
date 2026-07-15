import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/pipeline_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PipelineStatusCard extends StatelessWidget {
  final PipelineMonitorSnapshot monitor;

  const PipelineStatusCard({required this.monitor, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Pipeline status',
      subtitle: monitor.status.label,
      children: [
        Text('Current stage: ${monitor.currentStage?.label ?? '—'}'),
        Text('Active workers: ${monitor.activeWorkers}'),
        Text(
          'Updated ${monitor.updatedAt.toLocal().toString().split('.').first}',
        ),
      ],
    );
  }
}

class QueueMonitorCard extends StatelessWidget {
  final PipelineMonitorSnapshot monitor;

  const QueueMonitorCard({required this.monitor, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Queue monitor',
      subtitle: 'Ready ${monitor.queueLength} · Retry ${monitor.retryQueueLength}',
      children: [
        if (monitor.queues.isEmpty)
          const Text('No queues')
        else
          for (final q in monitor.queues) ...[
            Text('${q.name}: ${q.length}/${q.capacity}'),
            LinearProgressIndicator(
              value: q.fillRatio.clamp(0.0, 1.0),
            ),
            Text(
              'Enqueued ${q.enqueuedTotal} · Dequeued ${q.dequeuedTotal} · '
              'Overflow ${q.overflowCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class ProcessingStatistics extends StatelessWidget {
  final PipelineMonitorSnapshot monitor;

  const ProcessingStatistics({required this.monitor, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Processing statistics',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            _StatChip(
              label: 'Completed',
              value: '${monitor.completedTasks}',
            ),
            _StatChip(label: 'Failed', value: '${monitor.failedTasks}'),
            _StatChip(label: 'Retries', value: '${monitor.retryCount}'),
            _StatChip(
              label: 'Speed',
              value: '${monitor.processingSpeedPerSec.toStringAsFixed(1)}/s',
            ),
            _StatChip(
              label: 'Avg time',
              value: '${monitor.averageTaskTime.inMilliseconds} ms',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class WorkerStatusCard extends StatelessWidget {
  final PipelineMonitorSnapshot monitor;

  const WorkerStatusCard({required this.monitor, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Worker pool',
      subtitle: 'Inline workers · isolate-ready boundary',
      children: [
        Text('Busy workers: ${monitor.activeWorkers}'),
        Text(
          'Architecture prepared for Image compression · AI inference · '
          'Sensor fusion without UI jank.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class RetryQueueCard extends StatelessWidget {
  final PipelineMonitorSnapshot monitor;

  const RetryQueueCard({required this.monitor, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Retry queue',
      subtitle: '${monitor.retryQueueLength} waiting · ${monitor.retryCount} triggered',
      children: [
        Text(
          'Exponential backoff prevents infinite retry storms. '
          'Failed stages can be recovered from controls.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class TaskHistoryCard extends StatelessWidget {
  final List<PipelineTask> history;
  final ValueChanged<String>? onRetry;
  final ValueChanged<String>? onCancel;

  const TaskHistoryCard({
    required this.history,
    this.onRetry,
    this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final recent = history.take(12).toList();
    return AppSectionCard(
      title: 'Task history',
      subtitle: '${history.length} events',
      children: [
        if (recent.isEmpty)
          const Text('No tasks yet')
        else
          for (final t in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(t.name),
              subtitle: Text(
                '${t.stage.label} · ${t.status.label} · '
                'attempt ${t.attempt}'
                '${t.errorMessage != null ? ' · ${t.errorMessage}' : ''}',
              ),
              trailing: Wrap(
                children: [
                  if (t.status == TaskStatus.failed && onRetry != null)
                    IconButton(
                      tooltip: 'Retry',
                      onPressed: () => onRetry!(t.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  if ((t.status == TaskStatus.pending ||
                          t.status == TaskStatus.retrying) &&
                      onCancel != null)
                    IconButton(
                      tooltip: 'Cancel',
                      onPressed: () => onCancel!(t.id),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class PipelineControls extends StatelessWidget {
  final PipelineStatus status;

  const PipelineControls({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final running = status == PipelineStatus.running ||
        status == PipelineStatus.recovering;
    final paused = status == PipelineStatus.paused;

    return AppSectionCard(
      title: 'Pipeline controls',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: running
                  ? null
                  : () => context
                      .read<PipelineBloc>()
                      .add(const PipelineStarted()),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
            FilledButton.tonalIcon(
              onPressed: running
                  ? () => context
                      .read<PipelineBloc>()
                      .add(const PipelinePaused())
                  : null,
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
            ),
            FilledButton.tonalIcon(
              onPressed: paused
                  ? () => context
                      .read<PipelineBloc>()
                      .add(const PipelineResumed())
                  : null,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Resume'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<PipelineBloc>()
                  .add(const PipelineStopped()),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<PipelineBloc>()
                  .add(const PipelineRestarted()),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<PipelineBloc>()
                  .add(const PipelineRecoverFailed()),
              icon: const Icon(Icons.healing_outlined),
              label: const Text('Recover'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Enqueue demo work', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final stage in [
              PipelineStageKind.frameAcquisition,
              PipelineStageKind.metadata,
              PipelineStageKind.storage,
              PipelineStageKind.analytics,
            ])
              ActionChip(
                label: Text(stage.label),
                onPressed: () => context.read<PipelineBloc>().add(
                      PipelineEnqueueDemoTask(stage: stage),
                    ),
              ),
            ActionChip(
              label: const Text('Fail + retry'),
              onPressed: () => context.read<PipelineBloc>().add(
                    const PipelineEnqueueDemoTask(
                      stage: PipelineStageKind.datasetValidation,
                      forceFail: true,
                      priority: TaskPriority.high,
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
