import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:equatable/equatable.dart';

/// Severity for a driver-facing warning banner.
enum DriverWarningSeverity {
  /// Informational.
  info,

  /// Elevated caution.
  caution,

  /// Immediate attention.
  critical,
}

/// Single HUD warning item.
class DriverWarning extends Equatable {
  /// Stable id for list keys / dedupe.
  final String id;

  /// Short title.
  final String title;

  /// Detail message.
  final String message;

  /// Severity band.
  final DriverWarningSeverity severity;

  /// Creates [DriverWarning].
  const DriverWarning({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
  });

  @override
  List<Object?> get props => [id, title, message, severity];
}

/// Fused snapshot for the driver dashboard HUD.
class DriverDashboardHud extends Equatable {
  /// Flood / water coverage percent \[0–100\].
  final double floodCoveragePercent;

  /// Whether a flood segmentation sample has arrived.
  final bool hasFloodSample;

  /// Current risk level.
  final RiskLevel riskLevel;

  /// Risk score \[0–100\].
  final double riskScore;

  /// Whether a risk assessment exists.
  final bool hasRiskAssessment;

  /// Vehicle speed km/h (0 if unknown).
  final double speedKmh;

  /// Whether a GPS fix is available.
  final bool hasGpsFix;

  /// Latitude when available.
  final double? latitude;

  /// Longitude when available.
  final double? longitude;

  /// Horizontal accuracy meters.
  final double? gpsAccuracyMeters;

  /// Active ranked warnings (critical first).
  final List<DriverWarning> warnings;

  /// Whether live fusion / sensors are actively monitored.
  final bool isLive;

  /// Snapshot time.
  final DateTime updatedAt;

  /// Creates [DriverDashboardHud].
  const DriverDashboardHud({
    required this.floodCoveragePercent,
    required this.hasFloodSample,
    required this.riskLevel,
    required this.riskScore,
    required this.hasRiskAssessment,
    required this.speedKmh,
    required this.hasGpsFix,
    required this.warnings,
    required this.isLive,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.gpsAccuracyMeters,
  });

  /// Empty idle HUD.
  factory DriverDashboardHud.idle([DateTime? at]) {
    return DriverDashboardHud(
      floodCoveragePercent: 0,
      hasFloodSample: false,
      riskLevel: RiskLevel.low,
      riskScore: 0,
      hasRiskAssessment: false,
      speedKmh: 0,
      hasGpsFix: false,
      warnings: const [],
      isLive: false,
      updatedAt: at ?? DateTime.now(),
    );
  }

  /// Copy helper.
  DriverDashboardHud copyWith({
    double? floodCoveragePercent,
    bool? hasFloodSample,
    RiskLevel? riskLevel,
    double? riskScore,
    bool? hasRiskAssessment,
    double? speedKmh,
    bool? hasGpsFix,
    double? latitude,
    double? longitude,
    double? gpsAccuracyMeters,
    List<DriverWarning>? warnings,
    bool? isLive,
    DateTime? updatedAt,
    bool clearGps = false,
  }) {
    return DriverDashboardHud(
      floodCoveragePercent: floodCoveragePercent ?? this.floodCoveragePercent,
      hasFloodSample: hasFloodSample ?? this.hasFloodSample,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      hasRiskAssessment: hasRiskAssessment ?? this.hasRiskAssessment,
      speedKmh: speedKmh ?? this.speedKmh,
      hasGpsFix: clearGps ? false : (hasGpsFix ?? this.hasGpsFix),
      latitude: clearGps ? null : (latitude ?? this.latitude),
      longitude: clearGps ? null : (longitude ?? this.longitude),
      gpsAccuracyMeters:
          clearGps ? null : (gpsAccuracyMeters ?? this.gpsAccuracyMeters),
      warnings: warnings ?? this.warnings,
      isLive: isLive ?? this.isLive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        floodCoveragePercent,
        hasFloodSample,
        riskLevel,
        riskScore,
        hasRiskAssessment,
        speedKmh,
        hasGpsFix,
        latitude,
        longitude,
        gpsAccuracyMeters,
        warnings,
        isLive,
        updatedAt,
      ];
}
