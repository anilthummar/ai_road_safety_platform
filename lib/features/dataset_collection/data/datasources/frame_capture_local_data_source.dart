import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_queue_manager.dart';

/// Memory-only queue access for frame acquisition (no disk).
abstract class FrameCaptureLocalDataSource {
  /// Underlying queue manager.
  FrameQueueManager get queue;

  /// Enqueue helper exposing [FrameEnqueueResult].
  FrameEnqueueResult enqueue(CapturedFrame frame);

  /// Dequeue oldest.
  CapturedFrame? dequeue();

  /// Clear queue.
  void clear();

  /// Current size.
  int get size;

  /// Max capacity.
  int get maxSize;

  /// Total accepted since last clearCounters / create.
  int get capturedCount;

  /// Total dropped / rejected since last reset.
  int get droppedCount;

  /// Increment dropped counter.
  void recordDrop();

  /// Increment captured counter (when enqueue succeeds).
  void recordCapture();

  /// Reset counters (on start capture).
  void resetCounters();

  /// Builds a [FrameQueueSnapshot] with optional FPS.
  FrameQueueSnapshot snapshot({double captureRateFps = 0});
}
