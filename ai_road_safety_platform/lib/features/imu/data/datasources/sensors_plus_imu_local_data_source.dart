import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/features/imu/data/datasources/imu_local_data_source.dart';
import 'package:ai_road_safety_platform/features/imu/data/processors/imu_processors.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [sensors_plus] IMU implementation with bias, tilt, vibration, and emit throttle.
class SensorsPlusImuLocalDataSource implements ImuLocalDataSource {
  /// Creates [SensorsPlusImuLocalDataSource].
  SensorsPlusImuLocalDataSource({
    required SharedPreferences preferences,
    ImuOrientationProcessor? orientationProcessor,
    VibrationProcessor? vibrationProcessor,
  })  : _prefs = preferences,
        _orientation = orientationProcessor ?? const ImuOrientationProcessor(),
        _vibration = vibrationProcessor ?? VibrationProcessor() {
    _calibration = _loadCalibration();
    _sessionController.add(_buildSession());
  }

  final SharedPreferences _prefs;
  final ImuOrientationProcessor _orientation;
  final VibrationProcessor _vibration;
  final ImuCalibrationCollector _calibrator = ImuCalibrationCollector();

  final StreamController<ImuSession> _sessionController =
      StreamController<ImuSession>.broadcast();
  final StreamController<ImuSample> _sampleController =
      StreamController<ImuSample>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  ImuCalibration _calibration = const ImuCalibration.uncalibrated();
  bool _streaming = false;
  bool _calibrating = false;

  ImuVector3 _rawAccel = const ImuVector3.zero();
  ImuVector3 _rawGyro = const ImuVector3.zero();
  ImuVector3 _rawMag = const ImuVector3.zero();
  bool _hasAccel = false;
  bool _hasGyro = false;
  bool _hasMag = false;

  DateTime? _lastEmitAt;
  Completer<ImuCalibration>? _calibrateCompleter;

  /// Unit gravity direction captured when streaming starts (current mount pose).
  ImuVector3? _restGravityUnit;
  ImuVector3 _restGravitySum = const ImuVector3.zero();
  int _restGravitySamples = 0;

  @override
  ImuCalibration get calibration => _calibration;

  @override
  bool get isStreaming => _streaming;

  @override
  bool get isCalibrating => _calibrating;

  @override
  Stream<ImuSession> get sessionStream => _sessionController.stream;

  @override
  Stream<ImuSample> get sampleStream => _sampleController.stream;

