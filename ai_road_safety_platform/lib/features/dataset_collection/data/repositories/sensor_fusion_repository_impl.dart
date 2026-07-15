import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/sensor_fusion_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/sensor_fusion_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/sensor_fusion_engine.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:uuid/uuid.dart';

class SensorFusionRepositoryImpl implements SensorFusionRepository {
  final SensorFusionLocalDataSource _local;
  final SensorFusionEngine _engine;
  final GpsRepository _gps;
  final ImuRepository _imu;
  final CameraRepository? _camera;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;
  final SensorFusionConfig _config;

  SensorFusionSession? _session;
  GpsFix? _latestGps;
  ImuSample? _latestImu;
  DateTime? _lastCameraAt;
  DateTime? _lastGpsAt;
  DateTime? _lastImuAt;

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _tickTimer;

  SensorFusionRepositoryImpl({
    required SensorFusionLocalDataSource localDataSource,
    required SensorFusionEngine engine,
    required GpsRepository gpsRepository,
    required ImuRepository imuRepository,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    CameraRepository? cameraRepository,
    Uuid? uuid,
    SensorFusionConfig config = SensorFusionConfig.defaults,
  })  : _local = localDataSource,
        _engine = engine,
        _gps = gpsRepository,
        _imu = imuRepository,
        _camera = cameraRepository,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid(),
        _config = config;

  @override
  Future<Result<SensorFusionSnapshot>> loadSnapshot() {
    return _guard(() async {
      final session = _session ?? await _local.loadSession();
      _session = session;
      final samples = await _local.loadSamples();
      final now = DateTime.now().toUtc();
      return SensorFusionSnapshot(
        session: session,
        recentSamples: samples,
        channels: _engine.buildChannelStatuses(
          now: now,
          config: _config,
          lastCameraAt: _lastCameraAt,
          lastGpsAt: _lastGpsAt ?? _latestGps?.timestamp,
          lastImuAt: _lastImuAt ?? _latestImu?.timestamp,
          cameraEnabled: session?.cameraEnabled ?? true,
          gpsEnabled: session?.gpsEnabled ?? true,
          imuEnabled: session?.imuEnabled ?? true,
        ),
        generatedAt: now,
      );
    });
  }

  @override
  Future<Result<SensorFusionSession>> startFusion({
    bool enableCamera = true,
    bool enableGps = true,
    bool enableImu = true,
  }) {
    return _guard(() async {
      if (_session?.isRunning == true) {
        return _session!;
      }
      await _tearDownStreams();
      final now = DateTime.now().toUtc();
      _session = SensorFusionSession(
        id: _uuid.v4(),
        isRunning: true,
        startedAt: now,
        cameraEnabled: enableCamera,
        gpsEnabled: enableGps,
        imuEnabled: enableImu,
        sonarEnabled: false,
        notes: 'Camera + GPS + IMU fusion (sonar reserved)',
      );
      await _local.saveSession(_session);

      if (enableGps) {
        final gpsStart = await _gps.startTracking();
        gpsStart.fold(
          onOk: (_) {},
          onErr: (f) => _logger.warning(
            'GPS start: ${f.message}',
            tag: 'SensorFusion',
          ),
        );
        _subs.add(
          _gps.watchFixes().listen((fix) {
            _latestGps = fix;
            _lastGpsAt = fix.timestamp.toUtc();
          }),
        );
      }

      if (enableImu) {
        final imuStart = await _imu.startStreaming();
        imuStart.fold(
          onOk: (_) {},
          onErr: (f) => _logger.warning(
            'IMU start: ${f.message}',
            tag: 'SensorFusion',
          ),
        );
        _subs.add(
          _imu.sampleStream.listen((sample) {
            _latestImu = sample;
            _lastImuAt = sample.timestamp.toUtc();
          }),
        );
      }

      if (enableCamera && _camera != null) {
        final camera = _camera;
        final camStart = await camera.startFrameStreaming(targetFps: 4);
        camStart.fold(
          onOk: (_) {
            _subs.add(
              camera.watchFrames().listen((CameraFrameMeta frame) {
                _lastCameraAt = frame.timestamp.toUtc();
                unawaited(
                  fuseTick(
                    at: frame.timestamp,
                    camera: FusedCameraRef(
                      sessionId: frame.sessionId,
                      sequence: frame.sequence,
                      timestamp: frame.timestamp.toUtc(),
                      width: frame.width,
                      height: frame.height,
                    ),
                  ),
                );
              }),
            );
          },
          onErr: (f) => _logger.warning(
            'Camera fusion stream: ${f.message}',
            tag: 'SensorFusion',
          ),
        );
      }

      // Heartbeat fusion when camera ticks are sparse / unavailable.
      _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_session?.isRunning != true) return;
        unawaited(fuseTick());
      });

