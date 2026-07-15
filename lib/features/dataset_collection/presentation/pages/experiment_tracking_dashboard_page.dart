import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/experiment_tracking_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/experiment_tracking_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.3 AI experiment tracking — runs, params, metrics.
class ExperimentTrackingDashboardPage extends StatelessWidget {
  const ExperimentTrackingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ExperimentTrackingBloc>()..add(const ExperimentTrackingLoad()),
      child: const _ExperimentTrackingView(),
    );
  }
}

class _ExperimentTrackingView extends StatelessWidget {
  const _ExperimentTrackingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment tracking'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ExperimentTrackingBloc>()
                .add(const ExperimentTrackingRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ExperimentTrackingBloc, ExperimentTrackingState>(
        listenWhen: (p, n) =>
            n is ExperimentTrackingError ||
            (n is ExperimentTrackingLoaded && n.statusMessage != null),
        listener: (context, state) {
          if (state is ExperimentTrackingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is ExperimentTrackingLoaded &&
              state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ExperimentTrackingInitial() || ExperimentTrackingLoading() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (state is ExperimentTrackingLoading &&
                        state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(state.message!),
                    ],
                  ],
                ),
              ),
            ExperimentTrackingError(:final failure, :final snapshot) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppSectionCard(
                    title: 'Could not load experiments',
                    subtitle: failure.message,
                    children: [
                      FilledButton(
                        onPressed: () => context
                            .read<ExperimentTrackingBloc>()
                            .add(const ExperimentTrackingLoad()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ExperimentTrackerSummaryCard(snapshot: snapshot),
                  ],
                ],
              ),
            ExperimentTrackingLoaded(:final snapshot) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ExperimentTrackingBloc>()
                      .add(const ExperimentTrackingRefresh());
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Phase 13.3 · runs · params · metrics',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const ExperimentTrackingControls(),
                    const SizedBox(height: AppSpacing.lg),
                    ExperimentTrackerSummaryCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.lg),
                    ExperimentRunListCard(runs: snapshot.runs),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
