/// Data-layer exception hierarchy.
///
/// Thrown inside data sources / clients, then mapped to [Failure] types
/// inside repository implementations. Never catch these in UI widgets.
class AppException implements Exception {
  /// Diagnostic message for logs.
  final String message;

  /// Optional underlying cause for stack correlation.
  final Object? cause;

  /// Optional stack from the originating layer.
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException(message: $message, cause: $cause)';
}

/// HTTP / remote API exception.
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });
}

/// Local persistence exception.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// Connectivity exception.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection.',
    super.cause,
    super.stackTrace,
  });
}

/// Platform permission exception.
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// Camera plugin / hardware exception (app-layer; not the camera package type).
class DeviceCameraException extends AppException {
  const DeviceCameraException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// TensorFlow Lite / inference pipeline exception.
class InferenceException extends AppException {
  const InferenceException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// GNSS / Geolocator exception.
class DeviceGpsException extends AppException {
  const DeviceGpsException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// IMU / sensors_plus exception.
class DeviceImuException extends AppException {
  const DeviceImuException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// Risk analysis / fusion exception.
class DeviceRiskException extends AppException {
  const DeviceRiskException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// JSON / DTO parsing exception.
class ParsingException extends AppException {
  const ParsingException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
