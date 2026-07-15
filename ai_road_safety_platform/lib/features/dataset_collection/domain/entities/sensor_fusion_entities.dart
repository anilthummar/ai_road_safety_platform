import 'package:equatable/equatable.dart';

/// Sensor modality in the fusion framework (Phase 13.7).
enum FusionSensorChannel {
  camera,
  gps,
  imu,
  sonar,
}

extension FusionSensorChannelX on FusionSensorChannel {
  String get label => switch (this) {
        FusionSensorChannel.camera => 'Camera',
        FusionSensorChannel.gps => 'GPS',
        FusionSensorChannel.imu => 'IMU',
        FusionSensorChannel.sonar => 'Sonar',
      };
}

/// Live / stale / missing channel health.
enum FusionChannelHealth {
  live,
  stale,
  missing,
  disabled,
}

extension FusionChannelHealthX on FusionChannelHealth {
  String get label => switch (this) {
        FusionChannelHealth.live => 'Live',
        FusionChannelHealth.stale => 'Stale',
        FusionChannelHealth.missing => 'Missing',
        FusionChannelHealth.disabled => 'Disabled',
      };
}

/// Overall fusion sample quality band.
enum FusionQualityBand {
  high,
  medium,
  low,
  incomplete,
}

extension FusionQualityBandX on FusionQualityBand {
  String get label => switch (this) {
        FusionQualityBand.high => 'High',
        FusionQualityBand.medium => 'Medium',
        FusionQualityBand.low => 'Low',
        FusionQualityBand.incomplete => 'Incomplete',
      };
}

