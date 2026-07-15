import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/pipeline_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_orchestrator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';

/// In-memory pipeline repository backed by [PipelineOrchestrator].
class PipelineRepositoryImpl implements PipelineRepository {
  final PipelineOrchestrator _orchestrator;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;

  PipelineRepositoryImpl({
    required PipelineOrchestrator orchestrator,
    required ErrorHandler errorHandler,
    required AppLogger logger,
  })  : _orchestrator = orchestrator,
        _errorHandler = errorHandler,
        _logger = logger;

  @override
  Future<Result<PipelineMonitorSnapshot>> startPipeline() {
    return _guard(() async {
      await _orchestrator.start();
      return _orchestrator.monitor();
    });
  }

  @override
  Future<Result<PipelineMonitorSnapshot>> stopPipeline() {
    return _guard(() async {
      await _orchestrator.stop();
      return _orchestrator.monitor();
    });
  }

  @override
  Future<Result<PipelineMonitorSnapshot>> pausePipeline() {
    return _guard(() async {
      await _orchestrator.pause();
      return _orchestrator.monitor();
    });
  }

  @override
  Future<Result<PipelineMonitorSnapshot>> resumePipeline() {
    return _guard(() async {
      await _orchestrator.resume();
      return _orchestrator.monitor();
    });
  }

  @override
  Future<Result<PipelineMonitorSnapshot>> restartPipeline() {
    return _guard(() async {
      await _orchestrator.restart();
      return _orchestrator.monitor();
    });
  }

  @override
  Future<Result<void>> registerStage(PipelineStage stage) {
    return _guard(() async {
      _orchestrator.registerStage(stage);
    });
  }

  @override
  Future<Result<PipelineTask>> executeTask(PipelineTask task) {
    return _guard(() => _orchestrator.executeTask(task));
  }

  @override
  Future<Result<PipelineTask>> retryTask(String taskId) {
    return _guard(() => _orchestrator.retryTask(taskId));
  }

  @override
  Future<Result<void>> cancelTask(String taskId) {
    return _guard(() async {
      final ok = await _orchestrator.cancelTask(taskId);
      if (!ok) {
        throw const CacheException(message: 'Task not found or not cancellable');
      }
    });
  }

  @override
  Future<Result<PipelineMonitorSnapshot>> getMonitor() {
    return _guard(() async => _orchestrator.monitor());
  }

  @override
  Future<Result<List<PipelineTask>>> getTaskHistory() {
    return _guard(() async => _orchestrator.taskManager.history);
  }

  @override
  Future<Result<int>> recoverFailed() {
    return _guard(_orchestrator.recoverFailedStages);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    } on StateError catch (e, st) {
      _logger.warning(e.message, tag: 'Pipeline');
      return Err(_errorHandler.handle(
        CacheException(message: e.message),
        st,
      ));
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
