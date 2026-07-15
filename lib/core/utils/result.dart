import 'package:ai_road_safety_platform/core/errors/failures.dart';

/// Functional result wrapper for domain / data boundary outcomes.
sealed class Result<T> {
  const Result();

  /// True when this is [Ok].
  bool get isOk => this is Ok<T>;

  /// True when this is [Err].
  bool get isErr => this is Err<T>;

  /// Unwraps the success value or throws.
  T getOrThrow() {
    return switch (this) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Maps success values; preserves failures.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok(:final value) => Ok(transform(value)),
      Err(:final failure) => Err(failure),
    };
  }

  /// Invokes [onOk] or [onErr].
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) {
    return switch (this) {
      Ok(:final value) => onOk(value),
      Err(:final failure) => onErr(failure),
    };
  }
}

/// Successful result carrying [value].
final class Ok<T> extends Result<T> {
  /// Success payload.
  final T value;

  /// Creates an [Ok].
  const Ok(this.value);
}

/// Failed result carrying a domain [Failure].
final class Err<T> extends Result<T> {
  /// Domain failure.
  final Failure failure;

  /// Creates an [Err].
  const Err(this.failure);
}
