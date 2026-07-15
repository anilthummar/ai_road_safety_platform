import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:equatable/equatable.dart';

/// Input context passed to every [CaptureRule] evaluation.
class FrameCaptureContext extends Equatable {
  /// Latest camera metadata (null for pure-manual synthetic captures).
  final CameraFrameMeta? frame;

  /// Active dataset session id.
  final String sessionId;

  /// Session is recording (not idle/stopped).
  final bool isSessionActive;

  /// Session is paused — rules must not auto-capture.
  final bool isSessionPaused;

  /// Acquisition engine is paused.
  final bool isCapturePaused;

  /// Manual capture was requested this tick.
  final bool manualRequested;

  /// Evaluation time.
  final DateTime now;

  /// Lens label for output frames.
  final String lensDirection;

  /// Sensor rotation degrees.
  final int rotationDegrees;

  /// Creates [FrameCaptureContext].
  const FrameCaptureContext({
    required this.sessionId,
    required this.isSessionActive,
    required this.isSessionPaused,
    required this.isCapturePaused,
    required this.manualRequested,
    required this.now,
    required this.lensDirection,
    required this.rotationDegrees,
    this.frame,
  });

  @override
  List<Object?> get props => [
        frame,
        sessionId,
        isSessionActive,
        isSessionPaused,
        isCapturePaused,
        manualRequested,
        now,
        lensDirection,
        rotationDegrees,
      ];
}

/// Decision returned by a [CaptureRule].
class CaptureDecision extends Equatable {
  /// Whether to admit a frame.
  final bool shouldCapture;

  /// Optional reason when [shouldCapture] is true.
  final CaptureReason? reason;

  /// Creates [CaptureDecision].
  const CaptureDecision({
    required this.shouldCapture,
    this.reason,
  });

  /// Negative decision.
  static const CaptureDecision skip = CaptureDecision(shouldCapture: false);

  /// Positive decision helper.
  factory CaptureDecision.capture({
    required String ruleId,
    required String message,
    required CaptureType type,
  }) {
    return CaptureDecision(
      shouldCapture: true,
      reason: CaptureReason(ruleId: ruleId, message: message, type: type),
    );
  }

  @override
  List<Object?> get props => [shouldCapture, reason];
}

/// Modular capture rule — add new rules without changing the engine.
abstract class CaptureRule {
  /// Stable rule id.
  String get id;

  /// Display name.
  String get name;

  /// Whether the rule participates in evaluation.
  bool get isEnabled;

  /// Evaluates the current frame / session context.
  CaptureDecision evaluate(FrameCaptureContext context);

  /// Called after a successful enqueue driven by this rule (optional).
  void onCaptured(FrameCaptureContext context) {}

  /// Reset internal state when capture starts / stops.
  void reset() {}
}
