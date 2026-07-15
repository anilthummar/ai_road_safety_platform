import 'package:logger/logger.dart';

/// Application logging facade over the `logger` package.
///
/// Prefer this over [print] or direct [Logger] usage so levels and tags stay
/// consistent across features.
class AppLogger {
  /// Underlying logger instance.
  final Logger _logger;

  /// Creates an [AppLogger] with optional custom [Logger] configuration.
  AppLogger({Logger? logger})
      : _logger = logger ??
            Logger(
              printer: PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 8,
                lineLength: 100,
                colors: true,
                printEmojis: false,
                dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
              ),
            );

  /// Verbose / trace level.
  void verbose(String message, {String? tag}) {
    _logger.t(_format(message, tag));
  }

  /// Debug level.
  void debug(String message, {String? tag}) {
    _logger.d(_format(message, tag));
  }

  /// Informational level.
  void info(String message, {String? tag}) {
    _logger.i(_format(message, tag));
  }

  /// Warning level.
  void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _logger.w(_format(message, tag), error: error, stackTrace: stackTrace);
  }

  /// Error level.
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(_format(message, tag), error: error, stackTrace: stackTrace);
  }

  /// Fatal / what-a-terrible-failure level.
  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(_format(message, tag), error: error, stackTrace: stackTrace);
  }

  String _format(String message, String? tag) {
    if (tag == null || tag.isEmpty) {
      return message;
    }
    return '[$tag] $message';
  }
}
