import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/animated_dashboard_card.dart';
import 'package:flutter/material.dart';

/// Animated list of driver warnings.
class WarningsPanel extends StatelessWidget {
  /// Warnings to show.
  final List<DriverWarning> warnings;

  /// Entrance delay.
  final Duration delay;

  /// Creates [WarningsPanel].
  const WarningsPanel({
    required this.warnings,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedDashboardCard(
      delay: delay,
      accentColor: warnings.any((w) => w.severity == DriverWarningSeverity.critical)
          ? AppColors.riskCritical
          : warnings.isNotEmpty
              ? AppColors.brandCaution
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: warnings.isEmpty
                    ? scheme.onSurfaceVariant
                    : AppColors.brandCaution,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Warnings', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${warnings.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (warnings.isEmpty)
            Text(
              'All clear — no active warnings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
          else
            ...warnings.map((w) => _WarningTile(warning: w)),
        ],
      ),
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile({required this.warning});

  final DriverWarning warning;

  @override
  Widget build(BuildContext context) {
    final color = switch (warning.severity) {
      DriverWarningSeverity.info => AppColors.info,
      DriverWarningSeverity.caution => AppColors.brandCaution,
      DriverWarningSeverity.critical => AppColors.riskCritical,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                      ),
                ),
                Text(
                  warning.message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
