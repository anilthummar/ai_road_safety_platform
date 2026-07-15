import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dashboard/data/datasources/driver_dashboard_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/repositories/driver_dashboard_repository.dart';

/// Maps dashboard data-source exceptions to domain [Result]s.
class DriverDashboardRepositoryImpl implements DriverDashboardRepository {
  final DriverDashboardLocalDataSource _local;
  final ErrorHandler _errorHandler;

  /// Creates [DriverDashboardRepositoryImpl].
  DriverDashboardRepositoryImpl({
    required DriverDashboardLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _errorHandler = errorHandler;

  @override
  Stream<DriverDashboardHud> watchHud() => _local.hudStream;

  @override
  Future<Result<void>> startLive() {
    return _guard(_local.startLive);
  }

  @override
  Future<Result<void>> stopLive() {
    return _guard(_local.stopLive);
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
