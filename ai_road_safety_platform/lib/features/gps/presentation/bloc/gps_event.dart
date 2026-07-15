import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:equatable/equatable.dart';

/// GPS Bloc events.
sealed class GpsEvent extends Equatable {
  const GpsEvent();

  @override
  List<Object?> get props => [];
}

/// Bootstraps permission check + optional first fix.
class GpsStarted extends GpsEvent {
  const GpsStarted();
}

/// Re-requests permission after denial.
class GpsPermissionRequested extends GpsEvent {
  const GpsPermissionRequested();
}

/// Opens OS settings.
///
/// Use [locationServices] when GPS/location toggle is off; otherwise opens
/// the app settings page (for permanently denied permission).
class GpsOpenSettingsRequested extends GpsEvent {
  /// When true, opens Location / GPS services; else app permission settings.
  final bool locationServices;

  /// Creates [GpsOpenSettingsRequested].
  const GpsOpenSettingsRequested({this.locationServices = false});

  @override
  List<Object?> get props => [locationServices];
}

/// Requests a one-shot current location.
class GpsCurrentLocationRequested extends GpsEvent {
  const GpsCurrentLocationRequested();
}

/// Starts continuous updates.
class GpsTrackingStarted extends GpsEvent {
  const GpsTrackingStarted();
}

/// Stops continuous updates.
class GpsTrackingStopped extends GpsEvent {
  const GpsTrackingStopped();
}

/// Tears down GPS resources.
class GpsDisposed extends GpsEvent {
  const GpsDisposed();
}

/// Internal session fan-in.
class GpsSessionUpdated extends GpsEvent {
  /// Latest session.
  final GpsSession session;

  /// Creates [GpsSessionUpdated].
  const GpsSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Internal fix fan-in.
class GpsFixUpdated extends GpsEvent {
  /// Latest GNSS fix.
  final GpsFix fix;

  /// Creates [GpsFixUpdated].
  const GpsFixUpdated(this.fix);

  @override
  List<Object?> get props => [fix];
}
