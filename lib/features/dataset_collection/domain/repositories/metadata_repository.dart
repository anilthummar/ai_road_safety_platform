import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// Domain contract for in-memory frame metadata (Phase 12.4).
abstract class MetadataRepository {
  /// Synchronizes sensors and builds [FrameMetadata] for [frame].
  Future<Result<FrameMetadata>> generateMetadata(CapturedFrame frame);

  /// Alias of [generateMetadata] for explicit sync API.
  Future<Result<FrameMetadata>> synchronizeMetadata(CapturedFrame frame);

  /// Returns the latest generated metadata, if any.
  Future<Result<FrameMetadata?>> getLatestMetadata();

  /// Clears the in-memory metadata buffer.
  Future<Result<void>> clearMetadata();

  /// Sensor liveness for developer UI.
  SensorStatusSnapshot get sensorStatus;
}
