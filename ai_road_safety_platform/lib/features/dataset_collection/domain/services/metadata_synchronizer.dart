import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// Latest sensor buffers used at capture time (Phase 12.4).
class SensorSnapshotBundle {
  /// Latest GPS location metadata (or missing).
  final LocationMetadata location;

  /// Latest motion metadata (or missing).
  final MotionMetadata motion;

  /// Latest inference metadata (or missing).
  final InferenceMetadata inference;

  /// Device / battery / app.
  final DeviceMetadata device;

  /// Sensor liveness flags.
  final SensorStatusSnapshot sensorStatus;

  /// Creates [SensorSnapshotBundle].
  const SensorSnapshotBundle({
    required this.location,
    required this.motion,
    required this.inference,
    required this.device,
    required this.sensorStatus,
  });
}

/// Collects / refreshes sensor snapshots for [MetadataSynchronizer].
abstract class SensorSnapshotProvider {
  /// Fetches the best-effort sensor bundle at [at] for frame [frame].
  Future<SensorSnapshotBundle> collect({
    required CapturedFrame frame,
    required DateTime at,
  });

  /// Current liveness without a full collect.
  SensorStatusSnapshot get status;

  /// Starts background cache listeners (idempotent).
  void start();

  /// Stops listeners.
  void stop();
}

/// Merges a [CapturedFrame] with sensor snapshots into [FrameMetadata].
abstract class MetadataSynchronizer {
  /// Builds synchronized metadata for [frame] with [frameNumber].
  Future<FrameMetadata> synchronize({
    required CapturedFrame frame,
    required int frameNumber,
  });
}
