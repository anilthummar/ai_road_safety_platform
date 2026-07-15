import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:equatable/equatable.dart';

/// Discrete fused hazard severity for the road-safety platform.
enum RiskLevel {
  /// Conditions appear normal.
  low,

  /// Elevated caution — slow down / watch flooding.
  medium,

  /// Serious hazard — avoid flooded stretch if possible.
  high,

  /// Immediate danger — stop / reroute.
  extreme,
}

/// Extension helpers for [RiskLevel].
extension RiskLevelX on RiskLevel {
  /// Short UI label.
  String get label => switch (this) {
        RiskLevel.low => 'Low',
        RiskLevel.medium => 'Medium',
        RiskLevel.high => 'High',
        RiskLevel.extreme => 'Extreme',
      };

  /// Sort key 0–3.
  int get rank => index;

  /// Maps a 0–100 score onto levels.
  static RiskLevel fromScore(double score) {
    if (score >= 75) return RiskLevel.extreme;
    if (score >= 50) return RiskLevel.high;
    if (score >= 25) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

/// Normalized inputs consumed by the rule engine.
class RiskInputSnapshot extends Equatable {
  /// Water / flood coverage percent \[0–100\].
  final double floodCoveragePercent;

  /// Vehicle speed in km/h (0 if unknown).
  final double speedKmh;

  /// Horizontal GPS accuracy in meters (null if no fix).
  final double? gpsAccuracyMeters;

  /// Latitude when a fix exists.
  final double? latitude;

  /// Longitude when a fix exists.
  final double? longitude;

  /// Absolute device tilt from upright (degrees).
  final double tiltDegrees;

  /// Vehicle / road vibration intensity.
  final VibrationIntensity vibrationIntensity;

  /// Vibration RMS (m/s²).
  final double vibrationRms;

  /// Whether a GPS fix was present for this snapshot.
  final bool hasGpsFix;

  /// Whether IMU sample was present.
  final bool hasImuSample;

  /// Whether flood segmentation data was present.
  final bool hasFloodSample;

  /// Capture time.
  final DateTime timestamp;

  /// Creates [RiskInputSnapshot].
  const RiskInputSnapshot({
    required this.floodCoveragePercent,
    required this.speedKmh,
    required this.tiltDegrees,
    required this.vibrationIntensity,
    required this.vibrationRms,
    required this.timestamp,
    this.gpsAccuracyMeters,
    this.latitude,
    this.longitude,
    this.hasGpsFix = false,
    this.hasImuSample = false,
    this.hasFloodSample = false,
  });

  /// Empty / unknown sensors baseline.
  factory RiskInputSnapshot.empty([DateTime? at]) {
    return RiskInputSnapshot(
      floodCoveragePercent: 0,
      speedKmh: 0,
      tiltDegrees: 0,
      vibrationIntensity: VibrationIntensity.calm,
      vibrationRms: 0,
      timestamp: at ?? DateTime.now(),
    );
  }

  /// Copy helper.
  RiskInputSnapshot copyWith({
    double? floodCoveragePercent,
    double? speedKmh,
    double? gpsAccuracyMeters,
    double? latitude,
    double? longitude,
    double? tiltDegrees,
    VibrationIntensity? vibrationIntensity,
    double? vibrationRms,
    bool? hasGpsFix,
    bool? hasImuSample,
    bool? hasFloodSample,
    DateTime? timestamp,
    bool clearGps = false,
  }) {
    return RiskInputSnapshot(
      floodCoveragePercent: floodCoveragePercent ?? this.floodCoveragePercent,
      speedKmh: speedKmh ?? this.speedKmh,
      gpsAccuracyMeters:
          clearGps ? null : (gpsAccuracyMeters ?? this.gpsAccuracyMeters),
      latitude: clearGps ? null : (latitude ?? this.latitude),
      longitude: clearGps ? null : (longitude ?? this.longitude),
      tiltDegrees: tiltDegrees ?? this.tiltDegrees,
      vibrationIntensity: vibrationIntensity ?? this.vibrationIntensity,
      vibrationRms: vibrationRms ?? this.vibrationRms,
      hasGpsFix: clearGps ? false : (hasGpsFix ?? this.hasGpsFix),
      hasImuSample: hasImuSample ?? this.hasImuSample,
      hasFloodSample: hasFloodSample ?? this.hasFloodSample,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        floodCoveragePercent,
        speedKmh,
        gpsAccuracyMeters,
        latitude,
        longitude,
        tiltDegrees,
        vibrationIntensity,
        vibrationRms,
        hasGpsFix,
        hasImuSample,
        hasFloodSample,
        timestamp,
      ];
}

/// Result from a single business rule evaluation.
class RiskRuleHit extends Equatable {
  /// Stable rule id (e.g. `flood_coverage`).
  final String ruleId;

  /// Human-readable rule name.
  final String ruleName;

  /// Contribution score \[0–100\].
  final double score;

  /// Suggested level from this rule alone.
  final RiskLevel level;

  /// Short reason shown in the UI factor list.
  final String reason;

  /// Optional driver recommendation when this rule fires.
  final String? recommendation;

  /// Creates [RiskRuleHit].
  const RiskRuleHit({
    required this.ruleId,
    required this.ruleName,
    required this.score,
    required this.level,
    required this.reason,
    this.recommendation,
  });

  @override
  List<Object?> get props => [
        ruleId,
        ruleName,
        score,
        level,
        reason,
        recommendation,
      ];
}

/// Actionable guidance for the driver / operator.
class RiskRecommendation extends Equatable {
  /// Priority (higher first).
  final int priority;

  /// Source rule id.
  final String ruleId;

  /// Message text.
  final String message;

  /// Creates [RiskRecommendation].
  const RiskRecommendation({
    required this.priority,
    required this.ruleId,
    required this.message,
  });

  @override
  List<Object?> get props => [priority, ruleId, message];
}

/// Complete fused assessment from the rule engine.
class RiskAssessment extends Equatable {
  /// Overall risk level.
  final RiskLevel level;

  /// Aggregate score \[0–100\].
  final double score;

  /// Inputs used for this evaluation.
  final RiskInputSnapshot inputs;

  /// Rules that contributed (score &gt; 0).
  final List<RiskRuleHit> triggeredRules;

  /// Deduped, priority-sorted recommendations.
  final List<RiskRecommendation> recommendations;

  /// Evaluation timestamp.
  final DateTime evaluatedAt;

  /// Creates [RiskAssessment].
  const RiskAssessment({
    required this.level,
    required this.score,
    required this.inputs,
    required this.triggeredRules,
    required this.recommendations,
    required this.evaluatedAt,
  });

  @override
  List<Object?> get props => [
        level,
        score,
        inputs,
        triggeredRules,
        recommendations,
        evaluatedAt,
      ];
}

/// Live risk-analysis session.
class RiskSession extends Equatable {
  /// Whether continuous fused evaluation is running.
  final bool isMonitoring;

  /// Latest assessment (nullable before first emit).
  final RiskAssessment? latestAssessment;

  /// Creates [RiskSession].
  const RiskSession({
    required this.isMonitoring,
    this.latestAssessment,
  });

  /// Idle factory.
  const RiskSession.idle()
      : isMonitoring = false,
        latestAssessment = null;

  /// Copy helper.
  RiskSession copyWith({
    bool? isMonitoring,
    RiskAssessment? latestAssessment,
    bool clearAssessment = false,
  }) {
    return RiskSession(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      latestAssessment:
          clearAssessment ? null : (latestAssessment ?? this.latestAssessment),
    );
  }

  @override
  List<Object?> get props => [isMonitoring, latestAssessment];
}

/// Risk engine timing / throttle constants.
class RiskAnalysisConfig {
  RiskAnalysisConfig._();

  /// Max fused assessment emit rate (~5 Hz).
  static const Duration emitInterval = Duration(milliseconds: 200);
}
