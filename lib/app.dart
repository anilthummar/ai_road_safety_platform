import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/theme/app_theme.dart';
import 'package:ai_road_safety_platform/core/theme/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root application widget.
///
/// Wires [ThemeBloc], Material 3 themes, and [GoRouter].
class AiRoadSafetyApp extends StatelessWidget {
  /// Creates the root [AiRoadSafetyApp].
  const AiRoadSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ThemeBloc>()..add(const ThemeStarted()),
      child: BlocSelector<ThemeBloc, ThemeState, ThemeMode>(
        selector: (state) => state.themeMode,
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: sl<GoRouter>(),
          );
        },
      ),
    );
  }
}
