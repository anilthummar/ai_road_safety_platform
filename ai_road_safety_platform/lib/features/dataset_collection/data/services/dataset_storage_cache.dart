import 'dart:collection';
import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// Bounded in-memory caches for hot metadata / thumbnails / session ids.
class DatasetStorageCache {
  final int maxEntries;
  final LinkedHashMap<String, FrameMetadata> _metadata = LinkedHashMap();
  final LinkedHashMap<String, Uint8List> _thumbnails = LinkedHashMap();
  final LinkedHashSet<String> _sessions = LinkedHashSet();

  /// Creates [DatasetStorageCache].
  DatasetStorageCache({this.maxEntries = 64});

  /// Cache key for a frame.
  static String frameKey(String sessionId, int frameNumber) =>
      '$sessionId#$frameNumber';

  void putMetadata(String sessionId, int frameNumber, FrameMetadata value) {
    _put(_metadata, frameKey(sessionId, frameNumber), value);
    _sessions.add(sessionId);
  }

  FrameMetadata? getMetadata(String sessionId, int frameNumber) =>
      _metadata[frameKey(sessionId, frameNumber)];

  void putThumbnail(String sessionId, int frameNumber, Uint8List bytes) {
    _put(_thumbnails, frameKey(sessionId, frameNumber), bytes);
  }

  Uint8List? getThumbnail(String sessionId, int frameNumber) =>
      _thumbnails[frameKey(sessionId, frameNumber)];

  void rememberSession(String sessionId) => _sessions.add(sessionId);

  bool hasSession(String sessionId) => _sessions.contains(sessionId);

  /// Clears all caches.
  void clear() {
    _metadata.clear();
    _thumbnails.clear();
    _sessions.clear();
  }

  void _put<V>(LinkedHashMap<String, V> map, String key, V value) {
    map.remove(key);
    map[key] = value;
    while (map.length > maxEntries) {
      map.remove(map.keys.first);
    }
  }
}
