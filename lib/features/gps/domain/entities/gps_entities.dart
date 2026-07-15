import 'package:equatable/equatable.dart';

/// Location permission status independent of the Geolocator plugin.
enum GpsPermissionStatus {
  /// Permission granted (when-in-use or always).
  granted,

  /// Denied but can ask again.
  denied,

  /// Permanently denied — open settings.
  permanentlyDenied,

  /// Restricted by parental controls / MDM.
  restricted,

  /// Unable to determine.
  unknown,
}

/// Location service (GPS radio) availability.
enum GpsServiceStatus {
  /// Device location services are on.
  enabled,

  /// Device location services are off.
  disabled,
}

/// Immutable GNSS fix with accuracy, altitude, speed, and heading.
class GpsFix extends Equatable {
  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Horizontal accuracy in meters (smaller is better).
  final double accuracyMeters;

  /// Altitude in meters above the WGS84 ellipsoid (nullable when unknown).
  final double? altitudeMeters;

  /// Speed in meters per second (nullable / 0 when stationary / unknown).
  final double? speedMetersPerSecond;

  /// Heading / bearing in degrees \[0–360) (nullable when unknown).
  final double? headingDegrees;

  /// Fix timestamp.
  final DateTime timestamp;

  /// True when the platform reports a mocked / fake location.
  final bool isMocked;

  /// Creates a [GpsFix].
  const GpsFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    this.altitudeMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
    this.isMocked = false,
  });

  /// Speed in km/h when [speedMetersPerSecond] is available.
  double? get speedKmh {
    final speed = speedMetersPerSecond;
    if (speed == null) return null;
    return speed * 3.6;
  }

  /// Human-readable coordinate pair.
  String get coordinateLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracyMeters,
        altitudeMeters,
        speedMetersPerSecond,
        headingDegrees,
        timestamp,
        isMocked,
      ];
}

/// Live GPS session snapshot for Bloc / HUD.
class GpsSession extends Equatable {
  /// Whether continuous updates are running.
  final bool isStreaming;

  /// Whether the device location service is enabled.
  final bool isServiceEnabled;

  /// Latest fix, if any.
  final GpsFix? latestFix;

  /// Number of fixes received in this session.
  final int fixCount;

  /// Creates a [GpsSession].
  const GpsSession({
    required this.isStreaming,
    required this.isServiceEnabled,
    this.latestFix,
    this.fixCount = 0,
  });

  /// Idle factory.
  const GpsSession.idle({this.isServiceEnabled = false})
      : isStreaming = false,
        latestFix = null,
        fixCount = 0;

  /// Copy helper.
  GpsSession copyWith({
    bool? isStreaming,
    bool? isServiceEnabled,
    GpsFix? latestFix,
    int? fixCount,
    bool clearFix = false,
  }) {
    return GpsSession(
      isStreaming: isStreaming ?? this.isStreaming,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      latestFix: clearFix ? null : (latestFix ?? this.latestFix),
      fixCount: fixCount ?? this.fixCount,
    );
  }

  @override
  List<Object?> get props => [
        isStreaming,
        isServiceEnabled,
        latestFix,
        fixCount,
      ];
}

/// Configuration for continuous GNSS updates.
class GpsTrackingConfig {
  GpsTrackingConfig._();

  /// Desired horizontal accuracy for risk fusion.
  static const double distanceFilterMeters = 5;

  /// Timeout for one-shot current position.
  static const Duration currentPositionTimeout = Duration(seconds: 15);
}