/// Compact GPS slice carried on a fused sample.
class FusedGpsSlice extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double? speedKmh;
  final double? headingDegrees;
  final DateTime timestamp;
  final int ageMs;

  const FusedGpsSlice({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    required this.ageMs,
    this.speedKmh,
    this.headingDegrees,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'speedKmh': speedKmh,
        'headingDegrees': headingDegrees,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'ageMs': ageMs,
      };

  factory FusedGpsSlice.fromJson(Map<String, dynamic> json) {
    return FusedGpsSlice(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble() ?? 0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble(),
      headingDegrees: (json['headingDegrees'] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ageMs: (json['ageMs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracyMeters,
        speedKmh,
        headingDegrees,
        timestamp,
        ageMs,
      ];
}

/// Compact IMU slice carried on a fused sample.
class FusedImuSlice extends Equatable {
  final double accelMagnitude;
  final double gyroMagnitude;
  final double tiltDegrees;
  final double pitchDegrees;
  final double rollDegrees;
  final DateTime timestamp;
  final int ageMs;

  const FusedImuSlice({
    required this.accelMagnitude,
    required this.gyroMagnitude,
    required this.tiltDegrees,
    required this.pitchDegrees,
    required this.rollDegrees,
    required this.timestamp,
    required this.ageMs,
  });

  Map<String, dynamic> toJson() => {
        'accelMagnitude': accelMagnitude,
        'gyroMagnitude': gyroMagnitude,
        'tiltDegrees': tiltDegrees,
        'pitchDegrees': pitchDegrees,
        'rollDegrees': rollDegrees,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'ageMs': ageMs,
      };

  factory FusedImuSlice.fromJson(Map<String, dynamic> json) {
    return FusedImuSlice(
      accelMagnitude: (json['accelMagnitude'] as num?)?.toDouble() ?? 0,
      gyroMagnitude: (json['gyroMagnitude'] as num?)?.toDouble() ?? 0,
      tiltDegrees: (json['tiltDegrees'] as num?)?.toDouble() ?? 0,
      pitchDegrees: (json['pitchDegrees'] as num?)?.toDouble() ?? 0,
      rollDegrees: (json['rollDegrees'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ageMs: (json['ageMs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        accelMagnitude,
        gyroMagnitude,
        tiltDegrees,
        pitchDegrees,
        rollDegrees,
        timestamp,
        ageMs,
      ];
}

/// Future sonar channel placeholder (not live yet).
class FusedSonarSlice extends Equatable {
  final double? rangeMeters;
  final DateTime? timestamp;
  final int ageMs;
  final bool available;

  const FusedSonarSlice({
    this.rangeMeters,
    this.timestamp,
    this.ageMs = 0,
    this.available = false,
  });

  const FusedSonarSlice.unavailable()
      : rangeMeters = null,
        timestamp = null,
        ageMs = 0,
        available = false;

  Map<String, dynamic> toJson() => {
        'rangeMeters': rangeMeters,
        'timestamp': timestamp?.toUtc().toIso8601String(),
        'ageMs': ageMs,
        'available': available,
      };

  factory FusedSonarSlice.fromJson(Map<String, dynamic> json) {
    return FusedSonarSlice(
      rangeMeters: (json['rangeMeters'] as num?)?.toDouble(),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc(),
      ageMs: (json['ageMs'] as num?)?.toInt() ?? 0,
      available: json['available'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [rangeMeters, timestamp, ageMs, available];
}

/// Camera frame reference attached to a fused sample.
class FusedCameraRef extends Equatable {
  final String? sessionId;
  final int? sequence;
  final DateTime timestamp;
  final int? width;
  final int? height;

  const FusedCameraRef({
    required this.timestamp,
    this.sessionId,
    this.sequence,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sequence': sequence,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'width': width,
        'height': height,
      };

  factory FusedCameraRef.fromJson(Map<String, dynamic> json) {
    return FusedCameraRef(
      sessionId: json['sessionId'] as String?,
      sequence: (json['sequence'] as num?)?.toInt(),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [sessionId, sequence, timestamp, width, height];
}

/// One time-aligned multi-sensor observation.
class FusedSample extends Equatable {
  final String id;
  final DateTime timestamp;
  final FusedCameraRef? camera;
  final FusedGpsSlice? gps;
  final FusedImuSlice? imu;
  final FusedSonarSlice sonar;
  final double qualityScore;
  final FusionQualityBand qualityBand;
  final List<FusionSensorChannel> sourcesPresent;
  final String notes;

  const FusedSample({
    required this.id,
    required this.timestamp,
    required this.qualityScore,
    required this.qualityBand,
    required this.sourcesPresent,
    this.camera,
    this.gps,
    this.imu,
    this.sonar = const FusedSonarSlice.unavailable(),
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'camera': camera?.toJson(),
        'gps': gps?.toJson(),
        'imu': imu?.toJson(),
        'sonar': sonar.toJson(),
        'qualityScore': qualityScore,
        'qualityBand': qualityBand.name,
        'sourcesPresent': [for (final s in sourcesPresent) s.name],
        'notes': notes,
      };

  factory FusedSample.fromJson(Map<String, dynamic> json) {
    return FusedSample(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      camera: json['camera'] is Map
          ? FusedCameraRef.fromJson(
              Map<String, dynamic>.from(json['camera'] as Map),
            )
          : null,
      gps: json['gps'] is Map
          ? FusedGpsSlice.fromJson(Map<String, dynamic>.from(json['gps'] as Map))
          : null,
      imu: json['imu'] is Map
          ? FusedImuSlice.fromJson(Map<String, dynamic>.from(json['imu'] as Map))
          : null,
      sonar: json['sonar'] is Map
          ? FusedSonarSlice.fromJson(
              Map<String, dynamic>.from(json['sonar'] as Map),
            )
          : const FusedSonarSlice.unavailable(),
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0,
      qualityBand: FusionQualityBand.values.firstWhere(
        (b) => b.name == json['qualityBand'],
        orElse: () => FusionQualityBand.incomplete,
      ),
      sourcesPresent: [
        for (final s in (json['sourcesPresent'] as List? ?? const []))
          FusionSensorChannel.values.firstWhere(
            (c) => c.name == s.toString(),
            orElse: () => FusionSensorChannel.camera,
          ),
      ],
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        camera,
        gps,
        imu,
        sonar,
        qualityScore,
        qualityBand,
        sourcesPresent,
        notes,
      ];
}

/// Per-channel health for the fusion dashboard.
class FusionChannelStatus extends Equatable {
  final FusionSensorChannel channel;
  final FusionChannelHealth health;
  final DateTime? lastSampleAt;
  final int ageMs;
  final String detail;

  const FusionChannelStatus({
    required this.channel,
    required this.health,
    required this.ageMs,
    this.lastSampleAt,
    this.detail = '',
  });

  Map<String, dynamic> toJson() => {
        'channel': channel.name,
        'health': health.name,
        'lastSampleAt': lastSampleAt?.toUtc().toIso8601String(),
        'ageMs': ageMs,
        'detail': detail,
      };

  factory FusionChannelStatus.fromJson(Map<String, dynamic> json) {
    return FusionChannelStatus(
      channel: FusionSensorChannel.values.firstWhere(
        (c) => c.name == json['channel'],
        orElse: () => FusionSensorChannel.camera,
      ),
      health: FusionChannelHealth.values.firstWhere(
        (h) => h.name == json['health'],
        orElse: () => FusionChannelHealth.missing,
      ),
      lastSampleAt:
          DateTime.tryParse(json['lastSampleAt'] as String? ?? '')?.toUtc(),
      ageMs: (json['ageMs'] as num?)?.toInt() ?? 0,
      detail: json['detail'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [channel, health, lastSampleAt, ageMs, detail];
}

/// Active / idle fusion session metadata.
class SensorFusionSession extends Equatable {
  final String id;
  final bool isRunning;
  final DateTime startedAt;
  final DateTime? stoppedAt;
  final int sampleCount;
  final bool cameraEnabled;
  final bool gpsEnabled;
  final bool imuEnabled;
  final bool sonarEnabled;
  final String notes;

  const SensorFusionSession({
    required this.id,
    required this.isRunning,
    required this.startedAt,
    this.stoppedAt,
    this.sampleCount = 0,
    this.cameraEnabled = true,
    this.gpsEnabled = true,
    this.imuEnabled = true,
    this.sonarEnabled = false,
    this.notes = '',
  });

  SensorFusionSession copyWith({
    String? id,
    bool? isRunning,
    DateTime? startedAt,
    DateTime? stoppedAt,
    int? sampleCount,
    bool? cameraEnabled,
    bool? gpsEnabled,
    bool? imuEnabled,
    bool? sonarEnabled,
    String? notes,
    bool clearStoppedAt = false,
  }) {
    return SensorFusionSession(
      id: id ?? this.id,
      isRunning: isRunning ?? this.isRunning,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: clearStoppedAt ? null : (stoppedAt ?? this.stoppedAt),
      sampleCount: sampleCount ?? this.sampleCount,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      imuEnabled: imuEnabled ?? this.imuEnabled,
      sonarEnabled: sonarEnabled ?? this.sonarEnabled,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isRunning': isRunning,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'stoppedAt': stoppedAt?.toUtc().toIso8601String(),
        'sampleCount': sampleCount,
        'cameraEnabled': cameraEnabled,
        'gpsEnabled': gpsEnabled,
        'imuEnabled': imuEnabled,
        'sonarEnabled': sonarEnabled,
        'notes': notes,
      };

  factory SensorFusionSession.fromJson(Map<String, dynamic> json) {
    return SensorFusionSession(
      id: json['id'] as String? ?? '',
      isRunning: json['isRunning'] as bool? ?? false,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      stoppedAt:
          DateTime.tryParse(json['stoppedAt'] as String? ?? '')?.toUtc(),
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      cameraEnabled: json['cameraEnabled'] as bool? ?? true,
      gpsEnabled: json['gpsEnabled'] as bool? ?? true,
      imuEnabled: json['imuEnabled'] as bool? ?? true,
      sonarEnabled: json['sonarEnabled'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        isRunning,
        startedAt,
        stoppedAt,
        sampleCount,
        cameraEnabled,
        gpsEnabled,
        imuEnabled,
        sonarEnabled,
        notes,
      ];
}

/// Dashboard aggregate for sensor fusion.
class SensorFusionSnapshot extends Equatable {
  final SensorFusionSession? session;
  final List<FusedSample> recentSamples;
  final List<FusionChannelStatus> channels;
  final DateTime generatedAt;

  const SensorFusionSnapshot({
    required this.recentSamples,
    required this.channels,
    required this.generatedAt,
    this.session,
  });

  bool get isRunning => session?.isRunning ?? false;

  FusedSample? get latestSample =>
      recentSamples.isEmpty ? null : recentSamples.first;

  double get averageQuality {
    if (recentSamples.isEmpty) return 0;
    final sum =
        recentSamples.fold<double>(0, (a, s) => a + s.qualityScore);
    return sum / recentSamples.length;
  }

  @override
  List<Object?> get props => [session, recentSamples, channels, generatedAt];
}

/// Tunable freshness thresholds for fusion quality.
class SensorFusionConfig extends Equatable {
  final int gpsStaleMs;
  final int imuStaleMs;
  final int cameraStaleMs;
  final int maxBufferedSamples;

  const SensorFusionConfig({
    this.gpsStaleMs = 3000,
    this.imuStaleMs = 500,
    this.cameraStaleMs = 1000,
    this.maxBufferedSamples = 50,
  });

  static const SensorFusionConfig defaults = SensorFusionConfig();

  @override
  List<Object?> get props =>
      [gpsStaleMs, imuStaleMs, cameraStaleMs, maxBufferedSamples];
}
