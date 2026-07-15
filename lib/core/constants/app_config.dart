/// Application-wide configuration values for the AI Road Safety Platform.
///
/// Values here are compile-time / environment defaults. Runtime overrides
/// (remote config, feature flags) should live in a dedicated service later.
class AppConfig {
  AppConfig._();

  /// Human-readable product name shown in UI chrome and store metadata.
  static const String appName = 'AI Road Safety Platform';

  /// Short product name for constrained spaces (app bar, notifications).
  static const String appShortName = 'AI Road Safety';

  /// Semantic version mirrored from [pubspec.yaml] for diagnostics UI.
  static const String appVersion = '1.0.0';

  /// Build number mirrored from [pubspec.yaml] for support tickets.
  static const String buildNumber = '1';

  /// Reverse-DNS application identifier.
  static const String applicationId = 'com.airoadsafety.platform';

  /// Default REST base URL — replace per flavor in later phases.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.airoadsafety.local/v1',
  );

  /// HTTP connect timeout for Dio.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// HTTP receive timeout for Dio.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// HTTP send timeout for Dio.
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Enables verbose logging outside release builds.
  static const bool enableVerboseLogging = bool.fromEnvironment(
    'VERBOSE_LOGGING',
    defaultValue: true,
  );

  /// Research project display title.
  static const String researchTitle =
      'Flooded Road & Hidden Hazard Detection using Artificial Intelligence';
}
