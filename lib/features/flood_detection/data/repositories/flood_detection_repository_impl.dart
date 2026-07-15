import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/datasources/tflite_flood_segmentation_data_source.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';

/// Maps segmentation data-source results to domain [Result]s.
class FloodDetectionRepositoryImpl implements FloodDetectionRepository {
  final FloodSegmentationDataSource _dataSource;
  final ErrorHandler _errorHandler;

  /// Creates [FloodDetectionRepositoryImpl].
  FloodDetectionRepositoryImpl({
    required FloodSegmentationDataSource dataSource,
    required ErrorHandler errorHandler,
  })  : _dataSource = dataSource,
        _errorHandler = errorHandler;

  /// Exposes overlay pixels for the painter (presentation adapter).
  FloodSegmentationDataSource get dataSource => _dataSource;

  @override
  Future<Result<FloodDetectionSession>> initialize() {
    return _guard(_dataSource.initialize);
  }

  @override
  Future<Result<FloodDetectionSession>> start() {
    return _guard(_dataSource.start);
  }

  @override
  Future<Result<FloodDetectionSession>> stop() {
    return _guard(_dataSource.stop);
  }

  @override
  Future<Result<void>> disposeEngine() {
    return _guard(_dataSource.disposeEngine);
  }

  @override
  Future<Result<FloodSegmentationResult>> segment(CameraRawFrame frame) {
    return _guard(() => _dataSource.segment(frame));
  }

  @override
  Stream<FloodSegmentationResult> watchResults() => _dataSource.resultStream;

  @override
  Stream<FloodDetectionSession> watchSession() => _dataSource.sessionStream;

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
