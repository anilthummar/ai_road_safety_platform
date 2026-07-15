import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/animated_dashboard_card.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/status_pill.dart';
import 'package:flutter/material.dart';

/// GPS status and coordinate summary card.
class GpsStatusCard extends StatelessWidget {
  /// Whether a fix exists.
  final bool hasFix;

  /// Latitude.
  final double? latitude;

  /// Longitude.
  final double? longitude;

  /// Accuracy meters.
  final double? accuracyMeters;

  /// Entrance delay.
  final Duration delay;

  /// Creates [GpsStatusCard].
  const GpsStatusCard({
    required this.hasFix,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = hasFix ? AppColors.success : scheme.outline;

    return AnimatedDashboardCard(
      delay: delay,
      accentColor: hasFix ? accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFix ? Icons.gps_fixed : Icons.gps_off,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('GPS', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              StatusPill(
                label: hasFix ? 'Locked' : 'No fix',
                active: hasFix,
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hasFix)
            Text(
              'No satellite fix — enable Location / GPS in system settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
          else ...[
            Text(
              '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.my_location, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '±${accuracyMeters?.toStringAsFixed(1) ?? '—'} m accuracy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (accuracyMeters != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (1 - (accuracyMeters! / 50)).clamp(0.05, 1.0),
                  minHeight: 8,
                  color: accuracyMeters! <= 15
                      ? AppColors.success
                      : AppColors.brandCaution,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
