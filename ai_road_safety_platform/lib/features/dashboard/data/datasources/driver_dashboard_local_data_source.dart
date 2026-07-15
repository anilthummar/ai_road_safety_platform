import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';

/// Local fusion for the driver dashboard HUD.
abstract class DriverDashboardLocalDataSource {
  /// HUD stream.
  Stream<DriverDashboardHud> get hudStream;

  /// Whether live mode is on.
  bool get isLive;

  /// Starts risk monitoring and sensor subscriptions.
  Future<void> startLive();

  /// Stops monitoring.
  Future<void> stopLive();

  /// Singleton-safe teardown.
  Future<void> dispose();
}
