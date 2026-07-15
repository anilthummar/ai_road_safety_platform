import 'dart:collection';

import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';

/// Strategy for admitting tasks when the queue is full.
enum BackpressurePolicy {
  /// Reject new tasks.
  reject,

  /// Drop oldest pending to admit newest.
  dropOldest,
}

/// Abstract task queue (Queue Pattern).
abstract class TaskQueue {
  String get name;
  int get length;
  int get capacity;
  bool get isFull;
  QueueMetrics get metrics;

  TaskEnqueueResult enqueue(PipelineTask task);
  PipelineTask? dequeue();
  PipelineTask? removeById(String id);
  bool containsId(String id);
  List<PipelineTask> snapshot();
  void clear();
}

/// Bounded FIFO queue with backpressure.
class FifoTaskQueue implements TaskQueue {
  @override
  final String name;
  @override
  final int capacity;
  final BackpressurePolicy backpressure;

  final Queue<PipelineTask> _q = Queue<PipelineTask>();
  final Set<String> _ids = {};
  int _overflow = 0;
  int _enqueued = 0;
  int _dequeued = 0;

  FifoTaskQueue({
    required this.name,
    this.capacity = 64,
    this.backpressure = BackpressurePolicy.dropOldest,
  }) {
    assert(capacity > 0);
  }

  @override
  int get length => _q.length;

  @override
  bool get isFull => _q.length >= capacity;

  @override
  QueueMetrics get metrics => QueueMetrics(
        name: name,
        length: length,
        capacity: capacity,
        overflowCount: _overflow,
        enqueuedTotal: _enqueued,
        dequeuedTotal: _dequeued,
      );

  @override
  bool containsId(String id) => _ids.contains(id);

  @override
  TaskEnqueueResult enqueue(PipelineTask task) {
    if (_ids.contains(task.id)) return TaskEnqueueResult.duplicate;

    if (_q.length >= capacity) {
      _overflow++;
      if (backpressure == BackpressurePolicy.reject) {
        return TaskEnqueueResult.overflowRejected;
      }
      final oldest = _q.removeFirst();
      _ids.remove(oldest.id);
      _q.addLast(task);
      _ids.add(task.id);
      _enqueued++;
      return TaskEnqueueResult.overflowDroppedOldest;
    }

    _q.addLast(task);
    _ids.add(task.id);
    _enqueued++;
    return TaskEnqueueResult.enqueued;
  }

  @override
  PipelineTask? dequeue() {
    if (_q.isEmpty) return null;
    final t = _q.removeFirst();
    _ids.remove(t.id);
    _dequeued++;
    return t;
  }

  @override
  PipelineTask? removeById(String id) {
    PipelineTask? found;
    final kept = <PipelineTask>[];
    while (_q.isNotEmpty) {
      final t = _q.removeFirst();
      if (t.id == id && found == null) {
        found = t;
      } else {
        kept.add(t);
      }
    }
    for (final t in kept) {
      _q.addLast(t);
    }
    if (found != null) {
      _ids.remove(id);
      _dequeued++;
    }
    return found;
  }

  @override
  List<PipelineTask> snapshot() => List.unmodifiable(_q.toList());

  @override
  void clear() {
    _q.clear();
    _ids.clear();
  }
}

/// Priority queue — higher [TaskPriority.weight] dequeues first.
class PriorityTaskQueue implements TaskQueue {
  @override
  final String name;
  @override
  final int capacity;
  final BackpressurePolicy backpressure;

  final List<PipelineTask> _items = [];
  final Set<String> _ids = {};
  int _overflow = 0;
  int _enqueued = 0;
  int _dequeued = 0;

  PriorityTaskQueue({
    required this.name,
    this.capacity = 64,
    this.backpressure = BackpressurePolicy.reject,
  }) {
    assert(capacity > 0);
  }

  @override
  int get length => _items.length;

  @override
  bool get isFull => _items.length >= capacity;

  @override
  QueueMetrics get metrics => QueueMetrics(
        name: name,
        length: length,
        capacity: capacity,
        overflowCount: _overflow,
        enqueuedTotal: _enqueued,
        dequeuedTotal: _dequeued,
      );

  @override
  bool containsId(String id) => _ids.contains(id);

  void _sort() {
    _items.sort((a, b) {
      final byPriority = b.priority.weight.compareTo(a.priority.weight);
      if (byPriority != 0) return byPriority;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  @override
  TaskEnqueueResult enqueue(PipelineTask task) {
    if (_ids.contains(task.id)) return TaskEnqueueResult.duplicate;

    if (_items.length >= capacity) {
      _overflow++;
      if (backpressure == BackpressurePolicy.reject) {
        return TaskEnqueueResult.overflowRejected;
      }
      // Drop lowest priority / oldest.
      _sort();
      final dropped = _items.removeLast();
      _ids.remove(dropped.id);
    }

    _items.add(task);
    _ids.add(task.id);
    _enqueued++;
    _sort();
    return _overflow > 0 && _items.length == capacity
        ? TaskEnqueueResult.overflowDroppedOldest
        : TaskEnqueueResult.enqueued;
  }

  @override
  PipelineTask? dequeue() {
    if (_items.isEmpty) return null;
    _sort();
    final t = _items.removeAt(0);
    _ids.remove(t.id);
    _dequeued++;
    return t;
  }

  @override
  PipelineTask? removeById(String id) {
    final idx = _items.indexWhere((t) => t.id == id);
    if (idx < 0) return null;
    final t = _items.removeAt(idx);
    _ids.remove(id);
    _dequeued++;
    return t;
  }

  @override
  List<PipelineTask> snapshot() {
    _sort();
    return List.unmodifiable(_items);
  }

  @override
  void clear() {
    _items.clear();
    _ids.clear();
  }
}
