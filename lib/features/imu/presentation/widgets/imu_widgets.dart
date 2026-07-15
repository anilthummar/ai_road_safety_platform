import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/cards/app_card.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:flutter/material.dart';

/// Compact XYZ readout for accel / gyro / mag.
class ImuAxisCard extends StatelessWidget {
  /// Section title.
  final String title;

  /// Vector values.
  final ImuVector3 vector;

  /// Unit label (e.g. m/s²).
  final String unit;

  /// Leading icon.
  final IconData icon;

  /// Creates [ImuAxisCard].
  const ImuAxisCard({
    required this.title,
    required this.vector,
    required this.unit,
    required this.icon,
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
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                '|v| ${vector.magnitude.toStringAsFixed(2)} $unit',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _AxisRow(label: 'X', value: vector.x, unit: unit),
          _AxisRow(label: 'Y', value: vector.y, unit: unit),
          _AxisRow(label: 'Z', value: vector.z, unit: unit),
        ],
      ),
    );
  }
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              '${value.toStringAsFixed(3)} $unit',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pitch / roll / yaw + absolute tilt.
class ImuOrientationCard extends StatelessWidget {
  /// Orientation angles.
  final ImuOrientation orientation;

  /// Absolute tilt from upright.
  final double tiltDegrees;

  /// Creates [ImuOrientationCard].
  const ImuOrientationCard({
    required this.orientation,
    required this.tiltDegrees,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final yaw = orientation.yawDegrees;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.screen_rotation, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Orientation & tilt', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _AngleChip(
                label: 'Pitch',
                value: orientation.pitchDegrees,
              ),
              _AngleChip(
                label: 'Roll',
                value: orientation.rollDegrees,
              ),
              _AngleChip(
                label: 'Yaw',
                value: yaw,
                placeholder: 'n/a',
              ),
              _AngleChip(
                label: 'Tilt',
                value: tiltDegrees,
                emphasize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AngleChip extends StatelessWidget {
  const _AngleChip({
    required this.label,
    required this.value,
    this.placeholder,
    this.emphasize = false,
  });

  final String label;
  final double? value;
  final String? placeholder;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = value == null
        ? (placeholder ?? '—')
        : '${value!.toStringAsFixed(1)}°';
    return Chip(
      label: Text('$label $text'),
      side: emphasize
          ? BorderSide(color: scheme.primary.withValues(alpha: 0.5))
          : null,
    );
  }
}

/// Vehicle vibration meter.
class ImuVibrationCard extends StatelessWidget {
  /// Vibration metrics.
  final VibrationMetrics vibration;

  /// Creates [ImuVibrationCard].
  const ImuVibrationCard({required this.vibration, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final band = _bandStyle(vibration.intensity);
    final progress = (vibration.rms / 2.5).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vibration, color: band.color),
              const SizedBox(width: AppSpacing.sm),
              Text('Vehicle vibration', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Chip(
                avatar: Icon(Icons.circle, size: 10, color: band.color),
                label: Text(band.label),
                side: BorderSide(color: band.color.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: band.color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'RMS ${vibration.rms.toStringAsFixed(2)} m/s²  ·  '
            'Peak ${vibration.peak.toStringAsFixed(2)} m/s²',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _bandStyle(VibrationIntensity intensity) {
    return switch (intensity) {
      VibrationIntensity.calm => (label: 'Calm', color: AppColors.success),
      VibrationIntensity.moderate => (label: 'Moderate', color: AppColors.info),
      VibrationIntensity.rough => (label: 'Rough', color: AppColors.brandCaution),
      VibrationIntensity.severe => (label: 'Severe', color: AppColors.brandHazard),
    };
  }
}

/// Calibration status + progress.
class ImuCalibrationBanner extends StatelessWidget {
  /// Current calibration.
  final ImuCalibration calibration;

  /// Whether collecting samples.
  final bool isCalibrating;

  /// Progress 0–1 while calibrating.
  final double progress;

  /// Creates [ImuCalibrationBanner].
  const ImuCalibrationBanner({
    required this.calibration,
    required this.isCalibrating,
    required this.progress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isCalibrating) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hold still — calibrating…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          ],
        ),
      );
    }

    final ok = calibration.isCalibrated;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified : Icons.tune,
            color: ok ? AppColors.success : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              ok
                  ? 'Calibrated (${calibration.samplesUsed} samples)'
                  : 'Not calibrated — rest the phone flat and tap Calibrate',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Streaming status chip.
class ImuStatusChip extends StatelessWidget {
  /// Whether streams are active.
  final bool isStreaming;

  /// Creates [ImuStatusChip].
  const ImuStatusChip({required this.isStreaming, super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.circle,
        size: 10,
        color: isStreaming ? Colors.lightGreenAccent : Colors.grey,
      ),
      label: Text(isStreaming ? 'Streaming' : 'Idle'),
    );
  }
}
