import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';

/// [CameraRepository] implementation mapping data-source exceptions to [Failure]s.
class CameraRepositoryImpl implements CameraRepository {
  final CameraLocalDataSource _dataSource;
  final ErrorHandler _errorHandler;

  /// Creates [CameraRepositoryImpl].
  CameraRepositoryImpl({
    required CameraLocalDataSource dataSource,
    required ErrorHandler errorHandler,
  })  : _dataSource = dataSource,
        _errorHandler = errorHandler;

  @override
  Future<Result<CameraPermissionStatus>> checkPermission() {
    return _guard(() => _dataSource.checkPermission());
  }

  @override
  Future<Result<CameraPermissionStatus>> requestPermission() {
    return _guard(() => _dataSource.requestPermission());
  }

  @override
  Future<Result<bool>> openPermissionSettings() {
    return _guard(() => _dataSource.openPermissionSettings());
  }

  @override
  Future<Result<CameraSession>> initialize({
    CameraLensPreference lens = CameraLensPreference.rear,
  }) {
    return _guard(() => _dataSource.initialize(lens: lens));
  }

  @override
  Future<Result<CameraSession>> pause() {
    return _guard(_dataSource.pause);
  }

  @override
  Future<Result<CameraSession>> resume() {
    return _guard(_dataSource.resume);
  }

  @override
  Future<Result<CameraSession>> startFrameStreaming({int targetFps = 8}) {
    return _guard(() => _dataSource.startFrameStreaming(targetFps: targetFps));
  }

  @override
  Future<Result<CameraSession>> stopFrameStreaming() {
    return _guard(_dataSource.stopFrameStreaming);
  }

  @override
  Future<Result<void>> disposeCamera() {
    return _guard(_dataSource.disposeCamera);
  }

  @override
  Future<Result<CameraSession>> handleOrientationChanged(int degrees) {
    return _guard(() => _dataSource.handleOrientationChanged(degrees));
  }

  @override
  Stream<CameraSession> watchSession() => _dataSource.sessionStream;

  @override
  Stream<CameraFrameMeta> watchFrames() => _dataSource.frameStream;

  @override
  Stream<CameraRawFrame> watchRawFrames() => _dataSource.rawFrameStream;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Ok(value);
    } on Failure catch (failure) {
      return Err(failure);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
