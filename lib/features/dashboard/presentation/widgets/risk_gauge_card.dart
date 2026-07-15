import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/animated_dashboard_card.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/widgets/risk_widgets.dart';
import 'package:flutter/material.dart';

/// Risk level card with animated linear progress.
class RiskGaugeCard extends StatelessWidget {
  /// Risk level.
  final RiskLevel level;

  /// Score 0–100.
  final double score;

  /// Whether an assessment exists.
  final bool hasAssessment;

  /// Entrance delay.
  final Duration delay;

  /// Creates [RiskGaugeCard].
  const RiskGaugeCard({
    required this.level,
    required this.score,
    required this.hasAssessment,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = riskLevelColor(level);
    final scheme = Theme.of(context).colorScheme;
    final progress = hasAssessment ? (score / 100).clamp(0.0, 1.0) : 0.0;

    return AnimatedDashboardCard(
      delay: delay,
      accentColor: hasAssessment ? color : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_moon_outlined, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text('Risk', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              RiskLevelChip(level: hasAssessment ? level : RiskLevel.low),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            hasAssessment ? level.label : 'Awaiting fusion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: hasAssessment ? color : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  color: color,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasAssessment
                ? 'Score ${score.toStringAsFixed(0)} / 100'
                : 'Start sensors for live risk',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
