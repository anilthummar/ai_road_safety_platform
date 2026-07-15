import 'package:ai_road_safety_platform/core/theme/theme_bloc.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    bloc = ThemeBloc(prefs: prefs, logger: AppLogger());
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<ThemeBloc, ThemeState>(
    'loads system theme by default',
    build: () => bloc,
    act: (b) => b.add(const ThemeStarted()),
    expect: () => [
      const ThemeState(themeMode: ThemeMode.system, isInitialized: true),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'persists dark theme',
    build: () => bloc,
    seed: () => const ThemeState(themeMode: ThemeMode.system, isInitialized: true),
    act: (b) => b.add(const ThemeModeChanged(ThemeMode.dark)),
    expect: () => [
      const ThemeState(themeMode: ThemeMode.dark, isInitialized: true),
    ],
  );
}
