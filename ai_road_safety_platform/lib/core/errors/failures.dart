import 'package:equatable/equatable.dart';

/// Domain-layer failure base type.
///
/// Failures are returned from repositories / use cases — they must never
/// leak raw platform exceptions into the presentation layer.
abstract class Failure extends Equatable {
  /// Human-readable message suitable for UI or logs.
  final String message;

  /// Optional machine-readable code for analytics / localization maps.
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Unexpected / unclassified failure.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred.',
    super.code = 'unexpected',
  });
}

/// Remote API or HTTP failure.
class ServerFailure extends Failure {
  /// HTTP status when available.
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code = 'server',
    this.statusCode,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Local cache / database failure.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'cache',
  });
}

/// Device is offline or connectivity check failed.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection.',
    super.code = 'network',
  });
}

/// Permission denied by the OS (camera, location, sensors).
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'permission',
  });
}

/// Camera hardware / plugin failure.
class CameraFailure extends Failure {
  const CameraFailure({
    required super.message,
    super.code = 'camera',
  });
}

/// On-device AI / TFLite inference failure.
class InferenceFailure extends Failure {
  const InferenceFailure({
    required super.message,
    super.code = 'inference',
  });
}

/// GNSS / location hardware failure.
class GpsFailure extends Failure {
  const GpsFailure({
    required super.message,
    super.code = 'gps',
  });
}

/// IMU / motion sensor failure.
class ImuFailure extends Failure {
  const ImuFailure({
    required super.message,
    super.code = 'imu',
  });
}

/// Risk analysis / fusion failure.
class RiskFailure extends Failure {
  const RiskFailure({
    required super.message,
    super.code = 'risk',
  });
}

/// Validation failure for user input or sensor samples.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'validation',
  });
}
