import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/datasources/tflite_inference_data_source.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/inference_repository.dart';

/// Maps [InferenceLocalDataSource] exceptions to domain [Result]s.
class InferenceRepositoryImpl implements InferenceRepository {
  final InferenceLocalDataSource _dataSource;
  final ErrorHandler _errorHandler;

  /// Creates [InferenceRepositoryImpl].
  InferenceRepositoryImpl({
    required InferenceLocalDataSource dataSource,
    required ErrorHandler errorHandler,
  })  : _dataSource = dataSource,
        _errorHandler = errorHandler;

  @override
  Future<Result<InferenceSession>> initialize() {
    return _guard(_dataSource.initialize);
  }

  @override
  Future<Result<InferenceSession>> start() {
    return _guard(_dataSource.start);
  }

  @override
  Future<Result<InferenceSession>> stop() {
    return _guard(_dataSource.stop);
  }

  @override
  Future<Result<void>> disposeEngine() {
    return _guard(_dataSource.disposeEngine);
  }

  @override
  Future<Result<InferenceResult>> detect(CameraRawFrame frame) {
    return _guard(() => _dataSource.detect(frame));
  }

  @override
  Stream<InferenceResult> watchResults() => _dataSource.resultStream;

  @override
  Stream<InferenceSession> watchSession() => _dataSource.sessionStream;

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
