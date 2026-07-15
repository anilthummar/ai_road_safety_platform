import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:dio/dio.dart';

/// Configures and exposes the shared [Dio] HTTP client.
///
/// Feature-specific APIs should inject this client via GetIt — do not create
/// ad-hoc [Dio] instances inside widgets or blocs.
class ApiClient {
  /// Shared Dio instance.
  final Dio dio;

  /// Creates an [ApiClient] with production defaults and optional [logger].
  ApiClient({
    required AppLogger logger,
    Dio? dio,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                sendTimeout: AppConfig.sendTimeout,
                headers: const {
                  Headers.acceptHeader: 'application/json',
                  Headers.contentTypeHeader: 'application/json',
                },
              ),
            ) {
    this.dio.interceptors.add(
      _LoggingInterceptor(logger: logger),
    );
  }
}

/// Dio interceptor that emits structured request / response logs.
class _LoggingInterceptor extends Interceptor {
  final AppLogger logger;

  _LoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.enableVerboseLogging) {
      logger.debug(
        '→ ${options.method} ${options.uri}',
        tag: 'Http',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (AppConfig.enableVerboseLogging) {
      logger.debug(
        '← ${response.statusCode} ${response.requestOptions.uri}',
        tag: 'Http',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.warning(
      '✗ ${err.type.name} ${err.requestOptions.uri}',
      tag: 'Http',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
