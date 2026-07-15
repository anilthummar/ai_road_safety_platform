import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/entities/analytics_entities.dart';
import 'package:flutter/material.dart';

/// Period segmented control (weekly / monthly / yearly).
class AnalyticsPeriodSelector extends StatelessWidget {
  /// Active period.
  final AnalyticsPeriod period;

  /// On change.
  final ValueChanged<AnalyticsPeriod> onChanged;

  /// Creates [AnalyticsPeriodSelector].
  const AnalyticsPeriodSelector({
    required this.period,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AnalyticsPeriod>(
      segments: [
        for (final p in AnalyticsPeriod.values)
          ButtonSegment(
            value: p,
            label: Text(p.label),
            icon: Icon(switch (p) {
              AnalyticsPeriod.weekly => Icons.view_week_outlined,
              AnalyticsPeriod.monthly => Icons.calendar_view_month_outlined,
              AnalyticsPeriod.yearly => Icons.calendar_today_outlined,
            }),
          ),
      ],
      selected: {period},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
    );
  }
}

/// KPI metric card for the analytics dashboard.
class AnalyticsStatCard extends StatelessWidget {
  /// Title.
  final String title;

  /// Primary value text.
  final String value;

  /// Optional subtitle.
  final String? subtitle;

  /// Accent.
  final Color color;

  /// Leading icon.
  final IconData icon;

  /// Creates [AnalyticsStatCard].
  const AnalyticsStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grid of primary analytics KPIs.
class AnalyticsStatsGrid extends StatelessWidget {
  /// Summary.
  final AnalyticsSummary summary;

  /// Creates [AnalyticsStatsGrid].
  const AnalyticsStatsGrid({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final cards = [
          AnalyticsStatCard(
            title: 'Trips',
            value: '${summary.trips}',
            subtitle: 'Active GPS days',
            color: AppColors.brandPrimary,
            icon: Icons.route_outlined,
          ),
          AnalyticsStatCard(
            title: 'Flood events',
            value: '${summary.floodEvents}',
            subtitle: '≥ ${AnalyticsConfig.floodEventThresholdPercent.toStringAsFixed(0)}% coverage',
            color: AppColors.info,
            icon: Icons.water_drop_outlined,
          ),
          AnalyticsStatCard(
            title: 'Risk events',
            value: '${summary.riskEvents}',
            subtitle:
                '${summary.highRiskEvents} high · ${summary.extremeRiskEvents} extreme',
            color: AppColors.riskHigh,
            icon: Icons.shield_outlined,
          ),
          AnalyticsStatCard(
            title: 'Avg speed',
            value: summary.averageSpeedKmh.toStringAsFixed(0),
            subtitle: 'km/h over moving samples',
            color: AppColors.brandCaution,
            icon: Icons.speed,
          ),
        ];

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Secondary metrics strip.
class AnalyticsSecondaryStats extends StatelessWidget {
  /// Summary.
  final AnalyticsSummary summary;

  /// Creates [AnalyticsSecondaryStats].
  const AnalyticsSecondaryStats({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _Metric(
              label: 'Records',
              value: '${summary.totalRecords}',
            ),
            _Metric(
              label: 'Avg risk',
              value: summary.averageRiskScore.toStringAsFixed(0),
            ),
            _Metric(
              label: 'Peak flood',
              value: '${summary.maxFloodPercent.toStringAsFixed(0)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
