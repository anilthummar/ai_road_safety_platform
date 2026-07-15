import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

/// Compact live/idle status pill with a glowing state dot.
///
/// Replaces bulky Material [Chip]s in HUD headers.
class StatusPill extends StatelessWidget {
  /// Pill label (e.g. "Live", "Locked").
  final String label;

  /// Whether the state is active/healthy.
  final bool active;

  /// Accent used when [active]; defaults to the theme primary.
  final Color? activeColor;

  /// Creates [StatusPill].
  const StatusPill({
    required this.label,
    required this.active,
    this.activeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = activeColor ?? scheme.primary;
    final dotColor = active ? color : scheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? color : scheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}
