import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global [BlocObserver] that logs transitions and errors.
///
/// Registered once in [main] so every feature bloc is observable in debug.
/// High-frequency stream fan-in events are not logged (they flood logcat).
class AppBlocObserver extends BlocObserver {
  /// Logger used for bloc telemetry.
  final AppLogger logger;

  /// Creates an observer bound to [logger].
  AppBlocObserver({required this.logger});

  static const _noisyEventSuffixes = <String>{
    'HudUpdated',
    'FixUpdated',
    'SampleUpdated',
    'SessionUpdated',
    'ResultUpdated',
    'AssessmentUpdated',
    'FrameStreamingStarted',
  };

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    logger.debug('onCreate → ${bloc.runtimeType}', tag: 'Bloc');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (_isNoisy(event)) return;
    logger.verbose(
      'onEvent → ${bloc.runtimeType}: $event',
      tag: 'Bloc',
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // Skip Active→Active (same type) spam from high-rate sensor fans.
    if (change.currentState.runtimeType == change.nextState.runtimeType &&
        '${change.nextState.runtimeType}'.endsWith('Active')) {
      return;
    }
    logger.verbose(
      'onChange → ${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      tag: 'Bloc',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    logger.error(
      'onError → ${bloc.runtimeType}',
      tag: 'Bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    logger.debug('onClose → ${bloc.runtimeType}', tag: 'Bloc');
    super.onClose(bloc);
  }

  bool _isNoisy(Object? event) {
    if (event == null) return false;
    final name = event.runtimeType.toString();
    for (final suffix in _noisyEventSuffixes) {
      if (name.endsWith(suffix)) return true;
    }
    return false;
  }
}
