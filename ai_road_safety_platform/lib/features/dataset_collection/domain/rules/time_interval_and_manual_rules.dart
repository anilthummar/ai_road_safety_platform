import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/rules/capture_rule.dart';

/// Captures at most once every [interval] while the session is actively recording.
class TimeIntervalRule implements CaptureRule {
  /// Minimum gap between automatic captures.
  final Duration interval;

  DateTime? _lastCaptureAt;
  bool _enabled;

  /// Creates [TimeIntervalRule].
  TimeIntervalRule({
    this.interval = const Duration(seconds: 1),
    bool enabled = true,
  }) : _enabled = enabled;

  @override
  String get id => 'time_interval';

  @override
  String get name => 'Time interval';

  @override
  bool get isEnabled => _enabled;

  /// Enables / disables the rule.
  set isEnabled(bool value) => _enabled = value;

  @override
  CaptureDecision evaluate(FrameCaptureContext context) {
    if (!_enabled) return CaptureDecision.skip;
    if (!context.isSessionActive ||
        context.isSessionPaused ||
        context.isCapturePaused) {
      return CaptureDecision.skip;
    }
    if (context.frame == null) return CaptureDecision.skip;

    final last = _lastCaptureAt;
    if (last != null && context.now.difference(last) < interval) {
      return CaptureDecision.skip;
    }

    return CaptureDecision.capture(
      ruleId: id,
      message: 'Interval ${interval.inMilliseconds}ms elapsed',
      type: CaptureType.automatic,
    );
  }

  @override
  void onCaptured(FrameCaptureContext context) {
    _lastCaptureAt = context.now;
  }

  @override
  void reset() {
    _lastCaptureAt = null;
  }
}

/// Captures exactly once when a manual request is pending.
class ManualCaptureRule implements CaptureRule {
  bool _enabled;
  bool _armed = false;

  /// Creates [ManualCaptureRule].
  ManualCaptureRule({bool enabled = true}) : _enabled = enabled;

  @override
  String get id => 'manual';

  @override
  String get name => 'Manual capture';

  @override
  bool get isEnabled => _enabled;

  set isEnabled(bool value) => _enabled = value;

  /// Arms the rule for the next evaluation tick.
  void arm() => _armed = true;

  /// Whether a manual capture is waiting.
  bool get isArmed => _armed;

  @override
  CaptureDecision evaluate(FrameCaptureContext context) {
    if (!_enabled) return CaptureDecision.skip;
    if (!_armed && !context.manualRequested) return CaptureDecision.skip;
    if (!context.isSessionActive) return CaptureDecision.skip;
    // Manual capture is allowed even when capture-engine paused? Spec says
    // prevent capture when paused — skip.
    if (context.isSessionPaused || context.isCapturePaused) {
      return CaptureDecision.skip;
    }

    return CaptureDecision.capture(
      ruleId: id,
      message: 'Manual capture requested',
      type: CaptureType.manual,
    );
  }

  @override
  void onCaptured(FrameCaptureContext context) {
    _armed = false;
  }

  @override
  void reset() {
    _armed = false;
  }
}
