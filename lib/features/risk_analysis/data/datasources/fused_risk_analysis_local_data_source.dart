import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/datasources/risk_analysis_local_data_source.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Fuses flood / GPS / IMU into throttled [RiskAssessment]s via [RiskRuleEngine].
class FusedRiskAnalysisLocalDataSource implements RiskAnalysisLocalDataSource {
  /// Creates [FusedRiskAnalysisLocalDataSource].
  FusedRiskAnalysisLocalDataSource({
    required RiskRuleEngine ruleEngine,
    required FloodDetectionRepository floodRepository,
    required GpsRepository gpsRepository,
    required ImuRepository imuRepository,
  })  : _engine = ruleEngine,
        _floodRepository = floodRepository,
        _gpsRepository = gpsRepository,
        _imuRepository = imuRepository {
    _sessionController.add(const RiskSession.idle());
  }

  final RiskRuleEngine _engine;
  final FloodDetectionRepository _floodRepository;
  final GpsRepository _gpsRepository;
  final ImuRepository _imuRepository;

  final StreamController<RiskSession> _sessionController =
      StreamController<RiskSession>.broadcast();
  final StreamController<RiskAssessment> _assessmentController =
      StreamController<RiskAssessment>.broadcast();

  StreamSubscription<FloodSegmentationResult>? _floodSub;
  StreamSubscription<GpsFix>? _gpsSub;
  StreamSubscription<ImuSample>? _imuSub;

  bool _monitoring = false;
  RiskInputSnapshot _snapshot = RiskInputSnapshot.empty();
  RiskAssessment? _latest;
  DateTime? _lastEmitAt;

  @override
  Stream<RiskSession> get sessionStream => _sessionController.stream;

  @override
  Stream<RiskAssessment> get assessmentStream => _assessmentController.stream;

  @override
  bool get isMonitoring => _monitoring;

  @override
  RiskAssessment evaluate(RiskInputSnapshot snapshot) {
    final assessment = _engine.evaluate(snapshot);
    _latest = assessment;
    _snapshot = snapshot;
    _emitSession();
    if (!_assessmentController.isClosed) {
      _assessmentController.add(assessment);
    }
    return assessment;
  }

  @override
  Future<void> startMonitoring() async {
    if (_monitoring) return;
    try {
      // Best-effort sensor warm-up — missing GPS must not block fusion.
      await _warmUpGps();
      await _imuRepository.startStreaming();

      _floodSub = _floodRepository.watchResults().listen(
            _onFlood,
            onError: _onStreamError,
            cancelOnError: false,
          );
      _gpsSub = _gpsRepository.watchFixes().listen(
            _onGps,
            onError: _onStreamError,
            cancelOnError: false,
          );
      _imuSub = _imuRepository.sampleStream.listen(
        _onImu,
        onError: _onStreamError,
        cancelOnError: false,
      );

      _monitoring = true;
      _emitSession();
      _maybeEmitAssessment(force: true);
    } catch (error, stackTrace) {
      await _cancelSubs();
      _monitoring = false;
      throw DeviceRiskException(
        message: 'Failed to start risk monitoring: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Starts GPS when location services are on; otherwise skips quietly.
  Future<void> _warmUpGps() async {
    final serviceResult = await _gpsRepository.isServiceEnabled();
    final enabled = serviceResult.fold(
      onOk: (value) => value,
      onErr: (_) => false,
    );
    if (!enabled) return;

    await _gpsRepository.startTracking();
  }

  @override
  Future<void> stopMonitoring() async {
    await _cancelSubs();
    // Release sensors started by monitoring (best-effort).
    await _gpsRepository.stopTracking();
    await _imuRepository.stopStreaming();
    _monitoring = false;
    _emitSession();
  }

  @override
  Future<void> dispose() async {
    await stopMonitoring();
  }

  void _onFlood(FloodSegmentationResult result) {
    _snapshot = _snapshot.copyWith(
      floodCoveragePercent: result.stats.waterCoveragePercent,
      hasFloodSample: true,
      timestamp: DateTime.now(),
    );
    _maybeEmitAssessment();
  }

  void _onGps(GpsFix fix) {
    _snapshot = _snapshot.copyWith(
      speedKmh: fix.speedKmh ?? 0,
      gpsAccuracyMeters: fix.accuracyMeters,
      latitude: fix.latitude,
      longitude: fix.longitude,
      hasGpsFix: true,
      timestamp: DateTime.now(),
    );
    _maybeEmitAssessment();
  }

  void _onImu(ImuSample sample) {
    _snapshot = _snapshot.copyWith(
      tiltDegrees: sample.tiltDegrees,
      vibrationIntensity: sample.vibration.intensity,
      vibrationRms: sample.vibration.rms,
      hasImuSample: true,
      timestamp: DateTime.now(),
    );
    _maybeEmitAssessment();
  }

  void _maybeEmitAssessment({bool force = false}) {
    if (!_monitoring && !force) return;
    final now = DateTime.now();
    final last = _lastEmitAt;
    if (!force &&
        last != null &&
        now.difference(last) < RiskAnalysisConfig.emitInterval) {
      return;
    }
    _lastEmitAt = now;
    final assessment = _engine.evaluate(
      _snapshot.copyWith(timestamp: now),
    );
    _latest = assessment;
    if (!_assessmentController.isClosed) {
      _assessmentController.add(assessment);
    }
    _emitSession();
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (!_assessmentController.isClosed) {
      _assessmentController.addError(
        DeviceRiskException(
          message: 'Risk sensor fusion error: $error',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  Future<void> _cancelSubs() async {
    await _floodSub?.cancel();
    await _gpsSub?.cancel();
    await _imuSub?.cancel();
    _floodSub = null;
    _gpsSub = null;
    _imuSub = null;
  }

  void _emitSession() {
    if (_sessionController.isClosed) return;
    _sessionController.add(
      RiskSession(
        isMonitoring: _monitoring,
        latestAssessment: _latest,
      ),
    );
  }
}
