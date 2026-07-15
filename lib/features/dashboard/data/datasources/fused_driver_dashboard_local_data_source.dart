import 'dart:async';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/features/dashboard/data/datasources/driver_dashboard_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_warning_builder.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/repositories/risk_analysis_repository.dart';

/// Fuses flood / GPS / risk into a throttled [DriverDashboardHud].
class FusedDriverDashboardLocalDataSource
    implements DriverDashboardLocalDataSource {
  /// Creates [FusedDriverDashboardLocalDataSource].
  FusedDriverDashboardLocalDataSource({
    required FloodDetectionRepository floodRepository,
    required GpsRepository gpsRepository,
    required RiskAnalysisRepository riskRepository,
    DriverWarningBuilder warningBuilder = const DriverWarningBuilder(),
  })  : _floodRepository = floodRepository,
        _gpsRepository = gpsRepository,
        _riskRepository = riskRepository,
        _warningBuilder = warningBuilder {
    _controller.add(DriverDashboardHud.idle());
  }

  final FloodDetectionRepository _floodRepository;
  final GpsRepository _gpsRepository;
  final RiskAnalysisRepository _riskRepository;
  final DriverWarningBuilder _warningBuilder;

  final StreamController<DriverDashboardHud> _controller =
      StreamController<DriverDashboardHud>.broadcast();

  StreamSubscription<FloodSegmentationResult>? _floodSub;
  StreamSubscription<GpsFix>? _gpsSub;
  StreamSubscription<RiskAssessment>? _riskSub;

  bool _live = false;
  DriverDashboardHud _hud = DriverDashboardHud.idle();
  List<RiskRecommendation> _recommendations = const [];
  DateTime? _lastEmitAt;

  static const Duration _emitInterval = Duration(milliseconds: 120);

  @override
  Stream<DriverDashboardHud> get hudStream => _controller.stream;

  @override
  bool get isLive => _live;

  @override
  Future<void> startLive() async {
    if (_live) return;
    try {
      await _riskRepository.startMonitoring();

      _floodSub = _floodRepository.watchResults().listen(
            _onFlood,
            cancelOnError: false,
          );
      _gpsSub = _gpsRepository.watchFixes().listen(
            _onGps,
            cancelOnError: false,
          );
      _riskSub = _riskRepository.watchAssessments().listen(
            _onRisk,
            cancelOnError: false,
          );

      _live = true;
      _emit(force: true);
    } catch (error, stackTrace) {
      await _cancelSubs();
      _live = false;
      throw DeviceRiskException(
        message: 'Failed to start driver dashboard: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopLive() async {
    await _cancelSubs();
    await _riskRepository.stopMonitoring();
    _live = false;
    _emit(force: true);
  }

  @override
  Future<void> dispose() async {
    await stopLive();
  }

  void _onFlood(FloodSegmentationResult result) {
    _hud = _hud.copyWith(
      floodCoveragePercent: result.stats.waterCoveragePercent,
      hasFloodSample: true,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void _onGps(GpsFix fix) {
    _hud = _hud.copyWith(
      speedKmh: fix.speedKmh ?? 0,
      hasGpsFix: true,
      latitude: fix.latitude,
      longitude: fix.longitude,
      gpsAccuracyMeters: fix.accuracyMeters,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void _onRisk(RiskAssessment assessment) {
    _recommendations = assessment.recommendations;
    _hud = _hud.copyWith(
      riskLevel: assessment.level,
      riskScore: assessment.score,
      hasRiskAssessment: true,
      floodCoveragePercent: assessment.inputs.hasFloodSample
          ? assessment.inputs.floodCoveragePercent
          : _hud.floodCoveragePercent,
      hasFloodSample:
          assessment.inputs.hasFloodSample || _hud.hasFloodSample,
      speedKmh: assessment.inputs.hasGpsFix
          ? assessment.inputs.speedKmh
          : _hud.speedKmh,
      hasGpsFix: assessment.inputs.hasGpsFix || _hud.hasGpsFix,
      latitude: assessment.inputs.latitude ?? _hud.latitude,
      longitude: assessment.inputs.longitude ?? _hud.longitude,
      gpsAccuracyMeters:
          assessment.inputs.gpsAccuracyMeters ?? _hud.gpsAccuracyMeters,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  void _emit({bool force = false}) {
    final now = DateTime.now();
    final last = _lastEmitAt;
    if (!force &&
        last != null &&
        now.difference(last) < _emitInterval) {
      return;
    }

    final warnings = _warningBuilder.build(
      floodCoveragePercent: _hud.floodCoveragePercent,
      hasFloodSample: _hud.hasFloodSample,
      speedKmh: _hud.speedKmh,
      hasGpsFix: _hud.hasGpsFix,
      gpsAccuracyMeters: _hud.gpsAccuracyMeters,
      riskLevel: _hud.riskLevel,
      hasRiskAssessment: _hud.hasRiskAssessment,
      recommendations: _recommendations,
    );

    final next = _hud.copyWith(
      warnings: warnings,
      isLive: _live,
      updatedAt: now,
    );

    // Skip fan-out when visible HUD content is unchanged (IMU ticks spam otherwise).
    if (!force && _sameHudContent(_hud, next)) {
      return;
    }

    _lastEmitAt = now;
    _hud = next;

    if (!_controller.isClosed) {
      _controller.add(_hud);
    }
  }

  /// Compares HUD fields that drive UI, ignoring [DriverDashboardHud.updatedAt].
  bool _sameHudContent(DriverDashboardHud a, DriverDashboardHud b) {
    return a.floodCoveragePercent == b.floodCoveragePercent &&
        a.hasFloodSample == b.hasFloodSample &&
        a.riskLevel == b.riskLevel &&
        a.riskScore == b.riskScore &&
        a.hasRiskAssessment == b.hasRiskAssessment &&
        a.speedKmh == b.speedKmh &&
        a.hasGpsFix == b.hasGpsFix &&
        a.latitude == b.latitude &&
        a.longitude == b.longitude &&
        a.gpsAccuracyMeters == b.gpsAccuracyMeters &&
        a.isLive == b.isLive &&
        _sameWarnings(a.warnings, b.warnings);
  }

  bool _sameWarnings(List<DriverWarning> a, List<DriverWarning> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _cancelSubs() async {
    await _floodSub?.cancel();
    await _gpsSub?.cancel();
    await _riskSub?.cancel();
    _floodSub = null;
    _gpsSub = null;
    _riskSub = null;
  }
}
