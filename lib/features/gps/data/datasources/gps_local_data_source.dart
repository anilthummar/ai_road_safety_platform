import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:geolocator/geolocator.dart';

/// Low-level GNSS access via Geolocator.
abstract class GpsLocalDataSource {
  Future<GpsPermissionStatus> checkPermission();

  Future<GpsPermissionStatus> requestPermission();

  Future<bool> openPermissionSettings();

  /// Opens the OS Location / GPS services screen (not app permissions).
  Future<bool> openLocationSettings();

  Future<bool> isServiceEnabled();

  Future<GpsFix> getCurrentLocation();

  Future<GpsSession> startTracking();

  Future<GpsSession> stopTracking();

  Future<void> disposeGps();

  Stream<GpsFix> get fixStream;

  Stream<GpsSession> get sessionStream;

  GpsSession get currentSession;
}

/// Production [GpsLocalDataSource] backed by `geolocator`.
class GpsLocalDataSourceImpl implements GpsLocalDataSource {
  final AppLogger _logger;

  final StreamController<GpsFix> _fixController =
      StreamController<GpsFix>.broadcast();
  final StreamController<GpsSession> _sessionController =
      StreamController<GpsSession>.broadcast();

  StreamSubscription<Position>? _positionSub;
  GpsSession _session = const GpsSession.idle();
  int _fixCount = 0;

  /// Creates [GpsLocalDataSourceImpl].
  GpsLocalDataSourceImpl({required AppLogger logger}) : _logger = logger;

  @override
  GpsSession get currentSession => _session;

  @override
  Stream<GpsFix> get fixStream => _fixController.stream;

  @override
  Stream<GpsSession> get sessionStream => _sessionController.stream;

  @override
  Future<GpsPermissionStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<GpsPermissionStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  @override
  Future<bool> openPermissionSettings() {
    return Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  @override
  Future<bool> isServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<GpsFix> getCurrentLocation() async {
    await _ensureReady();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: GpsTrackingConfig.currentPositionTimeout,
        ),
      );
      final fix = _toFix(position);
      _emitFix(fix);
      return fix;
    } on TimeoutException catch (e, st) {
      throw DeviceGpsException(
        message: 'Timed out while waiting for a GPS fix.',
        cause: e,
        stackTrace: st,
      );
    } on LocationServiceDisabledException catch (e, st) {
      throw DeviceGpsException(
        message: 'Location services are disabled. Enable GPS and try again.',
        cause: e,
        stackTrace: st,
      );
    } on PermissionDeniedException catch (e, st) {
      throw PermissionException(
        message: 'Location permission was denied.',
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is AppException) rethrow;
      throw DeviceGpsException(
        message: 'Failed to get current location: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<GpsSession> startTracking() async {
    await _ensureReady();

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: GpsTrackingConfig.distanceFilterMeters.round(),
      ),
    ).listen(
      (position) => _emitFix(_toFix(position)),
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning(
          'GPS stream error',
          tag: 'GpsDataSource',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _session = _session.copyWith(
      isStreaming: true,
      isServiceEnabled: true,
    );
    _emitSession(_session);
    _logger.info('GPS tracking started', tag: 'GpsDataSource');
    return _session;
  }

  @override
  Future<GpsSession> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _session = _session.copyWith(isStreaming: false);
    _emitSession(_session);
    _logger.debug('GPS tracking stopped', tag: 'GpsDataSource');
    return _session;
  }

  @override
  Future<void> disposeGps() async {
    await stopTracking();
    _fixCount = 0;
    _session = const GpsSession.idle();
    _emitSession(_session);
  }

  Future<void> _ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _session = _session.copyWith(isServiceEnabled: serviceEnabled);
    _emitSession(_session);

    if (!serviceEnabled) {
      throw const DeviceGpsException(
        message: 'Location services are disabled. Enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final status = _mapPermission(permission);
    if (status == GpsPermissionStatus.denied) {
      throw const PermissionException(
        message: 'Location permission is required for GPS tracking.',
      );
    }
    if (status == GpsPermissionStatus.permanentlyDenied ||
        status == GpsPermissionStatus.restricted) {
      throw const PermissionException(
        message:
            'Location permission is permanently denied. Open settings to enable it.',
      );
    }
  }

  GpsFix _toFix(Position position) {
    return GpsFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      altitudeMeters: position.altitude.isFinite ? position.altitude : null,
      speedMetersPerSecond:
          position.speed.isFinite && position.speed >= 0 ? position.speed : null,
      headingDegrees: position.heading.isFinite && position.heading >= 0
          ? position.heading
          : null,
      timestamp: position.timestamp,
      isMocked: position.isMocked,
    );
  }

  void _emitFix(GpsFix fix) {
    _fixCount += 1;
    if (!_fixController.isClosed) {
      _fixController.add(fix);
    }
    _session = _session.copyWith(
      latestFix: fix,
      fixCount: _fixCount,
      isServiceEnabled: true,
    );
    _emitSession(_session);
  }

  void _emitSession(GpsSession session) {
    _session = session;
    if (!_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }

  GpsPermissionStatus _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse =>
        GpsPermissionStatus.granted,
      LocationPermission.denied => GpsPermissionStatus.denied,
      LocationPermission.deniedForever => GpsPermissionStatus.permanentlyDenied,
      LocationPermission.unableToDetermine => GpsPermissionStatus.unknown,
    };
  }
}
