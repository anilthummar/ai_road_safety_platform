import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/metadata_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/metadata_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer.dart';

/// Memory-backed [MetadataRepository] using [MetadataSynchronizer].
class MetadataRepositoryImpl implements MetadataRepository {
  final MetadataLocalDataSource _local;
  final MetadataSynchronizer _synchronizer;
  final SensorSnapshotProvider _sensors;
  final ErrorHandler _errorHandler;

  /// Creates [MetadataRepositoryImpl].
  MetadataRepositoryImpl({
    required MetadataLocalDataSource localDataSource,
    required MetadataSynchronizer synchronizer,
    required SensorSnapshotProvider sensors,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _synchronizer = synchronizer,
        _sensors = sensors,
        _errorHandler = errorHandler {
    _sensors.start();
  }

  @override
  SensorStatusSnapshot get sensorStatus => _sensors.status;

  @override
  Future<Result<FrameMetadata>> generateMetadata(CapturedFrame frame) {
    return _guard(() async {
      if (frame.sessionId.trim().isEmpty) {
        throw const CacheException(message: 'Missing Session for metadata.');
      }
      final frameNumber = _local.nextFrameNumber(frame.sessionId);
      final metadata = await _synchronizer.synchronize(
        frame: frame,
        frameNumber: frameNumber,
      );
      _local.save(metadata);
      return metadata;
    });
  }

  @override
  Future<Result<FrameMetadata>> synchronizeMetadata(CapturedFrame frame) {
    return generateMetadata(frame);
  }

  @override
  Future<Result<FrameMetadata?>> getLatestMetadata() {
    return _guard(() async => _local.latest);
  }

  @override
  Future<Result<void>> clearMetadata() {
    return _guard(() async => _local.clear());
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
