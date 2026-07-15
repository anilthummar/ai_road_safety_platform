import 'package:ai_road_safety_platform/core/services/app_logger.dart';

/// Abstraction for offloading work (isolates later; inline today).
abstract class BackgroundWorker {
  String get id;
  bool get isBusy;
  Future<T> run<T>(Future<T> Function() work);
  void dispose();
}

/// Inline worker — same isolate, non-blocking via async await.
class InlineBackgroundWorker implements BackgroundWorker {
  @override
  final String id;
  final AppLogger? logger;
  bool _busy = false;
  bool _disposed = false;

  InlineBackgroundWorker({required this.id, this.logger});

  @override
  bool get isBusy => _busy;

  @override
  Future<T> run<T>(Future<T> Function() work) async {
    if (_disposed) {
      throw StateError('Worker $id disposed');
    }
    _busy = true;
    try {
      return await work();
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
  }
}

/// Pool of workers for edge-compute isolation architecture.
class WorkerPool {
  final int size;
  final AppLogger? logger;
  final List<BackgroundWorker> _workers = [];

  WorkerPool({this.size = 2, this.logger}) {
    for (var i = 0; i < size; i++) {
      _workers.add(InlineBackgroundWorker(id: 'worker-$i', logger: logger));
    }
  }

  int get activeCount => _workers.where((w) => w.isBusy).length;

  int get capacity => _workers.length;

  /// Picks a free worker or waits on the least recently used.
  Future<BackgroundWorker> acquire() async {
    for (final w in _workers) {
      if (!w.isBusy) return w;
    }
    // All busy — return first; caller still awaits sequentially per worker.
    return _workers.first;
  }

  Future<T> run<T>(Future<T> Function() work) async {
    final worker = await acquire();
    return worker.run(work);
  }

  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
  }
}

/// Dispatches tasks onto the worker pool (isolate-ready boundary).
class TaskDispatcher {
  final WorkerPool pool;
  final AppLogger? logger;

  TaskDispatcher({required this.pool, this.logger});

  Future<T> dispatch<T>(Future<T> Function() work) {
    logger?.debug('Dispatch → worker pool', tag: 'Pipeline');
    return pool.run(work);
  }

  void dispose() => pool.dispose();
}
