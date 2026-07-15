import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// Memory-only store for generated [FrameMetadata] (Phase 12.4 — no disk).
abstract class MetadataLocalDataSource {
  /// Saves generated metadata as latest + appends to ring buffer.
  void save(FrameMetadata metadata);

  /// Latest generated metadata, if any.
  FrameMetadata? get latest;

  /// Recent metadata (newest last), capped.
  List<FrameMetadata> get recent;

  /// Next frame number for [sessionId].
  int nextFrameNumber(String sessionId);

  /// Clears all in-memory metadata and counters.
  void clear();

  /// Count of stored metadata objects.
  int get count;
}
