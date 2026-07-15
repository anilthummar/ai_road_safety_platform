import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/gps/data/datasources/gps_local_data_source.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';

/// Maps GPS data-source exceptions to domain [Result]s.
class GpsRepositoryImpl implements GpsRepository {
  final GpsLocalDataSource _dataSource;
  final ErrorHandler _errorHandler;

  /// Creates [GpsRepositoryImpl].
  GpsRepositoryImpl({
    required GpsLocalDataSource dataSource,
    required ErrorHandler errorHandler,
  })  : _dataSource = dataSource,
        _errorHandler = errorHandler;

  @override
  Future<Result<GpsPermissionStatus>> checkPermission() {
    return _guard(_dataSource.checkPermission);
  }

  @override
  Future<Result<GpsPermissionStatus>> requestPermission() {
    return _guard(_dataSource.requestPermission);
  }

  @override
  Future<Result<bool>> openPermissionSettings() {
    return _guard(_dataSource.openPermissionSettings);
  }

  @override
  Future<Result<bool>> openLocationSettings() {
    return _guard(_dataSource.openLocationSettings);
  }

  @override
  Future<Result<bool>> isServiceEnabled() {
    return _guard(_dataSource.isServiceEnabled);
  }

  @override
  Future<Result<GpsFix>> getCurrentLocation() {
    return _guard(_dataSource.getCurrentLocation);
  }

  @override
  Future<Result<GpsSession>> startTracking() {
    return _guard(_dataSource.startTracking);
  }

  @override
  Future<Result<GpsSession>> stopTracking() {
    return _guard(_dataSource.stopTracking);
  }

  @override
  Future<Result<void>> disposeGps() {
    return _guard(_dataSource.disposeGps);
  }

  @override
  Stream<GpsFix> watchFixes() => _dataSource.fixStream;

  @override
  Stream<GpsSession> watchSession() => _dataSource.sessionStream;

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
