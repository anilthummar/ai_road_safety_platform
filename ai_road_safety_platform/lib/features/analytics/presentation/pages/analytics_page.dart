import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/widgets/analytics_charts.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/widgets/analytics_stats_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Professional analytics dashboard — KPIs + weekly/monthly/yearly charts.
class AnalyticsPage extends StatelessWidget {
  /// Creates [AnalyticsPage].
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(const AnalyticsStarted()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AnalyticsBloc>().add(const AnalyticsRefreshed()),
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          return switch (state) {
            AnalyticsInitial() => const AppLoadingIndicator.page(
                message: 'Preparing analytics…',
              ),
            AnalyticsLoading(:final message) => AppLoadingIndicator.page(
                message: message,
              ),
            AnalyticsError(:final failure) => AppErrorView.fromFailure(
                failure,
                onRetry: () => context
                    .read<AnalyticsBloc>()
                    .add(const AnalyticsStarted()),
              ),
            AnalyticsLoaded(:final period, :final report) => AppPageContainer(
                child: _AnalyticsDashboard(
                  period: period,
                  report: report,
                ),
              ),
          };
        },
      ),
    );
  }
}

class _AnalyticsDashboard extends StatelessWidget {
  const _AnalyticsDashboard({
    required this.period,
    required this.report,
  });

  final AnalyticsPeriod period;
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AnalyticsBloc>().add(const AnalyticsRefreshed());
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        children: [
          Text(
            'Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Trips, flood events, risk events, and speed from Hive history.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnalyticsPeriodSelector(
            period: period,
            onChanged: (p) =>
                context.read<AnalyticsBloc>().add(AnalyticsPeriodChanged(p)),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnalyticsStatsGrid(summary: report.summary),
          const SizedBox(height: AppSpacing.md),
          AnalyticsSecondaryStats(summary: report.summary),
          const SizedBox(height: AppSpacing.lg),
          AnalyticsEventsChart(
            buckets: report.buckets,
            period: period,
          ),
          const SizedBox(height: AppSpacing.md),
          AnalyticsTripsChart(
            buckets: report.buckets,
            period: period,
          ),
          const SizedBox(height: AppSpacing.md),
          AnalyticsSpeedChart(
            buckets: report.buckets,
            period: period,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Updated ${_format(report.generatedAt)} · '
            '${report.summary.totalRecords} records in range',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  String _format(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
