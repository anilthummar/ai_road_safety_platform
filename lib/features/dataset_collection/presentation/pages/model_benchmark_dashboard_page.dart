import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_benchmark_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/model_benchmark_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.4 Model benchmark — offline scoring vs ground truth.
class ModelBenchmarkDashboardPage extends StatelessWidget {
  const ModelBenchmarkDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ModelBenchmarkBloc>()..add(const ModelBenchmarkLoad()),
      child: const _ModelBenchmarkView(),
    );
  }
}

class _ModelBenchmarkView extends StatelessWidget {
  const _ModelBenchmarkView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model benchmark'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ModelBenchmarkBloc>()
                .add(const ModelBenchmarkRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ModelBenchmarkBloc, ModelBenchmarkState>(
        listenWhen: (p, n) =>
            n is ModelBenchmarkError ||
            (n is ModelBenchmarkLoaded && n.statusMessage != null),
        listener: (context, state) {
          if (state is ModelBenchmarkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is ModelBenchmarkLoaded &&
              state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ModelBenchmarkInitial() || ModelBenchmarkLoading() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (state is ModelBenchmarkLoading &&
                        state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(state.message!),
                    ],
                  ],
                ),
              ),
            ModelBenchmarkError(:final failure, :final snapshot) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppSectionCard(
                    title: 'Could not load benchmarks',
                    subtitle: failure.message,
                    children: [
                      FilledButton(
                        onPressed: () => context
                            .read<ModelBenchmarkBloc>()
                            .add(const ModelBenchmarkLoad()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    BenchmarkSummaryCard(snapshot: snapshot),
                  ],
                ],
              ),
            ModelBenchmarkLoaded(:final snapshot) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ModelBenchmarkBloc>()
                      .add(const ModelBenchmarkRefresh());
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Phase 13.4 · offline scoring vs GT',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const BenchmarkControls(),
                    const SizedBox(height: AppSpacing.lg),
                    BenchmarkSummaryCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.lg),
                    BenchmarkReportListCard(reports: snapshot.reports),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
