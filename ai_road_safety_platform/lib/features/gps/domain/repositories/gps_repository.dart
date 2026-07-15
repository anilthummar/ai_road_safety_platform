import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';

/// Domain contract for GNSS permissions, one-shot fixes, and continuous tracking.
abstract class GpsRepository {
  /// Checks location permission without prompting.
  Future<Result<GpsPermissionStatus>> checkPermission();

  /// Requests location permission.
  Future<Result<GpsPermissionStatus>> requestPermission();

  /// Opens the app's system settings page (for permanently denied permission).
  Future<Result<bool>> openPermissionSettings();

  /// Opens the OS Location / GPS toggle screen.
  Future<Result<bool>> openLocationSettings();

  /// Whether device location services are enabled.
  Future<Result<bool>> isServiceEnabled();

  /// Requests the current position once.
  Future<Result<GpsFix>> getCurrentLocation();

  /// Starts continuous position updates.
  Future<Result<GpsSession>> startTracking();

  /// Stops continuous position updates.
  Future<Result<GpsSession>> stopTracking();

  /// Releases stream subscriptions.
  Future<Result<void>> disposeGps();

  /// Live fixes for the Bloc / HUD.
  Stream<GpsFix> watchFixes();

  /// Session stream (streaming / service flags).
  Stream<GpsSession> watchSession();
}
