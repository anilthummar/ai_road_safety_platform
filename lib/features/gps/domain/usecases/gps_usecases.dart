import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/gps/domain/entities/gps_entities.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';

/// Checks GPS permission without a system dialog.
class CheckGpsPermissionUseCase
    extends UseCase<Result<GpsPermissionStatus>, NoParams> {
  final GpsRepository _repository;

  /// Creates [CheckGpsPermissionUseCase].
  CheckGpsPermissionUseCase(this._repository);

  @override
  Future<Result<GpsPermissionStatus>> call(NoParams params) {
    return _repository.checkPermission();
  }
}

/// Requests GPS permission from the OS.
class RequestGpsPermissionUseCase
    extends UseCase<Result<GpsPermissionStatus>, NoParams> {
  final GpsRepository _repository;

  /// Creates [RequestGpsPermissionUseCase].
  RequestGpsPermissionUseCase(this._repository);

  @override
  Future<Result<GpsPermissionStatus>> call(NoParams params) {
    return _repository.requestPermission();
  }
}

/// Opens the app settings page (permission permanently denied).
class OpenGpsSettingsUseCase extends UseCase<Result<bool>, NoParams> {
  final GpsRepository _repository;

  /// Creates [OpenGpsSettingsUseCase].
  OpenGpsSettingsUseCase(this._repository);

  @override
  Future<Result<bool>> call(NoParams params) {
    return _repository.openPermissionSettings();
  }
}

/// Opens the OS Location / GPS services screen.
class OpenGpsLocationSettingsUseCase extends UseCase<Result<bool>, NoParams> {
  final GpsRepository _repository;

  /// Creates [OpenGpsLocationSettingsUseCase].
  OpenGpsLocationSettingsUseCase(this._repository);

  @override
  Future<Result<bool>> call(NoParams params) {
    return _repository.openLocationSettings();
  }
}

/// Fetches a single high-accuracy fix.
class GetCurrentLocationUseCase extends UseCase<Result<GpsFix>, NoParams> {
  final GpsRepository _repository;

  /// Creates [GetCurrentLocationUseCase].
  GetCurrentLocationUseCase(this._repository);

  @override
  Future<Result<GpsFix>> call(NoParams params) {
    return _repository.getCurrentLocation();
  }
}

/// Starts continuous GNSS updates.
class StartGpsTrackingUseCase extends UseCase<Result<GpsSession>, NoParams> {
  final GpsRepository _repository;

  /// Creates [StartGpsTrackingUseCase].
  StartGpsTrackingUseCase(this._repository);

  @override
  Future<Result<GpsSession>> call(NoParams params) {
    return _repository.startTracking();
  }
}

/// Stops continuous GNSS updates.
class StopGpsTrackingUseCase extends UseCase<Result<GpsSession>, NoParams> {
  final GpsRepository _repository;

  /// Creates [StopGpsTrackingUseCase].
  StopGpsTrackingUseCase(this._repository);

  @override
  Future<Result<GpsSession>> call(NoParams params) {
    return _repository.stopTracking();
  }
}

/// Releases GPS resources.
class DisposeGpsUseCase extends UseCase<Result<void>, NoParams> {
  final GpsRepository _repository;

  /// Creates [DisposeGpsUseCase].
  DisposeGpsUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.disposeGps();
  }
}
