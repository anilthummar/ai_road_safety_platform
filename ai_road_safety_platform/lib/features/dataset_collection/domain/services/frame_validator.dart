import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';

/// Why a frame was rejected by [FrameValidator].
enum FrameRejectReason {
  /// Missing camera metadata.
  nullFrame,

  /// Dimensions look corrupt / zero.
  corrupted,

  /// Below configured resolution.
  lowResolution,

  /// Same camera sequence already seen.
  duplicate,

  /// Dataset session paused.
  sessionPaused,

  /// No active unfinished session.
  sessionInactive,

  /// Acquisition engine is paused / stopped.
  captureInactive,
}

/// Result of validating an incoming camera frame.
class FrameValidationResult {
  /// Whether the frame may proceed to the rule engine.
  final bool isValid;

  /// Reject reason when invalid.
  final FrameRejectReason? reason;

  const FrameValidationResult._(this.isValid, this.reason);

  /// Valid frame.
  static const FrameValidationResult valid = FrameValidationResult._(true, null);

  /// Invalid frame.
  factory FrameValidationResult.invalid(FrameRejectReason reason) {
    return FrameValidationResult._(false, reason);
  }
}

/// Stateless validators for the acquisition pipeline.
class FrameValidator {
  /// Capture config (min resolution).
  final FrameCaptureConfig config;

  /// Creates [FrameValidator].
  const FrameValidator({this.config = const FrameCaptureConfig()});

  /// Validates [frame] against session / engine flags.
  FrameValidationResult validate({
    required CameraFrameMeta? frame,
    required bool isSessionActive,
    required bool isSessionPaused,
    required bool isCaptureActive,
    required bool isCapturePaused,
    required bool Function(int sequence) isDuplicateSequence,
  }) {
    if (!isSessionActive) {
      return FrameValidationResult.invalid(FrameRejectReason.sessionInactive);
    }
    if (isSessionPaused) {
      return FrameValidationResult.invalid(FrameRejectReason.sessionPaused);
    }
    if (!isCaptureActive || isCapturePaused) {
      return FrameValidationResult.invalid(FrameRejectReason.captureInactive);
    }
    if (frame == null) {
      return FrameValidationResult.invalid(FrameRejectReason.nullFrame);
    }
    if (frame.width <= 0 || frame.height <= 0) {
      return FrameValidationResult.invalid(FrameRejectReason.corrupted);
    }
    if (frame.width < config.minWidth || frame.height < config.minHeight) {
      return FrameValidationResult.invalid(FrameRejectReason.lowResolution);
    }
    if (isDuplicateSequence(frame.sequence)) {
      return FrameValidationResult.invalid(FrameRejectReason.duplicate);
    }
    return FrameValidationResult.valid;
  }
}
