import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:equatable/equatable.dart';

/// GPS Bloc states.
sealed class GpsState extends Equatable {
  const GpsState();

  @override
  List<Object?> get props => [];
}

/// Uninitialized.
class GpsInitial extends GpsState {
  const GpsInitial();
}

/// Permission / fix in progress.
class GpsLoading extends GpsState {
  /// Status text.
  final String message;

  /// Creates [GpsLoading].
  const GpsLoading({this.message = 'Reading GPS…'});

  @override
  List<Object?> get props => [message];
}

/// Location permission denied.
class GpsPermissionDenied extends GpsState {
  /// Whether settings must be opened.
  final bool isPermanentlyDenied;

  /// User-facing message.
  final String message;

  /// Creates [GpsPermissionDenied].
  const GpsPermissionDenied({
    required this.isPermanentlyDenied,
    this.message = 'Location permission is required for GPS tracking.',
  });

  @override
  List<Object?> get props => [isPermanentlyDenied, message];
}

/// Location services disabled at the OS level.
class GpsServiceDisabled extends GpsState {
  /// Creates [GpsServiceDisabled].
  const GpsServiceDisabled({
    this.message = 'Location services are disabled. Enable GPS and try again.',
  });

  /// User-facing message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// GPS ready with session + latest fix.
class GpsActive extends GpsState {
  /// Session flags and counters.
  final GpsSession session;

  /// Creates [GpsActive].
  const GpsActive({required this.session});

  /// Latest fix convenience.
  GpsFix? get latestFix => session.latestFix;

  /// Copy helper.
  GpsActive copyWith({GpsSession? session}) {
    return GpsActive(session: session ?? this.session);
  }

  @override
  List<Object?> get props => [session];
}

/// Fatal / recoverable GPS failure.
class GpsError extends GpsState {
  /// Domain failure.
  final Failure failure;

  /// Creates [GpsError].
  const GpsError(this.failure);

  @override
  List<Object?> get props => [failure];
}
