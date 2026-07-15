import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';

/// Domain contract for YOLOv8 TFLite real-time inference.
abstract class InferenceRepository {
  /// Loads model, labels, and hardware delegates.
  Future<Result<InferenceSession>> initialize();

  /// Starts consuming camera raw frames for inference.
  Future<Result<InferenceSession>> start();

  /// Stops consuming frames (keeps model warm).
  Future<Result<InferenceSession>> stop();

  /// Releases interpreter and subscriptions.
  Future<Result<void>> disposeEngine();

  /// Runs one-shot inference on an already-captured raw frame (tests / burst).
  Future<Result<InferenceResult>> detect(CameraRawFrame frame);

  /// Live result stream for overlay UI.
  Stream<InferenceResult> watchResults();

  /// Session / metrics stream for HUD.
  Stream<InferenceSession> watchSession();
}
