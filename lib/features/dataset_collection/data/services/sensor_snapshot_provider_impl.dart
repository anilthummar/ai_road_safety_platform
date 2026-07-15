import 'dart:async';
import 'dart:io' show Platform;

import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_detection_config.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/repositories/risk_analysis_repository.dart';
import 'package:flutter/foundation.dart';

/// Caches latest GPS / IMU / flood / risk for capture-time sync.
class SensorSnapshotProviderImpl implements SensorSnapshotProvider {
  final GpsRepository _gps;
  final ImuRepository _imu;
  final FloodDetectionRepository _flood;
  final RiskAnalysisRepository _risk;
  final AppLogger _logger;

  StreamSubscription<GpsFix>? _gpsSub;
  StreamSubscription<ImuSample>? _imuSub;
  StreamSubscription<FloodSegmentationResult>? _floodSub;
  StreamSubscription<RiskAssessment>? _riskSub;

  GpsFix? _latestGps;
  ImuSample? _latestImu;
  FloodSegmentationResult? _latestFlood;
  RiskAssessment? _latestRisk;
  bool _started = false;

  /// Creates [SensorSnapshotProviderImpl].
  SensorSnapshotProviderImpl({
    required GpsRepository gpsRepository,
    required ImuRepository imuRepository,
    required FloodDetectionRepository floodRepository,
    required RiskAnalysisRepository riskRepository,
    required AppLogger logger,
  })  : _gps = gpsRepository,
        _imu = imuRepository,
        _flood = floodRepository,
        _risk = riskRepository,
        _logger = logger;

  @override
  SensorStatusSnapshot get status => SensorStatusSnapshot(
        gpsLive: _latestGps != null,
        imuLive: _latestImu != null,
        aiLive: _latestFlood != null,
        riskLive: _latestRisk != null,
      );

  @override
  void start() {
    if (_started) return;
    _started = true;
    _gpsSub = _gps.watchFixes().listen(
      (fix) => _latestGps = fix,
      onError: (Object e) => _logger.debug('GPS cache: $e', tag: 'SensorSnap'),
    );
    _imuSub = _imu.sampleStream.listen(
      (sample) => _latestImu = sample,
      onError: (Object e) => _logger.debug('IMU cache: $e', tag: 'SensorSnap'),
    );
    _floodSub = _flood.watchResults().listen(
      (r) => _latestFlood = r,
      onError: (Object e) => _logger.debug('Flood cache: $e', tag: 'SensorSnap'),
    );
    _riskSub = _risk.watchAssessments().listen(
      (a) => _latestRisk = a,
      onError: (Object e) => _logger.debug('Risk cache: $e', tag: 'SensorSnap'),
    );
  }

  @override
  void stop() {
    _gpsSub?.cancel();
    _imuSub?.cancel();
    _floodSub?.cancel();
    _riskSub?.cancel();
    _gpsSub = null;
    _imuSub = null;
    _floodSub = null;
    _riskSub = null;
    _started = false;
  }

  @override
  Future<SensorSnapshotBundle> collect({
    required CapturedFrame frame,
    required DateTime at,
  }) async {
    start();

    // Prefer a fresh one-shot GPS when possible; fall back to cache.
    GpsFix? gps = _latestGps;
    try {
      final fresh = await _gps.getCurrentLocation().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () => throw TimeoutException('gps'),
      );
      if (fresh.isOk) {
        gps = fresh.getOrThrow();
        _latestGps = gps;
      }
    } catch (_) {
      // Keep cache / missing — never block UI on GNSS timeout.
    }

    final location = gps == null
        ? LocationMetadata.missing(at)
        : LocationMetadata(
            latitude: gps.latitude,
            longitude: gps.longitude,
            altitude: gps.altitudeMeters ?? 0,
            accuracy: gps.accuracyMeters,
            heading: gps.headingDegrees ?? 0,
            speed: gps.speedMetersPerSecond ?? 0,
            timestamp: gps.timestamp,
            isAvailable: true,
          );

    final imu = _latestImu;
    final motion = imu == null
        ? const MotionMetadata.missing()
        : MotionMetadata(
            accelerometerX: imu.accelerometer.x,
            accelerometerY: imu.accelerometer.y,
            accelerometerZ: imu.accelerometer.z,
            gyroscopeX: imu.gyroscope.x,
            gyroscopeY: imu.gyroscope.y,
            gyroscopeZ: imu.gyroscope.z,
            orientation: imu.orientation.yawDegrees ?? imu.tiltDegrees,
            isAvailable: true,
          );

    final flood = _latestFlood;
    final risk = _latestRisk;
    final inference = flood == null
        ? const InferenceMetadata.missing(
            modelVersion: FloodDetectionConfig.modelAssetPath,
          )
        : InferenceMetadata(
            prediction: flood.stats.isFloodLikely ? 'water' : 'clear',
            confidence: flood.stats.meanConfidence,
            waterCoverage: flood.stats.waterCoveragePercent,
            riskLevel: risk?.level.label ?? 'unknown',
            modelVersion: FloodDetectionConfig.modelAssetPath,
            inferenceTimeMs: flood.inferenceDuration.inMicroseconds / 1000.0,
            isAvailable: true,
          );

    final device = _readDevice(screenRotation: frame.rotation);

    return SensorSnapshotBundle(
      location: location,
      motion: motion,
      inference: inference,
      device: device,
      sensorStatus: status,
    );
  }

  DeviceMetadata _readDevice({required int screenRotation}) {
    if (kIsWeb) {
      return DeviceMetadata(
        deviceModel: 'web',
        manufacturer: 'browser',
        androidVersion: 'web',
        batteryLevel: -1,
        chargingStatus: 'unknown',
        screenRotation: screenRotation,
        appVersion: AppConfig.appVersion,
      );
    }

    String osVersion;
    try {
      osVersion = Platform.operatingSystemVersion;
    } catch (_) {
      osVersion = 'unknown';
    }

    return DeviceMetadata(
      deviceModel: defaultTargetPlatform.name,
      manufacturer: Platform.isAndroid
          ? 'Android'
          : Platform.isIOS
              ? 'Apple'
              : Platform.operatingSystem,
      androidVersion: osVersion,
      batteryLevel: -1,
      chargingStatus: 'unknown',
      screenRotation: screenRotation,
      appVersion: AppConfig.appVersion,
    );
  }
}
