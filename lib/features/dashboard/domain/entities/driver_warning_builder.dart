import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';

/// Builds ranked [DriverWarning]s from fused HUD inputs.
class DriverWarningBuilder {
  /// Creates [DriverWarningBuilder].
  const DriverWarningBuilder();

  /// Derives warnings from live metrics + optional risk recommendations.
  List<DriverWarning> build({
    required double floodCoveragePercent,
    required bool hasFloodSample,
    required double speedKmh,
    required bool hasGpsFix,
    required double? gpsAccuracyMeters,
    required RiskLevel riskLevel,
    required bool hasRiskAssessment,
    List<RiskRecommendation> recommendations = const [],
  }) {
    final warnings = <DriverWarning>[];

    if (hasRiskAssessment && riskLevel == RiskLevel.extreme) {
      warnings.add(
        const DriverWarning(
          id: 'risk_extreme',
          title: 'Extreme risk',
          message: 'Stop when safe — do not enter flooded or unstable roadway.',
          severity: DriverWarningSeverity.critical,
        ),
      );
    } else if (hasRiskAssessment && riskLevel == RiskLevel.high) {
      warnings.add(
        const DriverWarning(
          id: 'risk_high',
          title: 'High risk',
          message: 'Hazard elevated — reduce speed and prepare to stop.',
          severity: DriverWarningSeverity.critical,
        ),
      );
    }

    if (hasFloodSample && floodCoveragePercent >= 20) {
      warnings.add(
        DriverWarning(
          id: 'flood_high',
          title: 'Flooding detected',
          message:
              'Water coverage ${floodCoveragePercent.toStringAsFixed(0)}% — avoid flooded lanes.',
          severity: DriverWarningSeverity.critical,
        ),
      );
    } else if (hasFloodSample && floodCoveragePercent >= 8) {
      warnings.add(
        DriverWarning(
          id: 'flood_caution',
          title: 'Possible standing water',
          message:
              'Flood coverage ${floodCoveragePercent.toStringAsFixed(0)}% — proceed with caution.',
          severity: DriverWarningSeverity.caution,
        ),
      );
    }

    if (floodCoveragePercent >= 5 && speedKmh >= 40) {
      warnings.add(
        DriverWarning(
          id: 'flood_speed',
          title: 'Speed + water',
          message:
              '${speedKmh.toStringAsFixed(0)} km/h with water on road — slow down immediately.',
          severity: DriverWarningSeverity.critical,
        ),
      );
    }

    if (!hasGpsFix) {
      warnings.add(
        const DriverWarning(
          id: 'gps_missing',
          title: 'GPS unavailable',
          message:
              'Location services may be off — enable GPS in system settings.',
          severity: DriverWarningSeverity.info,
        ),
      );
    } else if (gpsAccuracyMeters != null && gpsAccuracyMeters >= 40) {
      warnings.add(
        DriverWarning(
          id: 'gps_poor',
          title: 'Poor GPS accuracy',
          message: 'Accuracy ±${gpsAccuracyMeters.toStringAsFixed(0)} m.',
          severity: DriverWarningSeverity.caution,
        ),
      );
    }

    if (speedKmh >= 90) {
      warnings.add(
        DriverWarning(
          id: 'speed_high',
          title: 'High speed',
          message: '${speedKmh.toStringAsFixed(0)} km/h — reduce speed near hazards.',
          severity: DriverWarningSeverity.caution,
        ),
      );
    }

    // Append unique risk recommendations as info/caution.
    for (final rec in recommendations) {
      final id = 'rec_${rec.ruleId}';
      if (warnings.any((w) => w.id == id)) continue;
      warnings.add(
        DriverWarning(
          id: id,
          title: 'Recommendation',
          message: rec.message,
          severity: rec.priority >= 200
              ? DriverWarningSeverity.critical
              : DriverWarningSeverity.caution,
        ),
      );
    }

    warnings.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    // Cap HUD noise.
    if (warnings.length > 6) {
      return warnings.sublist(0, 6);
    }
    return warnings;
  }
}
