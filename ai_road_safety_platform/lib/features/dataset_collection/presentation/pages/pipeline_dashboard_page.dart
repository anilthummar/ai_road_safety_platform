import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/pipeline_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/pipeline_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 12.10 background pipeline & edge compute monitor.
class PipelineDashboardPage extends StatelessWidget {
  const PipelineDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PipelineBloc>()..add(const PipelineRefreshMonitor()),
      child: const _PipelineDashboardView(),
    );
  }
}

class _PipelineDashboardView extends StatelessWidget {
  const _PipelineDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline engine'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<PipelineBloc>()
                .add(const PipelineRefreshMonitor()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<PipelineBloc, PipelineState>(
        listenWhen: (p, n) => n is PipelineFailure,
        listener: (context, state) {
          if (state is PipelineFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        builder: (context, state) {
          final monitor = switch (state) {
            PipelineRunning(:final monitor) => monitor,
            PipelinePausedState(:final monitor) => monitor,
            PipelineStoppedState(:final monitor) => monitor,
            PipelineTaskExecuting(:final monitor) => monitor,
            PipelineTaskCompletedState(:final monitor) => monitor,
            PipelineFailure(:final monitor) =>
              monitor ?? PipelineMonitorSnapshot.idle(),
            _ => PipelineMonitorSnapshot.idle(),
          };
          final history = switch (state) {
            PipelineRunning(:final history) => history,
            PipelinePausedState(:final history) => history,
            PipelineStoppedState(:final history) => history,
            PipelineTaskExecuting(:final history) => history,
            PipelineTaskCompletedState(:final history) => history,
            PipelineFailure(:final history) => history,
            _ => const <PipelineTask>[],
          };

          return AppPageContainer(
            child: ListView(
              children: [
                AppSectionCard(
                  title: 'Edge processing engine',
                  subtitle:
                      'Phase 12.10 · queue · pipeline · worker pool (inline)',
                  children: [
                    Text(
                      'Coordinates long-running dataset work without blocking '
                      'the camera preview. Stages are independent; isolates '
                      'can replace inline workers later.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (state is PipelineTaskExecuting) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const LinearProgressIndicator(),
                      Text('Executing ${state.task.name}…'),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PipelineControls(status: monitor.status),
                const SizedBox(height: AppSpacing.md),
                PipelineStatusCard(monitor: monitor),
                const SizedBox(height: AppSpacing.md),
                ProcessingStatistics(monitor: monitor),
                const SizedBox(height: AppSpacing.md),
                QueueMonitorCard(monitor: monitor),
                const SizedBox(height: AppSpacing.md),
                RetryQueueCard(monitor: monitor),
                const SizedBox(height: AppSpacing.md),
                WorkerStatusCard(monitor: monitor),
                const SizedBox(height: AppSpacing.md),
                TaskHistoryCard(
                  history: history,
                  onRetry: (id) => context
                      .read<PipelineBloc>()
                      .add(PipelineTaskRetryRequested(id)),
                  onCancel: (id) => context
                      .read<PipelineBloc>()
                      .add(PipelineTaskCancelRequested(id)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
