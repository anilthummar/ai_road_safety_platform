import 'dart:async';

/// Tracks recording elapsed time without coupling the UI to [Timer].
///
/// Supports start / pause / resume / stop / reset with a broadcast
/// [elapsedStream] for the Bloc.
abstract class SessionTimerService {
  /// Live elapsed duration while running (and last value when paused).
  Stream<Duration> get elapsedStream;

  /// Current elapsed snapshot.
  Duration get elapsed;

  /// Whether the ticker is currently advancing.
  bool get isRunning;

  /// Starts (or restarts) from [seed].
  void start({Duration seed = Duration.zero});

  /// Pauses without clearing elapsed.
  void pause();

  /// Continues from the paused elapsed value.
  void resume();

  /// Stops the ticker (keeps elapsed until [reset]).
  void stop();

  /// Clears elapsed back to zero and stops.
  void reset();

  /// Releases subscriptions / ticker.
  void dispose();
}

/// Default [SessionTimerService] using a periodic [Timer].
class SessionTimerServiceImpl implements SessionTimerService {
  final StreamController<Duration> _controller =
      StreamController<Duration>.broadcast();

  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  DateTime? _segmentStartedAt;
  bool _running = false;

  @override
  Stream<Duration> get elapsedStream => _controller.stream;

  @override
  Duration get elapsed => _running ? _currentElapsed() : _elapsed;

  @override
  bool get isRunning => _running;

  @override
  void start({Duration seed = Duration.zero}) {
    _ticker?.cancel();
    _elapsed = seed;
    _segmentStartedAt = DateTime.now();
    _running = true;
    _emit();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
  }

  @override
  void pause() {
    if (!_running) return;
    _elapsed = _currentElapsed();
    _running = false;
    _segmentStartedAt = null;
    _ticker?.cancel();
    _ticker = null;
    _emit();
  }

  @override
  void resume() {
    if (_running) return;
    _segmentStartedAt = DateTime.now();
    _running = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
    _emit();
  }

  @override
  void stop() {
    if (_running) {
      _elapsed = _currentElapsed();
    }
    _running = false;
    _segmentStartedAt = null;
    _ticker?.cancel();
    _ticker = null;
    _emit();
  }

  @override
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _running = false;
    _segmentStartedAt = null;
    _elapsed = Duration.zero;
    _emit();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }

  Duration _currentElapsed() {
    final started = _segmentStartedAt;
    if (!_running || started == null) return _elapsed;
    return _elapsed + DateTime.now().difference(started);
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(elapsed);
  }
}
