/// Immutable string / numeric constants that are not theme-token related.
///
/// Theme tokens live in [AppColors], [AppSpacing], and [AppDimensions].
class AppConstants {
  AppConstants._();

  /// SharedPreferences key for persisted [ThemeMode] preference.
  static const String themeModePrefsKey = 'app.theme_mode';

  /// Default animation duration for page / state transitions.
  static const Duration defaultAnimationDuration = Duration(milliseconds: 250);

  /// Slightly longer duration for hero / emphasis transitions.
  static const Duration emphasisAnimationDuration = Duration(milliseconds: 400);

  /// Debounce window for search / sensor sampling UIs.
  static const Duration defaultDebounce = Duration(milliseconds: 300);

  /// Maximum concurrent Dio requests (foundation; tune per environment).
  static const int maxConcurrentNetworkRequests = 8;

  /// Placeholder copy used by empty feature shells until Phase 2+.
  static const String phasePlaceholderMessage =
      'Feature will be implemented in a later phase.';
}
