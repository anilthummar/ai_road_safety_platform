import 'dart:collection';

import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';

/// Result of an enqueue attempt.
enum FrameEnqueueResult {
  /// Frame accepted.
  enqueued,

  /// Accepted after dropping the oldest frame (queue was full).
  enqueuedDroppedOldest,

  /// Rejected — duplicate [CapturedFrame.frameId].
  duplicateId,

  /// Rejected — duplicate [CapturedFrame.cameraSequence] in session.
  duplicateSequence,
}

/// In-memory FIFO frame queue with bounded capacity (Phase 12.3).
///
/// When full, discards the oldest frame to admit the newest (overflow policy).
class FrameQueueManager {
  /// Maximum frames retained.
  final int maxSize;

  final Queue<CapturedFrame> _queue = Queue<CapturedFrame>();
  final Set<String> _ids = <String>{};
  final Set<String> _sequences = <String>{};

  /// Creates [FrameQueueManager].
  FrameQueueManager({this.maxSize = 30}) {
    assert(maxSize > 0, 'maxSize must be > 0');
  }

  /// Current length.
  int get size => _queue.length;

  /// True when at capacity before the next insert.
  bool get isFull => _queue.length >= maxSize;

  /// FIFO snapshot (oldest first).
  List<CapturedFrame> get frames => List.unmodifiable(_queue.toList());

  /// Enqueues [frame]; may drop oldest when full.
  FrameEnqueueResult enqueue(CapturedFrame frame) {
    if (_ids.contains(frame.frameId)) {
      return FrameEnqueueResult.duplicateId;
    }
    final seqKey = _sequenceKey(frame);
    if (seqKey != null && _sequences.contains(seqKey)) {
      return FrameEnqueueResult.duplicateSequence;
    }

    var droppedOldest = false;
    while (_queue.length >= maxSize) {
      final oldest = _queue.removeFirst();
      _ids.remove(oldest.frameId);
      final oldKey = _sequenceKey(oldest);
      if (oldKey != null) _sequences.remove(oldKey);
      droppedOldest = true;
    }

    _queue.addLast(frame);
    _ids.add(frame.frameId);
    if (seqKey != null) _sequences.add(seqKey);

    return droppedOldest
        ? FrameEnqueueResult.enqueuedDroppedOldest
        : FrameEnqueueResult.enqueued;
  }

  /// Removes and returns the oldest frame, or null.
  CapturedFrame? dequeue() {
    if (_queue.isEmpty) return null;
    final frame = _queue.removeFirst();
    _ids.remove(frame.frameId);
    final key = _sequenceKey(frame);
    if (key != null) _sequences.remove(key);
    return frame;
  }

  /// Clears the queue.
  void clear() {
    _queue.clear();
    _ids.clear();
    _sequences.clear();
  }

  String? _sequenceKey(CapturedFrame frame) {
    final seq = frame.cameraSequence;
    if (seq == null) return null;
    return '${frame.sessionId}#$seq';
  }
}
