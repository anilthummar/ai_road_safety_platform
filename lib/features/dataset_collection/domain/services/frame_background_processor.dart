/// Placeholder for future isolate / compute offload of frame preprocessing.
///
/// Phase 12.3 keeps acquisition on the async event queue only — no
/// [Isolate.spawn] / [compute] yet. Call sites go through this facade so
/// later phases can swap in real background work without touching the bloc.
abstract class FrameBackgroundProcessor {
  /// Schedules [work] without blocking the UI isolate event loop.
  Future<T> runAsync<T>(Future<T> Function() work);

  /// Releases resources.
  void dispose();
}

/// Default processor — schedules work as a microtask / await chain.
class FrameBackgroundProcessorImpl implements FrameBackgroundProcessor {
  bool _disposed = false;

  @override
  Future<T> runAsync<T>(Future<T> Function() work) async {
    if (_disposed) {
      throw StateError('FrameBackgroundProcessor disposed');
    }
    // Placeholder: future isolate hop goes here.
    return work();
  }

  @override
  void dispose() {
    _disposed = true;
  }
}
