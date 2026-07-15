import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/sensor_fusion_repository.dart';
import 'package:equatable/equatable.dart';

class LoadSensorFusionSnapshotUseCase
    extends UseCase<Result<SensorFusionSnapshot>, NoParams> {
  final SensorFusionRepository _repository;
  LoadSensorFusionSnapshotUseCase(this._repository);

  @override
  Future<Result<SensorFusionSnapshot>> call(NoParams params) =>
      _repository.loadSnapshot();
}

class StartSensorFusionParams extends Equatable {
  final bool enableCamera;
  final bool enableGps;
  final bool enableImu;

  const StartSensorFusionParams({
    this.enableCamera = true,
    this.enableGps = true,
    this.enableImu = true,
  });

  @override
  List<Object?> get props => [enableCamera, enableGps, enableImu];
}

class StartSensorFusionUseCase
    extends UseCase<Result<SensorFusionSession>, StartSensorFusionParams> {
  final SensorFusionRepository _repository;
  StartSensorFusionUseCase(this._repository);

  @override
  Future<Result<SensorFusionSession>> call(StartSensorFusionParams params) =>
      _repository.startFusion(
        enableCamera: params.enableCamera,
        enableGps: params.enableGps,
        enableImu: params.enableImu,
      );
}

class StopSensorFusionUseCase
    extends UseCase<Result<SensorFusionSession>, NoParams> {
  final SensorFusionRepository _repository;
  StopSensorFusionUseCase(this._repository);

  @override
  Future<Result<SensorFusionSession>> call(NoParams params) =>
      _repository.stopFusion();
}

class FuseSensorTickUseCase
    extends UseCase<Result<FusedSample>, NoParams> {
  final SensorFusionRepository _repository;
  FuseSensorTickUseCase(this._repository);

  @override
  Future<Result<FusedSample>> call(NoParams params) =>
      _repository.fuseTick();
}

class CreateDemoFusedSampleUseCase
    extends UseCase<Result<FusedSample>, NoParams> {
  final SensorFusionRepository _repository;
  CreateDemoFusedSampleUseCase(this._repository);

  @override
  Future<Result<FusedSample>> call(NoParams params) =>
      _repository.createDemoSample();
}

class ClearFusionSamplesUseCase extends UseCase<Result<void>, NoParams> {
  final SensorFusionRepository _repository;
  ClearFusionSamplesUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.clearSamples();
}
