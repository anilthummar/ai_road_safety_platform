import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';

/// Persistence / control surface for the edge pipeline.
abstract class PipelineRepository {
  Future<Result<PipelineMonitorSnapshot>> startPipeline();

  Future<Result<PipelineMonitorSnapshot>> stopPipeline();

  Future<Result<PipelineMonitorSnapshot>> pausePipeline();

  Future<Result<PipelineMonitorSnapshot>> resumePipeline();

  Future<Result<PipelineMonitorSnapshot>> restartPipeline();

  Future<Result<void>> registerStage(PipelineStage stage);

  Future<Result<PipelineTask>> executeTask(PipelineTask task);

  Future<Result<PipelineTask>> retryTask(String taskId);

  Future<Result<void>> cancelTask(String taskId);

  Future<Result<PipelineMonitorSnapshot>> getMonitor();

  Future<Result<List<PipelineTask>>> getTaskHistory();

  Future<Result<int>> recoverFailed();
}
