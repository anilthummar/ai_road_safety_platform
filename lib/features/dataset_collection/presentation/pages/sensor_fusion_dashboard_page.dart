import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/sensor_fusion_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/sensor_fusion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 13.7 Sensor fusion — Camera + GPS + IMU (+ sonar later).
class SensorFusionDashboardPage extends StatelessWidget {
  const SensorFusionDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SensorFusionBloc>()..add(const SensorFusionLoad()),
      child: const _SensorFusionView(),
    );
  }
}

class _SensorFusionView extends StatelessWidget {
  const _SensorFusionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor fusion'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<SensorFusionBloc>()
                .add(const SensorFusionRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<SensorFusionBloc, SensorFusionState>(
        listenWhen: (p, n) =>
            n is SensorFusionError ||
            (n is SensorFusionLoaded && n.statusMessage != null),
        listener: (context, state) {
          if (state is SensorFusionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is SensorFusionLoaded &&
              state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.statusMessage!)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            SensorFusionInitial() || SensorFusionLoading() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (state is SensorFusionLoading &&
                        state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(state.message!),
                    ],
                  ],
                ),
              ),
            SensorFusionError(:final failure, :final snapshot) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppSectionCard(
                    title: 'Could not load fusion',
                    subtitle: failure.message,
                    children: [
                      FilledButton(
                        onPressed: () => context
                            .read<SensorFusionBloc>()
                            .add(const SensorFusionLoad()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SensorFusionSummaryCard(snapshot: snapshot),
                  ],
                ],
              ),
            SensorFusionLoaded(:final snapshot) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<SensorFusionBloc>()
                      .add(const SensorFusionRefresh());
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Phase 13.7 · camera + GPS + IMU (+ sonar later)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SensorFusionControls(),
                    const SizedBox(height: AppSpacing.lg),
                    SensorFusionSummaryCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.lg),
                    FusionChannelHealthCard(channels: snapshot.channels),
                    const SizedBox(height: AppSpacing.lg),
                    FusedSampleListCard(samples: snapshot.recentSamples),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
