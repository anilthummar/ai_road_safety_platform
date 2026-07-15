import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/frame_capture_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_queue_manager.dart';

/// In-memory [FrameCaptureLocalDataSource] — never writes to disk.
class MemoryFrameCaptureLocalDataSource implements FrameCaptureLocalDataSource {
  late FrameQueueManager _queue;
  int _capturedCount = 0;
  int _droppedCount = 0;

  /// Creates [MemoryFrameCaptureLocalDataSource].
  MemoryFrameCaptureLocalDataSource({
    int maxQueueSize = 30,
  }) : _queue = FrameQueueManager(maxSize: maxQueueSize);

  /// Rebuilds the queue with a new capacity (call while idle).
  void reconfigure({required int maxQueueSize}) {
    final old = _queue.frames;
    _queue = FrameQueueManager(maxSize: maxQueueSize);
    for (final frame in old) {
      _queue.enqueue(frame);
    }
  }

  @override
  FrameQueueManager get queue => _queue;

  @override
  FrameEnqueueResult enqueue(CapturedFrame frame) => _queue.enqueue(frame);

  @override
  CapturedFrame? dequeue() => _queue.dequeue();

  @override
  void clear() => _queue.clear();

  @override
  int get size => _queue.size;

  @override
  int get maxSize => _queue.maxSize;

  @override
  int get capturedCount => _capturedCount;

  @override
  int get droppedCount => _droppedCount;

  @override
  void recordDrop() => _droppedCount++;

  @override
  void recordCapture() => _capturedCount++;

  @override
  void resetCounters() {
    _capturedCount = 0;
    _droppedCount = 0;
  }

  @override
  FrameQueueSnapshot snapshot({double captureRateFps = 0}) {
    return FrameQueueSnapshot(
      size: size,
      maxSize: maxSize,
      capturedCount: _capturedCount,
      droppedCount: _droppedCount,
      captureRateFps: captureRateFps,
    );
  }
}
