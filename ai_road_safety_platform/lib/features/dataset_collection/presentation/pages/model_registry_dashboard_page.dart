import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_registry_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/model_registry_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.2 AI model management — versions, artifacts, metadata.
class ModelRegistryDashboardPage extends StatelessWidget {
  const ModelRegistryDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ModelRegistryBloc>()..add(const ModelRegistryLoad()),
      child: const _ModelRegistryView(),
    );
  }
}

class _ModelRegistryView extends StatelessWidget {
  const _ModelRegistryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ModelRegistryBloc>()
                .add(const ModelRegistryRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ModelRegistryBloc, ModelRegistryState>(
        listenWhen: (p, n) =>
            n is ModelRegistryError ||
            (n is ModelRegistryLoaded && n.statusMessage != null),
        listener: (context, state) {
          if (state is ModelRegistryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is ModelRegistryLoaded &&
              state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return AppPageContainer(
            child: switch (state) {
              ModelRegistryInitial() || ModelRegistryLoading() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state is ModelRegistryLoading
                            ? state.message
                            : 'Loading…',
                      ),
                    ],
                  ),
                ),
              ModelRegistryError(:final failure, :final snapshot) => ListView(
                  children: [
                    AppSectionCard(
                      title: 'Registry error',
                      children: [
                        Text(failure.message),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context
                              .read<ModelRegistryBloc>()
                              .add(const ModelRegistryLoad()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                    if (snapshot != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ModelRegistrySummaryCard(snapshot: snapshot),
                    ],
                  ],
                ),
              ModelRegistryLoaded(:final snapshot) => RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<ModelRegistryBloc>()
                        .add(const ModelRegistryRefresh());
                  },
                  child: ListView(
                    children: [
                      AppSectionCard(
                        title: 'AI model management',
                        subtitle:
                            'Phase 13.2 · versions · artifacts · metadata',
                        children: [
                          Text(
                            'Track local and bundled TFLite models. Activation '
                            'updates task-family pointers for future deployment.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const ModelRegistryControls(),
                      const SizedBox(height: AppSpacing.md),
                      ModelRegistrySummaryCard(snapshot: snapshot),
                      const SizedBox(height: AppSpacing.md),
                      ModelListCard(
                        models: snapshot.models,
                        active: snapshot.active,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final m in snapshot.models.take(4)) ...[
                        ModelDetailCard(model: m),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
            },
          );
        },
      ),
    );
  }
}
