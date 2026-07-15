import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';

/// Domain contract for the fused driver HUD.
abstract class DriverDashboardRepository {
  /// Live HUD snapshot stream.
  Stream<DriverDashboardHud> watchHud();

  /// Starts risk fusion + GPS (flood arrives when segmentation runs).
  Future<Result<void>> startLive();

  /// Stops live fusion subscriptions / risk monitoring.
  Future<Result<void>> stopLive();

  /// Releases resources.
  Future<Result<void>> dispose();
}
