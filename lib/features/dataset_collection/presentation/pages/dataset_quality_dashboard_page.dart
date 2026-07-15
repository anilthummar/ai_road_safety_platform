import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_quality_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_quality_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.1 dataset quality assessment & training gate.
class DatasetQualityDashboardPage extends StatelessWidget {
  const DatasetQualityDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DatasetQualityBloc>()..add(const DatasetQualityLoad()),
      child: const _DatasetQualityView(),
    );
  }
}

class _DatasetQualityView extends StatelessWidget {
  const _DatasetQualityView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset quality gate'),
        actions: [
          IconButton(
            tooltip: 'Assess now',
            onPressed: () => context
                .read<DatasetQualityBloc>()
                .add(const DatasetQualityAssess()),
            icon: const Icon(Icons.fact_check_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DatasetQualityBloc>()
                .add(const DatasetQualityRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<DatasetQualityBloc, DatasetQualityState>(
        listenWhen: (p, n) => n is DatasetQualityError,
        listener: (context, state) {
          if (state is DatasetQualityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        builder: (context, state) {
          return AppPageContainer(
            child: switch (state) {
              DatasetQualityInitial() || DatasetQualityLoading() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state is DatasetQualityLoading
                            ? state.message
                            : 'Loading…',
                      ),
                    ],
                  ),
                ),
              DatasetQualityEmpty(:final thresholds, :final message) =>
                ListView(
                  children: [
                    AppSectionCard(
                      title: 'AI dataset quality assessment',
                      subtitle: 'Phase 13.1 · gate before training',
                      children: [
                        Text(message),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: () => context
                              .read<DatasetQualityBloc>()
                              .add(const DatasetQualityAssess()),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Run assessment'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QualityThresholdsCard(
                      thresholds: thresholds,
                      onChanged: (t) => context
                          .read<DatasetQualityBloc>()
                          .add(DatasetQualityUpdateThresholds(t)),
                    ),
                  ],
                ),
              DatasetQualityError(:final failure, :final report, :final thresholds) =>
                ListView(
                  children: [
                    AppSectionCard(
                      title: 'Assessment error',
                      children: [
                        Text(failure.message),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context
                              .read<DatasetQualityBloc>()
                              .add(const DatasetQualityAssess()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                    if (report != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      QualityGateStatusCard(report: report),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    QualityThresholdsCard(
                      thresholds: thresholds,
                      onChanged: (t) => context
                          .read<DatasetQualityBloc>()
                          .add(DatasetQualityUpdateThresholds(t)),
                    ),
                  ],
                ),
              DatasetQualityLoaded(:final report, :final thresholds) =>
                RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<DatasetQualityBloc>()
                        .add(const DatasetQualityRefresh());
                  },
                  child: ListView(
                    children: [
                      AppSectionCard(
                        title: 'AI dataset quality assessment',
                        subtitle:
                            'Composes capture (12.7) + ground truth (12.9)',
                        children: [
                          Text(
                            'Generated ${report.generatedAt.toLocal()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton.icon(
                            onPressed: () => context
                                .read<DatasetQualityBloc>()
                                .add(const DatasetQualityAssess()),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Re-run assessment'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      QualityGateStatusCard(report: report),
                      const SizedBox(height: AppSpacing.md),
                      QualityCorpusStatsCard(report: report),
                      const SizedBox(height: AppSpacing.md),
                      QualityDimensionScoresCard(
                        dimensions: report.dimensions,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      QualityIssuesCard(issues: report.issues),
                      const SizedBox(height: AppSpacing.md),
                      QualityLabelCoverageCard(
                        coverage: report.labelCoverage,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      QualitySessionTableCard(sessions: report.sessions),
                      const SizedBox(height: AppSpacing.md),
                      QualityThresholdsCard(
                        thresholds: thresholds,
                        onChanged: (t) => context
                            .read<DatasetQualityBloc>()
                            .add(DatasetQualityUpdateThresholds(t)),
                      ),
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
