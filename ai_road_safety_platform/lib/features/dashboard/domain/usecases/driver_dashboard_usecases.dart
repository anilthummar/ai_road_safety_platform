import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/repositories/driver_dashboard_repository.dart';

/// Starts live driver HUD fusion.
class StartDriverDashboardUseCase extends UseCase<Result<void>, NoParams> {
  final DriverDashboardRepository _repository;

  /// Creates [StartDriverDashboardUseCase].
  StartDriverDashboardUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.startLive();
}

/// Stops live driver HUD fusion.
class StopDriverDashboardUseCase extends UseCase<Result<void>, NoParams> {
  final DriverDashboardRepository _repository;

  /// Creates [StopDriverDashboardUseCase].
  StopDriverDashboardUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.stopLive();
}

/// Releases dashboard resources.
class DisposeDriverDashboardUseCase extends UseCase<Result<void>, NoParams> {
  final DriverDashboardRepository _repository;

  /// Creates [DisposeDriverDashboardUseCase].
  DisposeDriverDashboardUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.dispose();
}
