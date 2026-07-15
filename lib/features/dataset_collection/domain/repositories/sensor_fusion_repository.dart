import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';

/// Multi-sensor fusion session + sample ring buffer (Phase 13.7).
abstract class SensorFusionRepository {
  Future<Result<SensorFusionSnapshot>> loadSnapshot();

  Future<Result<SensorFusionSession>> startFusion({
    bool enableCamera = true,
    bool enableGps = true,
    bool enableImu = true,
  });

  Future<Result<SensorFusionSession>> stopFusion();

  /// Push a manual / tick fusion using latest caches (+ optional overrides).
  Future<Result<FusedSample>> fuseTick({
    DateTime? at,
    FusedCameraRef? camera,
    GpsFix? gpsOverride,
    ImuSample? imuOverride,
  });

  Future<Result<FusedSample>> createDemoSample();

  Future<Result<void>> clearSamples();
}
