import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:equatable/equatable.dart';

/// GNSS snapshot bound to a captured frame (Phase 12.4).
class LocationMetadata extends Equatable {
  /// Latitude degrees (0 when unknown).
  final double latitude;

  /// Longitude degrees (0 when unknown).
  final double longitude;

  /// Altitude meters (0 when unknown).
  final double altitude;

  /// Horizontal accuracy meters (large when unknown).
  final double accuracy;

  /// Heading degrees \[0–360) (0 when unknown).
  final double heading;

  /// Speed m/s (0 when unknown).
  final double speed;

  /// Sensor timestamp (or capture time fallback).
  final DateTime timestamp;

  /// True when a real GNSS fix was available.
  final bool isAvailable;

  /// Creates [LocationMetadata].
  const LocationMetadata({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.timestamp,
    this.isAvailable = true,
  });

  /// Missing GPS defaults (validates as missing).
  factory LocationMetadata.missing(DateTime at) {
    return LocationMetadata(
      latitude: 0,
      longitude: 0,
      altitude: 0,
      accuracy: 9999,
      heading: 0,
      speed: 0,
      timestamp: at,
      isAvailable: false,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        accuracy,
        heading,
        speed,
        timestamp,
        isAvailable,
      ];
}

/// IMU / orientation snapshot.
class MotionMetadata extends Equatable {
  /// Accel X (m/s²).
  final double accelerometerX;

  /// Accel Y.
  final double accelerometerY;

  /// Accel Z.
  final double accelerometerZ;

  /// Gyro X (rad/s).
  final double gyroscopeX;

  /// Gyro Y.
  final double gyroscopeY;

  /// Gyro Z.
  final double gyroscopeZ;

  /// Compass / yaw degrees when known; else pitch|roll summary label.
  final double orientation;

  /// True when IMU sample was present.
  final bool isAvailable;

  /// Creates [MotionMetadata].
  const MotionMetadata({
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.orientation,
    this.isAvailable = true,
  });

  /// Missing IMU defaults.
  const MotionMetadata.missing()
      : accelerometerX = 0,
        accelerometerY = 0,
        accelerometerZ = 0,
        gyroscopeX = 0,
        gyroscopeY = 0,
        gyroscopeZ = 0,
        orientation = 0,
        isAvailable = false;

  @override
  List<Object?> get props => [
        accelerometerX,
        accelerometerY,
        accelerometerZ,
        gyroscopeX,
        gyroscopeY,
        gyroscopeZ,
        orientation,
        isAvailable,
      ];
}

/// AI / flood / risk snapshot.
class InferenceMetadata extends Equatable {
  /// Short prediction label (e.g. water / clear).
  final String prediction;

  /// Model confidence \[0–1\].
  final double confidence;

  /// Water coverage percent \[0–100\].
  final double waterCoverage;

  /// Risk level label.
  final String riskLevel;

  /// Model asset / version tag.
  final String modelVersion;

  /// Inference duration ms.
  final double inferenceTimeMs;

  /// True when a flood result was present.
  final bool isAvailable;

  /// Creates [InferenceMetadata].
  const InferenceMetadata({
    required this.prediction,
    required this.confidence,
    required this.waterCoverage,
    required this.riskLevel,
    required this.modelVersion,
    required this.inferenceTimeMs,
    this.isAvailable = true,
  });

  /// Missing AI defaults.
  const InferenceMetadata.missing({
    this.modelVersion = 'pending',
  })  : prediction = 'unavailable',
        confidence = 0,
        waterCoverage = 0,
        riskLevel = 'unknown',
        inferenceTimeMs = 0,
        isAvailable = false;

  @override
  List<Object?> get props => [
        prediction,
        confidence,
        waterCoverage,
        riskLevel,
        modelVersion,
        inferenceTimeMs,
        isAvailable,
      ];
}

/// Device / battery snapshot (defaults when OS APIs unavailable).
class DeviceMetadata extends Equatable {
  /// Device model label.
  final String deviceModel;

  /// Manufacturer when known.
  final String manufacturer;

  /// OS version string.
  final String androidVersion;

