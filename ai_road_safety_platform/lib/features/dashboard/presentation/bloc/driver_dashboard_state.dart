import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:equatable/equatable.dart';

/// Driver dashboard states.
sealed class DriverDashboardState extends Equatable {
  const DriverDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial.
final class DriverDashboardInitial extends DriverDashboardState {
  const DriverDashboardInitial();
}

/// Loading.
final class DriverDashboardLoading extends DriverDashboardState {
  /// Status.
  final String message;

  /// Creates [DriverDashboardLoading].
  const DriverDashboardLoading({this.message = 'Starting driver dashboard…'});

  @override
  List<Object?> get props => [message];
}

/// Live / idle HUD.
final class DriverDashboardActive extends DriverDashboardState {
  /// Fused HUD snapshot.
  final DriverDashboardHud hud;

  /// Creates [DriverDashboardActive].
  const DriverDashboardActive({required this.hud});

  @override
  List<Object?> get props => [hud];
}

/// Failure.
final class DriverDashboardError extends DriverDashboardState {
  /// Failure.
  final Failure failure;

  /// Creates [DriverDashboardError].
  const DriverDashboardError(this.failure);

  @override
  List<Object?> get props => [failure];
}
