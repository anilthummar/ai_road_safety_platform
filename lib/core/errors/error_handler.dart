import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:dio/dio.dart';

/// Maps low-level exceptions to domain [Failure]s and records diagnostics.
///
/// Presentation code should receive [Failure] only — never raw [Exception].
class ErrorHandler {
  /// Structured logger used for exception telemetry.
  final AppLogger _logger;

  /// Creates an [ErrorHandler] bound to [logger].
  const ErrorHandler({required AppLogger logger}) : _logger = logger;

  /// Converts any [error] into a typed [Failure].
  Failure handle(Object error, [StackTrace? stackTrace]) {
    _logger.error(
      'Handled error: $error',
      error: error,
      stackTrace: stackTrace,
      tag: 'ErrorHandler',
    );

    if (error is Failure) {
      return error;
    }

    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
      );
    }

    if (error is CacheException) {
      return CacheFailure(message: error.message);
    }

    if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    }

    if (error is PermissionException) {
      return PermissionFailure(message: error.message);
    }

    if (error is DeviceCameraException) {
      return CameraFailure(message: error.message);
    }

    if (error is InferenceException) {
      return InferenceFailure(message: error.message);
    }

    if (error is DeviceGpsException) {
      return GpsFailure(message: error.message);
    }

    if (error is DeviceImuException) {
      return ImuFailure(message: error.message);
    }

    if (error is DeviceRiskException) {
      return RiskFailure(message: error.message);
    }

    if (error is ParsingException) {
      return UnexpectedFailure(message: error.message, code: 'parsing');
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    return UnexpectedFailure(message: error.toString());
  }

  Failure _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(
          message: 'Connection timed out. Please try again.',
          code: 'timeout',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return ServerFailure(
          message: error.message ?? 'Server error.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const UnexpectedFailure(
          message: 'Request was cancelled.',
          code: 'cancelled',
        );
      case DioExceptionType.badCertificate:
        return const ServerFailure(
          message: 'Invalid SSL certificate.',
          code: 'bad_certificate',
        );
      case DioExceptionType.unknown:
        return UnexpectedFailure(message: error.message ?? 'Unknown network error.');
    }
  }
}
