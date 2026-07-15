import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer.dart';

/// Default [MetadataSynchronizer] — merge + validate + log (no disk I/O).
class MetadataSynchronizerImpl implements MetadataSynchronizer {
  final SensorSnapshotProvider _sensors;
  final AppLogger _logger;

  /// Creates [MetadataSynchronizerImpl].
  MetadataSynchronizerImpl({
    required SensorSnapshotProvider sensors,
    required AppLogger logger,
  })  : _sensors = sensors,
        _logger = logger;

  @override
  Future<FrameMetadata> synchronize({
    required CapturedFrame frame,
    required int frameNumber,
  }) async {
    final at = DateTime.now();
    try {
      final bundle = await _sensors.collect(frame: frame, at: at);
      final warnings = <String>[];

      if (!bundle.location.isAvailable) {
        warnings.add('Missing GPS');
        _logger.warning('Missing Sensor Data: GPS', tag: 'MetadataSync');
      }
      if (!bundle.motion.isAvailable) {
        warnings.add('Missing IMU');
        _logger.warning('Missing Sensor Data: IMU', tag: 'MetadataSync');
      }
      if (!bundle.inference.isAvailable) {
        warnings.add('Missing AI');
        _logger.warning('Missing Sensor Data: AI', tag: 'MetadataSync');
      }

      final hasSession = frame.sessionId.trim().isNotEmpty;
      if (!hasSession) {
        warnings.add('Missing Session');
        _logger.warning('Missing Sensor Data: Session', tag: 'MetadataSync');
      }

      final hasTimestamp = true; // CapturedFrame always has timestamp
      // (validated here for completeness)
      if (frame.timestamp.millisecondsSinceEpoch <= 0) {
        warnings.add('Missing Timestamp');
        _logger.warning('Missing Sensor Data: Timestamp', tag: 'MetadataSync');
      }

      final validation = MetadataValidation(
        hasGps: bundle.location.isAvailable,
        hasImu: bundle.motion.isAvailable,
        hasAi: bundle.inference.isAvailable,
        hasSession: hasSession,
        hasTimestamp: hasTimestamp,
        warnings: warnings,
      );

      final session = SessionMetadata(
        sessionId: frame.sessionId,
        frameNumber: frameNumber,
        captureReason: frame.captureReason.message,
        captureType: frame.captureType,
        capturedAt: frame.timestamp,
        frameId: frame.frameId,
      );

      final metadata = FrameMetadata(
        location: bundle.location,
        motion: bundle.motion,
        inference: bundle.inference,
        device: bundle.device.copyWithRotation(frame.rotation),
        session: session,
        validation: validation,
        synchronizedAt: at,
      );

      _logger.info(
        'Metadata Created frame=${frame.frameId} n=$frameNumber',
        tag: 'MetadataSync',
      );
      _logger.info('Synchronization Success', tag: 'MetadataSync');
      return metadata;
    } catch (e, st) {
      _logger.error(
        'Synchronization Failure: $e',
        tag: 'MetadataSync',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}

/// Local helper — DeviceMetadata is immutable so we copy with rotation.
extension on DeviceMetadata {
  DeviceMetadata copyWithRotation(int rotation) {
    return DeviceMetadata(
      deviceModel: deviceModel,
      manufacturer: manufacturer,
      androidVersion: androidVersion,
      batteryLevel: batteryLevel,
      chargingStatus: chargingStatus,
      screenRotation: rotation,
      appVersion: appVersion,
    );
  }
}
