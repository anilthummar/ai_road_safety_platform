import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/imu/data/datasources/imu_local_data_source.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';

/// Maps IMU data-source exceptions to domain [Result]s.
class ImuRepositoryImpl implements ImuRepository {
  final ImuLocalDataSource _local;
  final ErrorHandler _errorHandler;

  /// Creates [ImuRepositoryImpl].
  ImuRepositoryImpl({
    required ImuLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _errorHandler = errorHandler;

  @override
  Stream<ImuSession> get sessionStream => _local.sessionStream;

  @override
  Stream<ImuSample> get sampleStream => _local.sampleStream;

  @override
  Future<Result<void>> startStreaming() {
    return _guard(_local.startStreaming);
  }

  @override
  Future<Result<void>> stopStreaming() {
    return _guard(_local.stopStreaming);
  }

  @override
  Future<Result<ImuCalibration>> calibrate() {
    return _guard(_local.calibrate);
  }

  @override
  Future<Result<void>> dispose() {
    return _guard(_local.dispose);
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
