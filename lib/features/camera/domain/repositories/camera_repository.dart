import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';

/// Domain contract for camera permission, lifecycle, preview session, and frames.
///
/// Implementations live in the data layer and must not leak plugin types here.
abstract class CameraRepository {
  /// Checks current camera permission without prompting.
  Future<Result<CameraPermissionStatus>> checkPermission();

  /// Requests camera permission from the OS.
  Future<Result<CameraPermissionStatus>> requestPermission();

  /// Opens system settings when permission is permanently denied.
  Future<Result<bool>> openPermissionSettings();

  /// Initializes the preferred lens (default rear) and starts preview-ready session.
  Future<Result<CameraSession>> initialize({
    CameraLensPreference lens = CameraLensPreference.rear,
  });

  /// Pauses preview and stops frame streaming (background / explicit pause).
  Future<Result<CameraSession>> pause();

  /// Resumes preview after [pause].
  Future<Result<CameraSession>> resume();

  /// Starts throttled frame metadata streaming for future AI consumers.
  Future<Result<CameraSession>> startFrameStreaming({
    int targetFps = 8,
  });

  /// Stops image stream while keeping preview alive when possible.
  Future<Result<CameraSession>> stopFrameStreaming();

  /// Releases camera hardware resources.
  Future<Result<void>> disposeCamera();

  /// Notifies the repository that device orientation changed (degrees).
  Future<Result<CameraSession>> handleOrientationChanged(int degrees);

  /// Emits session snapshots when pause/resume/stream state changes.
  Stream<CameraSession> watchSession();

  /// Emits throttled frame metadata (never holds pixel buffers).
  Stream<CameraFrameMeta> watchFrames();

  /// Emits owned pixel-plane copies for AI inference (throttled).
  Stream<CameraRawFrame> watchRawFrames();
}
