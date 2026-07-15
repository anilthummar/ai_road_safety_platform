import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/capture_rule.dart';

/// Placeholder — flood confidence threshold (Phase 12.4+).
class FloodConfidenceRule implements CaptureRule {
  /// Creates [FloodConfidenceRule].
  const FloodConfidenceRule();

  @override
  String get id => 'flood_confidence';

  @override
  String get name => 'Flood confidence';

  @override
  bool get isEnabled => false;

  @override
  CaptureDecision evaluate(FrameCaptureContext context) => CaptureDecision.skip;

  @override
  void onCaptured(FrameCaptureContext context) {}

  @override
  void reset() {}
}

/// Placeholder — water coverage delta (Phase 12.4+).
class WaterCoverageChangeRule implements CaptureRule {
  /// Creates [WaterCoverageChangeRule].
  const WaterCoverageChangeRule();

  @override
  String get id => 'water_coverage_change';

  @override
  String get name => 'Water coverage change';

  @override
  bool get isEnabled => false;

  @override
  CaptureDecision evaluate(FrameCaptureContext context) => CaptureDecision.skip;

  @override
  void onCaptured(FrameCaptureContext context) {}

  @override
  void reset() {}
}

/// Placeholder — large vehicle / optical motion (Phase 12.4+).
class MotionRule implements CaptureRule {
  /// Creates [MotionRule].
  const MotionRule();

  @override
  String get id => 'motion';

  @override
  String get name => 'Motion';

  @override
  bool get isEnabled => false;

  @override
  CaptureDecision evaluate(FrameCaptureContext context) => CaptureDecision.skip;

  @override
  void onCaptured(FrameCaptureContext context) {}

  @override
  void reset() {}
}

/// Placeholder — sudden IMU spike (Phase 12.4+).
class ImuEventRule implements CaptureRule {
  /// Creates [ImuEventRule].
  const ImuEventRule();

  @override
  String get id => 'imu_event';

  @override
  String get name => 'IMU event';

  @override
  bool get isEnabled => false;

  @override
  CaptureDecision evaluate(FrameCaptureContext context) => CaptureDecision.skip;

  @override
  void onCaptured(FrameCaptureContext context) {}

  @override
  void reset() {}
}
