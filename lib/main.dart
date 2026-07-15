import 'dart:async';

import 'package:ai_road_safety_platform/app.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/app_bloc_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Application entry point.
///
/// Bootstraps dependency injection, global error handlers, and Bloc observer
/// before inflating [AiRoadSafetyApp].
Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await configureDependencies();

    final logger = sl<AppLogger>();
    Bloc.observer = AppBlocObserver(logger: logger);

    FlutterError.onError = (details) {
      logger.error(
        'FlutterError: ${details.exceptionAsString()}',
        tag: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error(
        'PlatformDispatcher error',
        tag: 'Platform',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    logger.info('AI Road Safety Platform starting', tag: 'Bootstrap');
    runApp(const AiRoadSafetyApp());
  }, (error, stack) {
    // Fallback when GetIt is not yet ready mid-bootstrap.
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}