  /// Battery percent \[0–100\]; `-1` when unknown.
  final int batteryLevel;

  /// `charging` / `discharging` / `full` / `unknown`.
  final String chargingStatus;

  /// Screen / sensor rotation degrees.
  final int screenRotation;

  /// App semantic version.
  final String appVersion;

  /// Creates [DeviceMetadata].
  const DeviceMetadata({
    required this.deviceModel,
    required this.manufacturer,
    required this.androidVersion,
    required this.batteryLevel,
    required this.chargingStatus,
    required this.screenRotation,
    required this.appVersion,
  });

  @override
  List<Object?> get props => [
        deviceModel,
        manufacturer,
        androidVersion,
        batteryLevel,
        chargingStatus,
        screenRotation,
        appVersion,
      ];
}

/// Session / capture identity snapshot.
class SessionMetadata extends Equatable {
  /// Dataset session id.
  final String sessionId;

  /// Monotonic frame number within the session.
  final int frameNumber;

  /// Capture reason message / rule id.
  final String captureReason;

  /// Capture type name.
  final CaptureType captureType;

  /// Capture wall time.
  final DateTime capturedAt;

  /// Source frame id.
  final String frameId;

  /// Creates [SessionMetadata].
  const SessionMetadata({
    required this.sessionId,
    required this.frameNumber,
    required this.captureReason,
    required this.captureType,
    required this.capturedAt,
    required this.frameId,
  });

  @override
  List<Object?> get props => [
        sessionId,
        frameNumber,
        captureReason,
        captureType,
        capturedAt,
        frameId,
      ];
}

/// Soft validation flags for missing sensors (defaults still applied).
class MetadataValidation extends Equatable {
  /// GPS present.
  final bool hasGps;

  /// IMU present.
  final bool hasImu;

  /// AI present.
  final bool hasAi;

  /// Session id non-empty.
  final bool hasSession;

  /// Timestamp present.
  final bool hasTimestamp;

  /// Human warnings for logs / UI.
  final List<String> warnings;

  /// Creates [MetadataValidation].
  const MetadataValidation({
    required this.hasGps,
    required this.hasImu,
    required this.hasAi,
    required this.hasSession,
    required this.hasTimestamp,
    this.warnings = const [],
  });

  /// True when no blocking identity issues (session + timestamp).
  bool get isAcceptable => hasSession && hasTimestamp;

  @override
  List<Object?> get props =>
      [hasGps, hasImu, hasAi, hasSession, hasTimestamp, warnings];
}

/// Fully synchronized per-frame metadata (memory only — Phase 12.4).
class FrameMetadata extends Equatable {
  /// Nested location block.
  final LocationMetadata location;

  /// Nested motion block.
  final MotionMetadata motion;

  /// Nested AI block.
  final InferenceMetadata inference;

  /// Nested device block.
  final DeviceMetadata device;

  /// Nested session block.
  final SessionMetadata session;

  /// Validation summary.
  final MetadataValidation validation;

  /// When this metadata object was built.
  final DateTime synchronizedAt;

  /// Creates [FrameMetadata].
  const FrameMetadata({
    required this.location,
    required this.motion,
    required this.inference,
    required this.device,
    required this.session,
    required this.validation,
    required this.synchronizedAt,
  });

  @override
  List<Object?> get props => [
        location,
        motion,
        inference,
        device,
        session,
        validation,
        synchronizedAt,
      ];
}

/// Live sensor health for developer UI.
class SensorStatusSnapshot extends Equatable {
  /// GPS cache warm.
  final bool gpsLive;

  /// IMU cache warm.
  final bool imuLive;

  /// Flood AI cache warm.
  final bool aiLive;

  /// Risk cache warm.
  final bool riskLive;

  /// Creates [SensorStatusSnapshot].
  const SensorStatusSnapshot({
    required this.gpsLive,
    required this.imuLive,
    required this.aiLive,
    required this.riskLive,
  });

  /// All cold.
  const SensorStatusSnapshot.cold()
      : gpsLive = false,
        imuLive = false,
        aiLive = false,
        riskLive = false;

  @override
  List<Object?> get props => [gpsLive, imuLive, aiLive, riskLive];
}
