import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:flutter/material.dart';

/// Gradient hero banner summarising road status at a glance.
///
/// Color follows the fused risk level; mini-stats show speed, flood coverage,
/// and GPS accuracy without scrolling.
class StatusHeroBanner extends StatelessWidget {
  /// Latest fused HUD snapshot.
  final DriverDashboardHud hud;

  /// Creates [StatusHeroBanner].
  const StatusHeroBanner({required this.hud, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final (Color base, IconData icon, String headline, String caption) =
        _visuals();
    final gradientEnd = Color.lerp(base, AppColors.brandInk, 0.35)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, gradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROAD STATUS',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headline,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hud.hasRiskAssessment)
                  _ScoreBubble(score: hud.riskScore),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  _HeroStat(
                    icon: Icons.speed_rounded,
                    value: hud.hasGpsFix ? hud.speedKmh.toStringAsFixed(0) : '—',
                    unit: 'km/h',
                    label: 'Speed',
                  ),
                  _statDivider(),
                  _HeroStat(
                    icon: Icons.water_drop_rounded,
                    value: hud.hasFloodSample
                        ? hud.floodCoveragePercent.toStringAsFixed(0)
                        : '—',
                    unit: '%',
                    label: 'Flood',
                  ),
                  _statDivider(),
                  _HeroStat(
                    icon: Icons.gps_fixed_rounded,
                    value: hud.gpsAccuracyMeters != null
                        ? '±${hud.gpsAccuracyMeters!.toStringAsFixed(0)}'
                        : '—',
                    unit: 'm',
                    label: 'GPS',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  (Color, IconData, String, String) _visuals() {
    if (!hud.isLive) {
      return (
        AppColors.brandInk,
        Icons.nightlight_round,
        'Standby',
        'HUD paused — sensors idle',
      );
    }
    if (!hud.hasRiskAssessment) {
      return (
        AppColors.info,
        Icons.radar_rounded,
        'Warming up…',
        'Waiting for sensor fusion',
      );
    }
    return switch (hud.riskLevel) {
      RiskLevel.low => (
          AppColors.brandPrimary,
          Icons.verified_user_rounded,
          'All clear',
          'Low risk · conditions nominal',
        ),
      RiskLevel.medium => (
          AppColors.brandCaution,
          Icons.shield_rounded,
          'Stay alert',
          'Medium risk detected',
        ),
      RiskLevel.high => (
          AppColors.riskHigh,
          Icons.report_rounded,
          'High risk',
          'Slow down — hazards likely',
        ),
      RiskLevel.extreme => (
          AppColors.riskCritical,
          Icons.emergency_rounded,
          'Critical',
          'Extreme risk — act now',
        ),
    };
  }
}

class _ScoreBubble extends StatelessWidget {
  const _ScoreBubble({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
              ),
              Text(
                'risk',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
