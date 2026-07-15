import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';

/// Single GPS metric tile (accuracy, altitude, speed, heading).
class GpsMetricTile extends StatelessWidget {
  /// Metric label.
  final String label;

  /// Formatted value.
  final String value;

  /// Optional unit suffix shown muted.
  final String? unit;

  /// Leading icon.
  final IconData icon;

  /// Accent color.
  final Color? color;

  /// Creates a [GpsMetricTile].
  const GpsMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.unit,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact accuracy quality badge.
class GpsAccuracyBadge extends StatelessWidget {
  /// Horizontal accuracy in meters.
  final double accuracyMeters;

  /// Creates [GpsAccuracyBadge].
  const GpsAccuracyBadge({required this.accuracyMeters, super.key});

  @override
  Widget build(BuildContext context) {
    final quality = _quality(accuracyMeters);
    return Chip(
      avatar: Icon(Icons.gps_fixed, size: 16, color: quality.color),
      label: Text(
        '${accuracyMeters.toStringAsFixed(1)} m · ${quality.label}',
      ),
      side: BorderSide(color: quality.color.withValues(alpha: 0.4)),
    );
  }

  ({String label, Color color}) _quality(double meters) {
    if (meters <= 5) {
      return (label: 'Excellent', color: AppColors.success);
    }
    if (meters <= 15) {
      return (label: 'Good', color: AppColors.info);
    }
    if (meters <= 40) {
      return (label: 'Fair', color: AppColors.brandCaution);
    }
    return (label: 'Poor', color: AppColors.brandHazard);
  }
}

/// Streaming / idle status chip.
class GpsStatusChip extends StatelessWidget {
  /// Whether continuous updates are active.
  final bool isStreaming;

  /// Whether location services are enabled.
  final bool isServiceEnabled;

  /// Creates [GpsStatusChip].
  const GpsStatusChip({
    required this.isStreaming,
    required this.isServiceEnabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isServiceEnabled) {
      return const Chip(
        avatar: Icon(Icons.location_disabled, size: 16),
        label: Text('GPS off'),
      );
    }
    return Chip(
      avatar: Icon(
        Icons.circle,
        size: 10,
        color: isStreaming ? Colors.lightGreenAccent : Colors.grey,
      ),
      label: Text(isStreaming ? 'Tracking' : 'Idle'),
    );
  }
}
