import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_deployment_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/model_deployment_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.6 Model deployment manager — edge package / rollback.
class ModelDeploymentDashboardPage extends StatelessWidget {
  const ModelDeploymentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ModelDeploymentBloc>()..add(const ModelDeploymentLoad()),
      child: const _ModelDeploymentView(),
    );
  }
}

class _ModelDeploymentView extends StatelessWidget {
  const _ModelDeploymentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deployment manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ModelDeploymentBloc>()
                .add(const ModelDeploymentRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ModelDeploymentBloc, ModelDeploymentState>(
        listenWhen: (p, n) =>
            n is ModelDeploymentError ||
            (n is ModelDeploymentLoaded && n.statusMessage != null),
        listener: (context, state) {
          if (state is ModelDeploymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is ModelDeploymentLoaded &&
              state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ModelDeploymentInitial() || ModelDeploymentLoading() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (state is ModelDeploymentLoading &&
                        state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(state.message!),
                    ],
                  ],
                ),
              ),
            ModelDeploymentError(:final failure, :final snapshot) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppSectionCard(
                    title: 'Could not load deployments',
                    subtitle: failure.message,
                    children: [
                      FilledButton(
                        onPressed: () => context
                            .read<ModelDeploymentBloc>()
                            .add(const ModelDeploymentLoad()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    DeploymentSummaryCard(snapshot: snapshot),
                  ],
                ],
              ),
            ModelDeploymentLoaded(:final snapshot) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ModelDeploymentBloc>()
                      .add(const ModelDeploymentRefresh());
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Phase 13.6 · edge package · rollback',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const DeploymentControls(),
                    const SizedBox(height: AppSpacing.lg),
                    DeploymentSummaryCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.lg),
                    DeploymentPackageListCard(
                      packages: snapshot.packages,
                      active: snapshot.active,
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
