import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/cards/app_card.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:flutter/material.dart';

/// Compact reusable meter for a single coverage percentage.
class CoverageStatCard extends StatelessWidget {
  /// Metric title.
  final String label;

  /// Value in percent \[0–100\].
  final double percent;

  /// Accent color for the bar / value.
  final Color color;

  /// Optional subtitle under the value.
  final String? subtitle;

  /// Creates a [CoverageStatCard].
  const CoverageStatCard({
    required this.label,
    required this.percent,
    required this.color,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clamped = percent.clamp(0.0, 100.0);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${clamped.toStringAsFixed(1)}%',
            style: textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(subtitle!, style: textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistics panel for water / road coverage and confidence.
class FloodStatsPanel extends StatelessWidget {
  /// Coverage + confidence metrics.
  final FloodCoverageStats stats;

  /// Optional compact mode for camera chrome.
  final bool compact;

  /// Creates a [FloodStatsPanel].
  const FloodStatsPanel({
    required this.stats,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final confPct = (stats.meanConfidence * 100).clamp(0.0, 100.0);

    if (compact) {
      return Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _CompactChip(
                label: 'Water',
                value: '${stats.waterCoveragePercent.toStringAsFixed(1)}%',
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CompactChip(
                label: 'Road',
                value: '${stats.roadCoveragePercent.toStringAsFixed(1)}%',
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CompactChip(
                label: 'Conf',
                value: '${confPct.toStringAsFixed(0)}%',
                color: AppColors.brandCaution,
              ),
              if (stats.isFloodLikely) ...[
                const SizedBox(width: AppSpacing.sm),
                const _CompactChip(
                  label: 'Alert',
                  value: 'FLOOD',
                  color: AppColors.brandHazard,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stats.isFloodLikely)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                borderColor: AppColors.brandHazard,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.brandHazard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Elevated water coverage detected on roadway.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: CoverageStatCard(
                  label: 'Water coverage',
                  percent: stats.waterCoveragePercent,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CoverageStatCard(
                  label: 'Road coverage',
                  percent: stats.roadCoveragePercent,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CoverageStatCard(
                  label: 'Vehicle',
                  percent: stats.vehicleCoveragePercent,
                  color: AppColors.brandSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CoverageStatCard(
                  label: 'Obstacle',
                  percent: stats.obstacleCoveragePercent,
                  color: AppColors.brandHazard,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CoverageStatCard(
            label: 'Mean segmentation confidence',
            percent: confPct,
            color: AppColors.brandCaution,
            subtitle: 'Average max-class confidence across pixels',
          ),
        ],
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legend for segmentation overlay colors.
class FloodClassLegend extends StatelessWidget {
  /// Creates [FloodClassLegend].
  const FloodClassLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <(String, Color)>[
      ('Road', Color(0xFF50505A)),
      ('Water', Color(0xFF1478DC)),
      ('Vehicle', Color(0xFF08A4BD)),
      ('Obstacle', Color(0xFFC1121F)),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items)
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: CircleAvatar(backgroundColor: item.$2, radius: 6),
            label: Text(item.$1),
          ),
      ],
    );
  }
}
