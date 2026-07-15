import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';

/// Domain contract for flooded-road semantic segmentation.
abstract class FloodDetectionRepository {
  /// Loads the segmentation model, labels, and delegates.
  Future<Result<FloodDetectionSession>> initialize();

  /// Starts live segmentation on camera raw frames.
  Future<Result<FloodDetectionSession>> start();

  /// Stops live segmentation (keeps model warm).
  Future<Result<FloodDetectionSession>> stop();

  /// Releases interpreter resources.
  Future<Result<void>> disposeEngine();

  /// One-shot segmentation (tests / burst).
  Future<Result<FloodSegmentationResult>> segment(CameraRawFrame frame);

  /// Live segmentation results for overlay + stats.
  Stream<FloodSegmentationResult> watchResults();

  /// Session / metrics stream.
  Stream<FloodDetectionSession> watchSession();
}
