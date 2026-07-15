import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/cards/app_card.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter/material.dart';

/// Color for a [RiskLevel] (Extreme → critical tint).
Color riskLevelColor(RiskLevel level) {
  return switch (level) {
    RiskLevel.low => AppColors.riskLow,
    RiskLevel.medium => AppColors.riskMedium,
    RiskLevel.high => AppColors.riskHigh,
    RiskLevel.extreme => AppColors.riskCritical,
  };
}

/// Large risk level badge with score.
class RiskLevelBadge extends StatelessWidget {
  /// Risk level.
  final RiskLevel level;

  /// Aggregate score 0–100.
  final double score;

  /// Creates [RiskLevelBadge].
  const RiskLevelBadge({
    required this.level,
    required this.score,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = riskLevelColor(level);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              level.label.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Score ${score.toStringAsFixed(0)} / 100',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact chip for risk level.
class RiskLevelChip extends StatelessWidget {
  /// Level.
  final RiskLevel level;

  /// Creates [RiskLevelChip].
  const RiskLevelChip({required this.level, super.key});

  @override
  Widget build(BuildContext context) {
    final color = riskLevelColor(level);
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(level.label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

/// Shows fused input snapshot used for the latest assessment.
class RiskInputsSummaryCard extends StatelessWidget {
  /// Inputs.
  final RiskInputSnapshot inputs;

  /// Creates [RiskInputsSummaryCard].
  const RiskInputsSummaryCard({required this.inputs, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.input, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Inputs', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InputChip(
                label: 'Flood',
                value: '${inputs.floodCoveragePercent.toStringAsFixed(1)}%',
                active: inputs.hasFloodSample,
              ),
              _InputChip(
                label: 'Speed',
                value: '${inputs.speedKmh.toStringAsFixed(0)} km/h',
                active: inputs.hasGpsFix,
              ),
              _InputChip(
                label: 'GPS',
                value: inputs.hasGpsFix
                    ? '±${inputs.gpsAccuracyMeters?.toStringAsFixed(0) ?? '?'} m'
                    : 'none',
                active: inputs.hasGpsFix,
              ),
              _InputChip(
                label: 'Tilt',
                value: '${inputs.tiltDegrees.toStringAsFixed(1)}°',
                active: inputs.hasImuSample,
              ),
              _InputChip(
                label: 'Vibration',
                value: inputs.vibrationIntensity.name,
                active: inputs.hasImuSample,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputChip extends StatelessWidget {
  const _InputChip({
    required this.label,
    required this.value,
    required this.active,
  });

  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text('$label · $value'),
      avatar: Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 16,
        color: active ? AppColors.success : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// List of triggered rule contributions.
class RiskFactorsList extends StatelessWidget {
  /// Triggered rules.
  final List<RiskRuleHit> factors;

  /// Creates [RiskFactorsList].
  const RiskFactorsList({required this.factors, super.key});

  @override
  Widget build(BuildContext context) {
    if (factors.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'No elevated risk factors.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk factors', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...factors.map((hit) {
            final color = riskLevelColor(hit.level);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.rule, color: color),
              title: Text(hit.ruleName),
              subtitle: Text(hit.reason),
              trailing: Text(
                hit.score.toStringAsFixed(0),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Prioritized recommendations.
class RiskRecommendationsCard extends StatelessWidget {
  /// Recommendations.
  final List<RiskRecommendation> recommendations;

  /// Creates [RiskRecommendationsCard].
  const RiskRecommendationsCard({
    required this.recommendations,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recommendations.isEmpty)
            Text(
              'No special actions — continue with normal caution.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chevron_right, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        rec.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Monitoring status chip.
class RiskMonitoringChip extends StatelessWidget {
  /// Whether fusion is live.
  final bool isMonitoring;

  /// Creates [RiskMonitoringChip].
  const RiskMonitoringChip({required this.isMonitoring, super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.circle,
        size: 10,
        color: isMonitoring ? Colors.lightGreenAccent : Colors.grey,
      ),
      label: Text(isMonitoring ? 'Live fusion' : 'Idle'),
    );
  }
}
