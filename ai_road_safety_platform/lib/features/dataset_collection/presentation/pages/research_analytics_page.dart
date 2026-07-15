import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_analytics_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_analytics_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Phase 12.7 research analytics & dataset intelligence workspace.
class ResearchAnalyticsPage extends StatelessWidget {
  /// Creates [ResearchAnalyticsPage].
  const ResearchAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DatasetAnalyticsBloc>()
        ..add(const DatasetAnalyticsLoad()),
      child: const _ResearchAnalyticsView(),
    );
  }
}

class _ResearchAnalyticsView extends StatelessWidget {
  const _ResearchAnalyticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DatasetAnalyticsBloc>()
                .add(const DatasetAnalyticsRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<DatasetAnalyticsBloc, DatasetAnalyticsState>(
        listenWhen: (p, n) => n is DatasetAnalyticsError,
        listener: (context, state) {
          if (state is DatasetAnalyticsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<DatasetAnalyticsBloc>();
          return AppPageContainer(
            child: Column(
              children: [
                AnalyticsFilterBar(
                  filter: bloc.currentFilter,
                  onChanged: (f) =>
                      bloc.add(DatasetAnalyticsFilter(f)),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _body(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, DatasetAnalyticsState state) {
    if (state is DatasetAnalyticsInitial) {
      return const AnalyticsLoadingState();
    }
    if (state is DatasetAnalyticsLoading) {
      return AnalyticsLoadingState(message: state.message);
    }
    if (state is DatasetAnalyticsEmpty) {
      return AnalyticsEmptyState(
        onOpenDashboard: () => context.go(RouteNames.datasetCollection),
      );
    }
    if (state is DatasetAnalyticsError) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Analytics unavailable',
        message: state.failure.message,
        actionLabel: 'Retry',
        onAction: () => context
            .read<DatasetAnalyticsBloc>()
            .add(const DatasetAnalyticsLoad()),
      );
    }
    if (state is DatasetAnalyticsLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context
              .read<DatasetAnalyticsBloc>()
              .add(const DatasetAnalyticsRefresh());
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            BlocSelector<DatasetAnalyticsBloc, DatasetAnalyticsState,
                DatasetAnalyticsReport?>(
              selector: (s) => s is DatasetAnalyticsLoaded ? s.report : null,
              builder: (context, selected) {
                if (selected == null) return const SizedBox.shrink();
                return AnalyticsDashboard(
                  report: selected,
                  onOpenSession: (id) => context.push(
                    RouteNames.datasetCollectionSessionPath(id),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