  @override
  Future<void> startStreaming() async {
    if (_streaming) {
      return;
    }
    try {
      _vibration.reset();
      _resetRestBaseline();
      _accelSub = accelerometerEventStream(
        samplingPeriod: ImuConfig.sensorInterval,
      ).listen(
        _onAccel,
        onError: _onSensorError,
        cancelOnError: false,
      );
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: ImuConfig.sensorInterval,
      ).listen(
        _onGyro,
        onError: _onSensorError,
        cancelOnError: false,
      );
      _magSub = magnetometerEventStream(
        samplingPeriod: ImuConfig.sensorInterval,
      ).listen(
        _onMag,
        onError: _onSensorError,
        cancelOnError: false,
      );
      _streaming = true;
      _emitSession();
    } catch (error, stackTrace) {
      await _cancelSubs();
      throw DeviceImuException(
        message: 'Failed to start IMU sensors: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopStreaming() async {
    await _cancelSubs();
    _streaming = false;
    _hasAccel = false;
    _hasGyro = false;
    _hasMag = false;
    _resetRestBaseline();
    if (_calibrating) {
      _calibrator.cancel();
      _calibrating = false;
      _calibrateCompleter?.completeError(
        const DeviceImuException(message: 'Calibration cancelled (stream stopped).'),
      );
      _calibrateCompleter = null;
    }
    _emitSession(clearSample: true);
  }

  @override
  Future<ImuCalibration> calibrate() async {
    if (!_streaming) {
      await startStreaming();
    }
    if (_calibrating) {
      throw const DeviceImuException(message: 'Calibration already in progress.');
    }
    _calibrator.start();
    _calibrating = true;
    _emitSession();
    final completer = Completer<ImuCalibration>();
    _calibrateCompleter = completer;
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    // Singleton-safe: cancel hardware streams only; keep broadcast controllers.
    await stopStreaming();
  }

  void _onAccel(AccelerometerEvent event) {
    _rawAccel = ImuVector3(x: event.x, y: event.y, z: event.z);
    _hasAccel = true;
    _maybeCompleteCalibration();
    _maybeEmitSample();
  }

  void _onGyro(GyroscopeEvent event) {
    _rawGyro = ImuVector3(x: event.x, y: event.y, z: event.z);
    _hasGyro = true;
    _maybeCompleteCalibration();
  }

  void _onMag(MagnetometerEvent event) {
    _rawMag = ImuVector3(x: event.x, y: event.y, z: event.z);
    _hasMag = true;
  }

  void _maybeCompleteCalibration() {
    if (!_calibrating || !_hasAccel || !_hasGyro) {
      return;
    }
    final result = _calibrator.addSample(
      accelerometer: _rawAccel,
      gyroscope: _rawGyro,
    );
    _emitSession();
    if (result == null) {
      return;
    }
    _calibration = result;
    _persistCalibration(result);
    _calibrating = false;
    _emitSession();
    _calibrateCompleter?.complete(result);
    _calibrateCompleter = null;
  }

  void _maybeEmitSample() {
    if (!_hasAccel) {
      return;
    }
    final now = DateTime.now();
    final last = _lastEmitAt;
    if (last != null && now.difference(last) < ImuConfig.emitInterval) {
      return;
    }
    _lastEmitAt = now;

    final calibratedAccel = _rawAccel - _calibration.accelerometerBias;
    final calibratedGyro = _hasGyro
        ? _rawGyro - _calibration.gyroscopeBias
        : const ImuVector3.zero();
    final mag = _hasMag ? _rawMag : const ImuVector3.zero();

    _captureRestBaseline(calibratedAccel);

    // Until mount baseline locks, report 0° so dash stands don't look Extreme.
    final derived = _orientation.process(
      accelerometer: calibratedAccel,
      magnetometer: mag,
      restGravityUnit: _restGravityUnit,
    );
    final tiltDegrees =
        _restGravityUnit == null ? 0.0 : derived.tiltDegrees;
    final vibration = _vibration.update(calibratedAccel);

    final sample = ImuSample(
      accelerometer: calibratedAccel,
      gyroscope: calibratedGyro,
      magnetometer: mag,
      orientation: derived.orientation,
      tiltDegrees: tiltDegrees,
      vibration: vibration,
      timestamp: now,
    );

    if (!_sampleController.isClosed) {
      _sampleController.add(sample);
    }
    _emitSession(latest: sample);
  }

  void _resetRestBaseline() {
    _restGravityUnit = null;
    _restGravitySum = const ImuVector3.zero();
    _restGravitySamples = 0;
  }

  /// Locks the mount/rest gravity after a short average so dash stands ≈ 0° tilt.
  void _captureRestBaseline(ImuVector3 calibratedAccel) {
    if (_restGravityUnit != null) return;
    final mag = calibratedAccel.magnitude;
    if (mag < 5) return; // skip free-fall / shake while settling
    _restGravitySum = _restGravitySum + calibratedAccel.normalized;
    _restGravitySamples += 1;
    if (_restGravitySamples >= ImuConfig.restBaselineSamples) {
      _restGravityUnit = (_restGravitySum * (1 / _restGravitySamples)).normalized;
    }
  }

  void _onSensorError(Object error, StackTrace stackTrace) {
    if (!_sampleController.isClosed) {
      _sampleController.addError(
        DeviceImuException(
          message: 'IMU sensor error: $error',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  Future<void> _cancelSubs() async {
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _magSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magSub = null;
  }

  ImuSession _buildSession({ImuSample? latest, bool clearSample = false}) {
    return ImuSession(
      isStreaming: _streaming,
      isCalibrating: _calibrating,
      calibrationProgress: _calibrating ? _calibrator.progress : 0,
      calibration: _calibration,
      latestSample: clearSample ? null : (latest ?? _lastSample),
    );
  }

  ImuSample? _lastSample;

  void _emitSession({ImuSample? latest, bool clearSample = false}) {
    if (latest != null) {
      _lastSample = latest;
    }
    if (clearSample) {
      _lastSample = null;
    }
    if (!_sessionController.isClosed) {
      _sessionController.add(
        _buildSession(latest: latest, clearSample: clearSample),
      );
    }
  }

  ImuCalibration _loadCalibration() {
    final atMs = _prefs.getInt(ImuConfig.prefsCalibratedAt);
    if (atMs == null) {
      return const ImuCalibration.uncalibrated();
    }
    return ImuCalibration(
      accelerometerBias: ImuVector3(
        x: _prefs.getDouble(ImuConfig.prefsAccelBiasX) ?? 0,
        y: _prefs.getDouble(ImuConfig.prefsAccelBiasY) ?? 0,
        z: _prefs.getDouble(ImuConfig.prefsAccelBiasZ) ?? 0,
      ),
      gyroscopeBias: ImuVector3(
        x: _prefs.getDouble(ImuConfig.prefsGyroBiasX) ?? 0,
        y: _prefs.getDouble(ImuConfig.prefsGyroBiasY) ?? 0,
        z: _prefs.getDouble(ImuConfig.prefsGyroBiasZ) ?? 0,
      ),
      samplesUsed: _prefs.getInt(ImuConfig.prefsSamplesUsed) ?? 0,
      calibratedAt: DateTime.fromMillisecondsSinceEpoch(atMs),
    );
  }

  Future<void> _persistCalibration(ImuCalibration calibration) async {
    final at = calibration.calibratedAt;
    if (at == null) {
      return;
    }
    await _prefs.setDouble(
      ImuConfig.prefsAccelBiasX,
      calibration.accelerometerBias.x,
    );
    await _prefs.setDouble(
      ImuConfig.prefsAccelBiasY,
      calibration.accelerometerBias.y,
    );
    await _prefs.setDouble(
      ImuConfig.prefsAccelBiasZ,
      calibration.accelerometerBias.z,
    );
    await _prefs.setDouble(
      ImuConfig.prefsGyroBiasX,
      calibration.gyroscopeBias.x,
    );
    await _prefs.setDouble(
      ImuConfig.prefsGyroBiasY,
      calibration.gyroscopeBias.y,
    );
    await _prefs.setDouble(
      ImuConfig.prefsGyroBiasZ,
      calibration.gyroscopeBias.z,
    );
    await _prefs.setInt(ImuConfig.prefsCalibratedAt, at.millisecondsSinceEpoch);
    await _prefs.setInt(ImuConfig.prefsSamplesUsed, calibration.samplesUsed);
  }
}
