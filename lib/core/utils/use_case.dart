/// Contract for a unitary use case with typed input/output.
abstract class UseCase<Output, Params> {
  /// Executes the use case with [params].
  Future<Output> call(Params params);
}

/// Marker for use cases that take no parameters.
class NoParams {
  /// Creates [NoParams].
  const NoParams();
}
