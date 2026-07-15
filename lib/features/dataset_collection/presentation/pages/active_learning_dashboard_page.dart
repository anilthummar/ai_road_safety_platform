import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/active_learning_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/active_learning_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.5 Active learning — smart sample selection.
class ActiveLearningDashboardPage extends StatelessWidget {
  const ActiveLearningDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ActiveLearningBloc>()..add(const ActiveLearningLoad()),
      child: const _ActiveLearningView(),
    );
  }
}

class _ActiveLearningView extends StatelessWidget {
  const _ActiveLearningView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active learning'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ActiveLearningBloc>()
                .add(const ActiveLearningRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ActiveLearningBloc, ActiveLearningState>(
        listenWhen: (p, n) =>
            n is ActiveLearningError ||
            (n is ActiveLearningLoaded && n.statusMessage != null),
        listener: (context, state) {
          if (state is ActiveLearningError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is ActiveLearningLoaded &&
              state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ActiveLearningInitial() || ActiveLearningLoading() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (state is ActiveLearningLoading &&
                        state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(state.message!),
                    ],
                  ],
                ),
              ),
            ActiveLearningError(:final failure, :final snapshot) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppSectionCard(
                    title: 'Could not load selections',
                    subtitle: failure.message,
                    children: [
                      FilledButton(
                        onPressed: () => context
                            .read<ActiveLearningBloc>()
                            .add(const ActiveLearningLoad()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ActiveLearningSummaryCard(snapshot: snapshot),
                  ],
                ],
              ),
            ActiveLearningLoaded(:final snapshot) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ActiveLearningBloc>()
                      .add(const ActiveLearningRefresh());
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Phase 13.5 · smart sample selection',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const ActiveLearningControls(),
                    const SizedBox(height: AppSpacing.lg),
                    ActiveLearningSummaryCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.lg),
                    ActiveLearningSelectionListCard(
                      selections: snapshot.selections,
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
