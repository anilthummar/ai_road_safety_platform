import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/session_timer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionTimerServiceImpl timer;

  setUp(() {
    timer = SessionTimerServiceImpl();
  });

  tearDown(() {
    timer.dispose();
  });

  test('start emits seed and advances while running', () async {
    final events = <Duration>[];
    final sub = timer.elapsedStream.listen(events.add);

    timer.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(timer.isRunning, isTrue);
    expect(timer.elapsed.inMilliseconds, greaterThanOrEqualTo(0));

    timer.pause();
    final pausedAt = timer.elapsed;
    expect(timer.isRunning, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(timer.elapsed, pausedAt);

    timer.resume();
    expect(timer.isRunning, isTrue);

    timer.stop();
    expect(timer.isRunning, isFalse);

    timer.reset();
    expect(timer.elapsed, Duration.zero);

    await sub.cancel();
    expect(events, isNotEmpty);
  });

  test('start with seed restores previous duration', () {
    timer.start(seed: const Duration(minutes: 2, seconds: 30));
    expect(timer.elapsed.inSeconds, greaterThanOrEqualTo(150));
    timer.pause();
    expect(timer.elapsed.inSeconds, greaterThanOrEqualTo(150));
  });
}
