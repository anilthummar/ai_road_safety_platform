import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_queues.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineTask _task(String id, {TaskPriority priority = TaskPriority.normal}) {
  return PipelineTask(
    id: id,
    stage: PipelineStageKind.metadata,
    name: id,
    priority: priority,
    createdAt: DateTime.utc(2026, 7, 14),
  );
}

void main() {
  group('FifoTaskQueue', () {
    test('FIFO order and duplicate rejection', () {
      final q = FifoTaskQueue(name: 'fifo', capacity: 3);
      expect(q.enqueue(_task('a')), TaskEnqueueResult.enqueued);
      expect(q.enqueue(_task('b')), TaskEnqueueResult.enqueued);
      expect(q.enqueue(_task('a')), TaskEnqueueResult.duplicate);
      expect(q.dequeue()?.id, 'a');
      expect(q.dequeue()?.id, 'b');
    });

    test('dropOldest backpressure', () {
      final q = FifoTaskQueue(
        name: 'fifo',
        capacity: 2,
        backpressure: BackpressurePolicy.dropOldest,
      );
      q.enqueue(_task('a'));
      q.enqueue(_task('b'));
      expect(q.enqueue(_task('c')), TaskEnqueueResult.overflowDroppedOldest);
      expect(q.snapshot().map((t) => t.id), ['b', 'c']);
      expect(q.metrics.overflowCount, 1);
    });

    test('reject backpressure', () {
      final q = FifoTaskQueue(
        name: 'fifo',
        capacity: 1,
        backpressure: BackpressurePolicy.reject,
      );
      q.enqueue(_task('a'));
      expect(q.enqueue(_task('b')), TaskEnqueueResult.overflowRejected);
    });
  });

  group('PriorityTaskQueue', () {
    test('critical dequeues before low', () {
      final q = PriorityTaskQueue(name: 'prio', capacity: 8);
      q.enqueue(_task('low', priority: TaskPriority.low));
      q.enqueue(_task('crit', priority: TaskPriority.critical));
      q.enqueue(_task('high', priority: TaskPriority.high));
      expect(q.dequeue()?.id, 'crit');
      expect(q.dequeue()?.id, 'high');
      expect(q.dequeue()?.id, 'low');
    });
  });
}
