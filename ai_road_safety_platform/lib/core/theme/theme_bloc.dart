import 'package:ai_road_safety_platform/core/constants/app_constants.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Events that mutate the application [ThemeMode].
sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the persisted theme preference on app start.
class ThemeStarted extends ThemeEvent {
  const ThemeStarted();
}

/// Sets an explicit [ThemeMode] and persists it.
class ThemeModeChanged extends ThemeEvent {
  /// Desired theme mode.
  final ThemeMode mode;

  const ThemeModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Cycles system → light → dark → system.
class ThemeModeCycled extends ThemeEvent {
  const ThemeModeCycled();
}

/// Immutable theme presentation state.
class ThemeState extends Equatable {
  /// Active Flutter [ThemeMode].
  final ThemeMode themeMode;

  /// Whether preferences have finished loading.
  final bool isInitialized;

  const ThemeState({
    required this.themeMode,
    this.isInitialized = false,
  });

  /// Initial unresolved state before prefs load.
  const ThemeState.initial()
      : themeMode = ThemeMode.system,
        isInitialized = false;

  /// Returns a copy with selective overrides.
  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isInitialized,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => [themeMode, isInitialized];
}

/// Manages theme mode persistence with [SharedPreferences].
///
/// Belongs to core (not a business feature) so every feature can share it.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _prefs;
  final AppLogger _logger;

  /// Creates a [ThemeBloc] with injected [prefs] and [logger].
  ThemeBloc({
    required SharedPreferences prefs,
    required AppLogger logger,
  })  : _prefs = prefs,
        _logger = logger,
        super(const ThemeState.initial()) {
    on<ThemeStarted>(_onStarted);
    on<ThemeModeChanged>(_onModeChanged);
    on<ThemeModeCycled>(_onModeCycled);
  }

  Future<void> _onStarted(
    ThemeStarted event,
    Emitter<ThemeState> emit,
  ) async {
    final stored = _prefs.getString(AppConstants.themeModePrefsKey);
    final mode = _decode(stored) ?? ThemeMode.system;
    _logger.debug('Theme loaded: $mode', tag: 'ThemeBloc');
    emit(state.copyWith(themeMode: mode, isInitialized: true));
  }

  Future<void> _onModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await _prefs.setString(
      AppConstants.themeModePrefsKey,
      _encode(event.mode),
    );
    _logger.info('Theme changed: ${event.mode}', tag: 'ThemeBloc');
    emit(state.copyWith(themeMode: event.mode, isInitialized: true));
  }

  Future<void> _onModeCycled(
    ThemeModeCycled event,
    Emitter<ThemeState> emit,
  ) async {
    final next = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    add(ThemeModeChanged(next));
  }

  static String _encode(ThemeMode mode) => mode.name;

  static ThemeMode? _decode(String? value) {
    if (value == null) return null;
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}
