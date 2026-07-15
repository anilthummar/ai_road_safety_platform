import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';

/// JSON codec for [FrameMetadata] (internal storage only — Phase 12.5).
class FrameMetadataJsonCodec {
  /// Encode to map.
  static Map<String, dynamic> toJson(FrameMetadata m) {
    return {
      'synchronizedAt': m.synchronizedAt.toIso8601String(),
      'location': {
        'latitude': m.location.latitude,
        'longitude': m.location.longitude,
        'altitude': m.location.altitude,
        'accuracy': m.location.accuracy,
        'heading': m.location.heading,
        'speed': m.location.speed,
        'timestamp': m.location.timestamp.toIso8601String(),
        'isAvailable': m.location.isAvailable,
      },
      'motion': {
        'accelerometerX': m.motion.accelerometerX,
        'accelerometerY': m.motion.accelerometerY,
        'accelerometerZ': m.motion.accelerometerZ,
        'gyroscopeX': m.motion.gyroscopeX,
        'gyroscopeY': m.motion.gyroscopeY,
        'gyroscopeZ': m.motion.gyroscopeZ,
        'orientation': m.motion.orientation,
        'isAvailable': m.motion.isAvailable,
      },
      'inference': {
        'prediction': m.inference.prediction,
        'confidence': m.inference.confidence,
        'waterCoverage': m.inference.waterCoverage,
        'riskLevel': m.inference.riskLevel,
        'modelVersion': m.inference.modelVersion,
        'inferenceTimeMs': m.inference.inferenceTimeMs,
        'isAvailable': m.inference.isAvailable,
      },
      'device': {
        'deviceModel': m.device.deviceModel,
        'manufacturer': m.device.manufacturer,
        'androidVersion': m.device.androidVersion,
        'batteryLevel': m.device.batteryLevel,
        'chargingStatus': m.device.chargingStatus,
        'screenRotation': m.device.screenRotation,
        'appVersion': m.device.appVersion,
      },
      'session': {
        'sessionId': m.session.sessionId,
        'frameNumber': m.session.frameNumber,
        'captureReason': m.session.captureReason,
        'captureType': m.session.captureType.name,
        'capturedAt': m.session.capturedAt.toIso8601String(),
        'frameId': m.session.frameId,
      },
      'validation': {
        'hasGps': m.validation.hasGps,
        'hasImu': m.validation.hasImu,
        'hasAi': m.validation.hasAi,
        'hasSession': m.validation.hasSession,
        'hasTimestamp': m.validation.hasTimestamp,
        'warnings': m.validation.warnings,
      },
    };
  }

  /// Decode from map.
  static FrameMetadata fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final mot = json['motion'] as Map<String, dynamic>? ?? {};
    final inf = json['inference'] as Map<String, dynamic>? ?? {};
    final dev = json['device'] as Map<String, dynamic>? ?? {};
    final ses = json['session'] as Map<String, dynamic>? ?? {};
    final val = json['validation'] as Map<String, dynamic>? ?? {};

    CaptureType captureType;
    try {
      captureType = CaptureType.values.byName(
        ses['captureType'] as String? ?? 'automatic',
      );
    } catch (_) {
      captureType = CaptureType.automatic;
    }

    return FrameMetadata(
      location: LocationMetadata(
        latitude: (loc['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (loc['longitude'] as num?)?.toDouble() ?? 0,
        altitude: (loc['altitude'] as num?)?.toDouble() ?? 0,
        accuracy: (loc['accuracy'] as num?)?.toDouble() ?? 9999,
        heading: (loc['heading'] as num?)?.toDouble() ?? 0,
        speed: (loc['speed'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.tryParse(loc['timestamp'] as String? ?? '') ??
            DateTime.now(),
        isAvailable: loc['isAvailable'] as bool? ?? false,
      ),
      motion: MotionMetadata(
        accelerometerX: (mot['accelerometerX'] as num?)?.toDouble() ?? 0,
        accelerometerY: (mot['accelerometerY'] as num?)?.toDouble() ?? 0,
        accelerometerZ: (mot['accelerometerZ'] as num?)?.toDouble() ?? 0,
        gyroscopeX: (mot['gyroscopeX'] as num?)?.toDouble() ?? 0,
        gyroscopeY: (mot['gyroscopeY'] as num?)?.toDouble() ?? 0,
        gyroscopeZ: (mot['gyroscopeZ'] as num?)?.toDouble() ?? 0,
        orientation: (mot['orientation'] as num?)?.toDouble() ?? 0,
        isAvailable: mot['isAvailable'] as bool? ?? false,
      ),
      inference: InferenceMetadata(
        prediction: inf['prediction'] as String? ?? 'unavailable',
        confidence: (inf['confidence'] as num?)?.toDouble() ?? 0,
        waterCoverage: (inf['waterCoverage'] as num?)?.toDouble() ?? 0,
        riskLevel: inf['riskLevel'] as String? ?? 'unknown',
        modelVersion: inf['modelVersion'] as String? ?? 'pending',
        inferenceTimeMs: (inf['inferenceTimeMs'] as num?)?.toDouble() ?? 0,
        isAvailable: inf['isAvailable'] as bool? ?? false,
      ),
      device: DeviceMetadata(
        deviceModel: dev['deviceModel'] as String? ?? 'unknown',
        manufacturer: dev['manufacturer'] as String? ?? 'unknown',
        androidVersion: dev['androidVersion'] as String? ?? 'unknown',
        batteryLevel: (dev['batteryLevel'] as num?)?.toInt() ?? -1,
        chargingStatus: dev['chargingStatus'] as String? ?? 'unknown',
        screenRotation: (dev['screenRotation'] as num?)?.toInt() ?? 0,
        appVersion: dev['appVersion'] as String? ?? '',
      ),
      session: SessionMetadata(
        sessionId: ses['sessionId'] as String? ?? '',
        frameNumber: (ses['frameNumber'] as num?)?.toInt() ?? 0,
        captureReason: ses['captureReason'] as String? ?? '',
        captureType: captureType,
        capturedAt: DateTime.tryParse(ses['capturedAt'] as String? ?? '') ??
            DateTime.now(),
        frameId: ses['frameId'] as String? ?? '',
      ),
      validation: MetadataValidation(
        hasGps: val['hasGps'] as bool? ?? false,
        hasImu: val['hasImu'] as bool? ?? false,
        hasAi: val['hasAi'] as bool? ?? false,
        hasSession: val['hasSession'] as bool? ?? false,
        hasTimestamp: val['hasTimestamp'] as bool? ?? true,
        warnings: (val['warnings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      ),
      synchronizedAt:
          DateTime.tryParse(json['synchronizedAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
