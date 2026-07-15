import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:equatable/equatable.dart';

/// Driver dashboard events.
sealed class DriverDashboardEvent extends Equatable {
  const DriverDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Bind streams and start live fusion.
final class DriverDashboardStarted extends DriverDashboardEvent {
  const DriverDashboardStarted();
}

/// Stop live fusion.
final class DriverDashboardStopped extends DriverDashboardEvent {
  const DriverDashboardStopped();
}

/// Dispose.
final class DriverDashboardDisposed extends DriverDashboardEvent {
  const DriverDashboardDisposed();
}

/// Internal HUD update.
final class DriverDashboardHudUpdated extends DriverDashboardEvent {
  /// Latest HUD.
  final DriverDashboardHud hud;

  /// Creates [DriverDashboardHudUpdated].
  const DriverDashboardHudUpdated(this.hud);

  @override
  List<Object?> get props => [hud];
}
