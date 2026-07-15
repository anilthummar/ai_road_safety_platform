import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over device connectivity checks.
///
/// Domain and data layers depend on this contract, not on [Connectivity]
/// directly, so tests can inject a fake.
abstract class NetworkInfo {
  /// Returns `true` when the device has a usable network path.
  Future<bool> get isConnected;

  /// Stream of connectivity changes for reactive offline UI.
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// [NetworkInfo] implementation backed by `connectivity_plus`.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  /// Creates [NetworkInfoImpl] with an injectable [Connectivity] instance.
  NetworkInfoImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
