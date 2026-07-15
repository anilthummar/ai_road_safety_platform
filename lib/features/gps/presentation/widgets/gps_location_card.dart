import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/cards/app_card.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/widgets/gps_metric_tile.dart';
import 'package:flutter/material.dart';

/// Reusable card summarizing a full GNSS fix.
class GpsLocationCard extends StatelessWidget {
  /// GNSS fix to display.
  final GpsFix fix;

  /// Creates [GpsLocationCard].
  const GpsLocationCard({required this.fix, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Current location', style: textTheme.titleMedium),
              ),
              GpsAccuracyBadge(accuracyMeters: fix.accuracyMeters),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            fix.coordinateLabel,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Updated ${_formatTime(fix.timestamp)}'
            '${fix.isMocked ? ' · mock location' : ''}',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// Grid of accuracy / altitude / speed / heading metrics.
class GpsMetricsGrid extends StatelessWidget {
  /// Source fix.
  final GpsFix fix;

  /// Creates [GpsMetricsGrid].
  const GpsMetricsGrid({required this.fix, super.key});

  @override
  Widget build(BuildContext context) {
    final speed = fix.speedKmh;
    final heading = fix.headingDegrees;
    final altitude = fix.altitudeMeters;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GpsMetricTile(
                label: 'Accuracy',
                value: fix.accuracyMeters.toStringAsFixed(1),
                unit: 'm',
                icon: Icons.my_location_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GpsMetricTile(
                label: 'Altitude',
                value: altitude == null ? '—' : altitude.toStringAsFixed(1),
                unit: altitude == null ? null : 'm',
                icon: Icons.terrain_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: GpsMetricTile(
                label: 'Speed',
                value: speed == null ? '—' : speed.toStringAsFixed(1),
                unit: speed == null ? null : 'km/h',
                icon: Icons.speed_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GpsMetricTile(
                label: 'Heading',
                value: heading == null ? '—' : heading.toStringAsFixed(0),
                unit: heading == null ? null : '°',
                icon: Icons.explore_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
