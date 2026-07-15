import 'dart:collection';

import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/metadata_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// In-memory [MetadataLocalDataSource] with a bounded ring buffer.
class MemoryMetadataLocalDataSource implements MetadataLocalDataSource {
  final int maxRecent;
  final Queue<FrameMetadata> _recent = Queue<FrameMetadata>();
  final Map<String, int> _frameCounters = {};
  FrameMetadata? _latest;

  /// Creates [MemoryMetadataLocalDataSource].
  MemoryMetadataLocalDataSource({this.maxRecent = 50});

  @override
  void save(FrameMetadata metadata) {
    _latest = metadata;
    _recent.addLast(metadata);
    while (_recent.length > maxRecent) {
      _recent.removeFirst();
    }
  }

  @override
  FrameMetadata? get latest => _latest;

  @override
  List<FrameMetadata> get recent => List.unmodifiable(_recent.toList());

  @override
  int nextFrameNumber(String sessionId) {
    final next = (_frameCounters[sessionId] ?? 0) + 1;
    _frameCounters[sessionId] = next;
    return next;
  }

  @override
  void clear() {
    _latest = null;
    _recent.clear();
    _frameCounters.clear();
  }

  @override
  int get count => _recent.length;
}