      _logger.info('Fusion started ${_session!.id}', tag: 'SensorFusion');
      return _session!;
    });
  }

  @override
  Future<Result<SensorFusionSession>> stopFusion() {
    return _guard(() async {
      await _tearDownStreams();
      final current = _session ?? await _local.loadSession();
      if (current == null) {
        throw const CacheException(message: 'No fusion session to stop');
      }
      final stopped = current.copyWith(
        isRunning: false,
        stoppedAt: DateTime.now().toUtc(),
      );
      _session = stopped;
      await _local.saveSession(stopped);
      try {
        await _gps.stopTracking();
      } catch (_) {}
      try {
        await _imu.stopStreaming();
      } catch (_) {}
      try {
        await _camera?.stopFrameStreaming();
      } catch (_) {}
      _logger.info('Fusion stopped ${stopped.id}', tag: 'SensorFusion');
      return stopped;
    });
  }

  @override
  Future<Result<FusedSample>> fuseTick({
    DateTime? at,
    FusedCameraRef? camera,
    GpsFix? gpsOverride,
    ImuSample? imuOverride,
  }) {
    return _guard(() async {
      final now = (at ?? DateTime.now()).toUtc();
      final sample = _engine.fuse(
        at: now,
        camera: camera ??
            (_lastCameraAt == null
                ? null
                : FusedCameraRef(timestamp: _lastCameraAt!)),
        gpsFix: gpsOverride ?? _latestGps,
        imuSample: imuOverride ?? _latestImu,
        config: _config,
      );
      await _appendSample(sample);
      return sample;
    });
  }

  @override
  Future<Result<FusedSample>> createDemoSample() {
    return _guard(() async {
      final now = DateTime.now().toUtc();
      final gps = GpsFix(
        latitude: 23.0225,
        longitude: 72.5714,
        accuracyMeters: 4.5,
        speedMetersPerSecond: 8.3,
        headingDegrees: 120,
        timestamp: now.subtract(const Duration(milliseconds: 120)),
      );
      final imu = ImuSample(
        accelerometer: const ImuVector3(x: 0.2, y: 0.1, z: 9.7),
        gyroscope: const ImuVector3(x: 0.01, y: 0.02, z: 0.0),
        magnetometer: const ImuVector3.zero(),
        orientation: const ImuOrientation(
          pitchDegrees: 2.5,
          rollDegrees: -1.2,
          yawDegrees: 118,
        ),
        tiltDegrees: 2.8,
        vibration: const VibrationMetrics(
          intensity: VibrationIntensity.moderate,
          rms: 0.35,
          peak: 0.9,
        ),
        timestamp: now.subtract(const Duration(milliseconds: 40)),
      );
      final sample = _engine.fuse(
        at: now,
        camera: FusedCameraRef(
          sessionId: 'demo-cam',
          sequence: 42,
          timestamp: now,
          width: 1280,
          height: 720,
        ),
        gpsFix: gps,
        imuSample: imu,
        notes: 'Demo fused sample',
      );
      _latestGps = gps;
      _latestImu = imu;
      _lastGpsAt = gps.timestamp;
      _lastImuAt = imu.timestamp;
      _lastCameraAt = now;
      _session ??= SensorFusionSession(
        id: _uuid.v4(),
        isRunning: false,
        startedAt: now,
        sampleCount: 0,
        notes: 'Demo session',
      );
      await _appendSample(sample);
      await _local.saveSession(_session);
      return sample;
    });
  }

  @override
  Future<Result<void>> clearSamples() {
    return _guard(() async {
      await _local.saveSamples(const []);
      if (_session != null) {
        _session = _session!.copyWith(sampleCount: 0);
        await _local.saveSession(_session);
      }
    });
  }

  Future<void> _appendSample(FusedSample sample) async {
    final existing = await _local.loadSamples();
    final next = [sample, ...existing];
    final capped = next.take(_config.maxBufferedSamples).toList();
    await _local.saveSamples(capped);
    if (_session != null) {
      _session = _session!.copyWith(sampleCount: _session!.sampleCount + 1);
      await _local.saveSession(_session);
    }
  }

  Future<void> _tearDownStreams() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
