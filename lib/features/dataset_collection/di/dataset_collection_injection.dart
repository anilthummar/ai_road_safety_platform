import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/active_learning_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_deployment_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/sensor_fusion_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/experiment_tracking_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_benchmark_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_registry_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_quality_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/annotation_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_collection_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/frame_capture_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/hive_dataset_collection_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/memory_frame_capture_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/memory_metadata_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/metadata_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_storage_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_storage_local_data_source_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/models/dataset_session_hive.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_export_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/active_learning_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/model_deployment_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/sensor_fusion_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/experiment_tracking_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/model_benchmark_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/model_registry_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_quality_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/pipeline_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/annotation_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_analytics_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_collection_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_explorer_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_export_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/dataset_storage_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/frame_capture_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/repositories/metadata_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/dataset_file_manager_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/dataset_storage_cache.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/sensor_snapshot_provider_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/services/storage_manager_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/active_learning_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_deployment_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/sensor_fusion_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/experiment_tracking_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_benchmark_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_quality_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/pipeline_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_analytics_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_explorer_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_export_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/metadata_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/active_learning_engine.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_deployment_engine.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/sensor_fusion_engine.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/experiment_tracking_validator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_benchmark_engine.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_registry_validator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_quality_assessment_engine.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_task_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/background_worker.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_orchestrator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/pipeline_stages.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/annotation_geometry.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_analytics_calculator.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_export_factory.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_document_generators.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/frame_background_processor.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/metadata_synchronizer_impl.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/session_timer_service.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/active_learning_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_deployment_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/sensor_fusion_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/experiment_tracking_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_benchmark_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/model_registry_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_quality_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/pipeline_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/annotation_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_analytics_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_collection_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_explorer_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_export_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_storage_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/frame_capture_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/metadata_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/active_learning_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_deployment_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/sensor_fusion_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/experiment_tracking_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_benchmark_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_registry_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_quality_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/pipeline_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_analytics_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_collection_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_explorer_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_export_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_storage_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/frame_capture_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/metadata_bloc.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers Dataset Collection dependency graph into GetIt (Phases 12.1–13.7).
Future<void> registerDatasetCollectionFeature() async {
  final box = await openDatasetSessionsHiveBox();
  sl.registerSingleton<Box<DatasetSessionHive>>(box);

  sl.registerLazySingleton<DatasetCollectionLocalDataSource>(
    () => HiveDatasetCollectionLocalDataSource(
      box: sl<Box<DatasetSessionHive>>(),
      preferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<DatasetCollectionRepository>(
    () => DatasetCollectionRepositoryImpl(
      localDataSource: sl(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );

  // Timer is per-bloc instance (factory) so dispose stays isolated.
  sl.registerFactory<SessionTimerService>(SessionTimerServiceImpl.new);

  sl.registerLazySingleton(() => CreateDatasetSessionUseCase(sl()));
  sl.registerLazySingleton(() => StartRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => PauseRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => ResumeRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => StopRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => CancelRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => CompleteRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => RenameDatasetSessionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDatasetSessionUseCase(sl()));
  sl.registerLazySingleton(() => GetDatasetSessionsUseCase(sl()));
  sl.registerLazySingleton(() => GetDatasetSessionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDatasetSessionUseCase(sl()));
  sl.registerLazySingleton(() => LoadCurrentRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => GetDatasetStatisticsUseCase(sl()));
  sl.registerLazySingleton(() => GetStorageInformationUseCase(sl()));

  // --- Phase 12.3 Frame acquisition engine ---
  sl.registerLazySingleton<FrameCaptureConfig>(
    () => const FrameCaptureConfig(),
  );
  sl.registerLazySingleton<FrameBackgroundProcessor>(
    FrameBackgroundProcessorImpl.new,
  );
  sl.registerLazySingleton<FrameCaptureLocalDataSource>(
    () => MemoryFrameCaptureLocalDataSource(
      maxQueueSize: sl<FrameCaptureConfig>().maxQueueSize,
    ),
  );
  sl.registerLazySingleton<FrameCaptureRepository>(
    () => FrameCaptureRepositoryImpl(
      cameraRepository: sl<CameraRepository>(),
      localDataSource: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
      backgroundProcessor: sl(),
      config: sl(),
    ),
  );
  sl.registerLazySingleton(() => StartFrameCaptureUseCase(sl()));
  sl.registerLazySingleton(() => StopFrameCaptureUseCase(sl()));
  sl.registerLazySingleton(() => PauseFrameCaptureUseCase(sl()));
  sl.registerLazySingleton(() => ResumeFrameCaptureUseCase(sl()));
  sl.registerLazySingleton(() => CaptureSingleFrameUseCase(sl()));
  sl.registerLazySingleton(() => EnqueueFrameUseCase(sl()));
  sl.registerLazySingleton(() => DequeueFrameUseCase(sl()));
  sl.registerLazySingleton(() => ClearFrameQueueUseCase(sl()));

  // --- Phase 12.4 Metadata synchronization ---
  sl.registerLazySingleton<SensorSnapshotProvider>(
    () => SensorSnapshotProviderImpl(
      gpsRepository: sl(),
      imuRepository: sl(),
      floodRepository: sl(),
      riskRepository: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<MetadataSynchronizer>(
    () => MetadataSynchronizerImpl(
      sensors: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<MetadataLocalDataSource>(
    MemoryMetadataLocalDataSource.new,
  );
  sl.registerLazySingleton<MetadataRepository>(
    () => MetadataRepositoryImpl(
      localDataSource: sl(),
      synchronizer: sl(),
      sensors: sl(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );
  sl.registerLazySingleton(() => GenerateFrameMetadataUseCase(sl()));
  sl.registerLazySingleton(() => SynchronizeMetadataUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentMetadataUseCase(sl()));
  sl.registerLazySingleton(() => ClearMetadataUseCase(sl()));

  // --- Phase 12.5 Local dataset storage ---
  sl.registerLazySingleton<DatasetStorageCache>(DatasetStorageCache.new);
  sl.registerLazySingleton<DatasetFileManager>(
    () => DatasetFileManagerImpl(logger: sl<AppLogger>()),
  );
  sl.registerLazySingleton<StorageManager>(
    () => StorageManagerImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<StorageBackgroundProcessor>(
    StorageBackgroundProcessorImpl.new,
  );
  sl.registerLazySingleton<DatasetStorageLocalDataSource>(
    () => DatasetStorageLocalDataSourceImpl(
      fileManager: sl(),
      storageManager: sl(),
      backgroundProcessor: sl(),
      cache: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<DatasetStorageRepository>(
    () => DatasetStorageRepositoryImpl(
      localDataSource: sl(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );
  sl.registerLazySingleton(() => SaveCapturedImageUseCase(sl()));
  sl.registerLazySingleton(() => SaveFrameMetadataUseCase(sl()));
  sl.registerLazySingleton(() => LoadCapturedImageUseCase(sl()));
  sl.registerLazySingleton(() => LoadFrameMetadataUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDatasetSessionStorageUseCase(sl()));
  sl.registerLazySingleton(() => CalculateStorageUsageUseCase(sl()));
  sl.registerLazySingleton(() => RecoverRecordingSessionUseCase(sl()));
  sl.registerLazySingleton(() => CleanupCacheUseCase(sl()));
  sl.registerLazySingleton(() => CleanupTemporaryFilesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteStoredImageUseCase(sl()));

  // --- Phase 12.6 Dataset dashboard & session explorer ---
  sl.registerLazySingleton<DatasetExplorerRepository>(
    () => DatasetExplorerRepositoryImpl(
      collectionRepository: sl(),
      storageRepository: sl(),
      fileManager: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadDashboardUseCase(sl()));
  sl.registerLazySingleton(() => LoadExplorerSessionsUseCase(sl()));
  sl.registerLazySingleton(() => SearchSessionsUseCase(sl()));
  sl.registerLazySingleton(() => FilterSessionsUseCase(sl()));
  sl.registerLazySingleton(() => SortSessionsUseCase(sl()));
  sl.registerLazySingleton(() => LoadSessionDetailsUseCase(sl()));
  sl.registerLazySingleton(() => LoadPreviewImagesUseCase(sl()));
  sl.registerLazySingleton(() => RenameExplorerSessionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExplorerSessionUseCase(sl()));
  sl.registerLazySingleton(() => DuplicateExplorerSessionUseCase(sl()));

  // --- Phase 12.7 Research analytics & dataset intelligence ---
  sl.registerLazySingleton<DatasetAnalyticsCalculator>(
    () => const DatasetAnalyticsCalculator(),
  );
  sl.registerLazySingleton<DatasetAnalyticsRepository>(
    () => DatasetAnalyticsRepositoryImpl(
      collectionRepository: sl(),
      storageRepository: sl(),
      fileManager: sl(),
      calculator: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => LoadResearchInsightsUseCase(sl()));
  sl.registerLazySingleton(() => LoadStorageAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => LoadSessionAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => LoadLocationAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => LoadInferenceAnalyticsUseCase(sl()));

  // --- Phase 12.8 Research dataset export & interoperability ---
  sl.registerLazySingleton(() => const ExportManifestGenerator());
  sl.registerLazySingleton(() => const ExportReadmeGenerator());
  sl.registerLazySingleton<DatasetExportFactory>(
    () => DatasetExportFactory(paths: () => sl<DatasetFileManager>().paths),
  );
  sl.registerLazySingleton<DatasetExportLocalDataSource>(
    () => DatasetExportLocalDataSourceImpl(
      fileManager: sl(),
      backgroundProcessor: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<DatasetExportRepository>(
    () => DatasetExportRepositoryImpl(
      collectionRepository: sl(),
      storageRepository: sl(),
      fileManager: sl(),
      localDataSource: sl(),
      factory: sl(),
      manifestGenerator: sl(),
      readmeGenerator: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => ExportDatasetUseCase(sl()));
  sl.registerLazySingleton(() => ExportSessionUseCase(sl()));
  sl.registerLazySingleton(() => GenerateManifestUseCase(sl()));
  sl.registerLazySingleton(() => GenerateReadmeUseCase(sl()));
  sl.registerLazySingleton(() => CompressDatasetUseCase(sl()));
  sl.registerLazySingleton(() => ValidateExportUseCase(sl()));

  // --- Phase 12.9 Annotation & ground truth ---
  sl.registerLazySingleton<AnnotationGeometryFactory>(
    AnnotationGeometryFactory.new,
  );
  sl.registerLazySingleton<AnnotationValidator>(
    () => AnnotationValidator(sl()),
  );
  sl.registerLazySingleton<AnnotationLocalDataSource>(
    () => AnnotationLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<LabelRepository>(
    () => LabelRepositoryImpl(
      localDataSource: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<AnnotationRepository>(
    () => AnnotationRepositoryImpl(
      localDataSource: sl(),
      fileManager: sl(),
      validator: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => CreateAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => UndoAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => RedoAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => ApproveAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => RejectAnnotationUseCase(sl()));
  sl.registerLazySingleton(() => LoadGroundTruthUseCase(sl()));

  // --- Phase 12.10 Pipeline orchestration & edge computing ---
  sl.registerLazySingleton<PipelineStageFactory>(
    () => PipelineStageFactory(logger: sl<AppLogger>()),
  );
  sl.registerLazySingleton<WorkerPool>(
    () => WorkerPool(size: 2, logger: sl<AppLogger>()),
  );
  sl.registerLazySingleton<TaskDispatcher>(
    () => TaskDispatcher(pool: sl(), logger: sl<AppLogger>()),
  );
  sl.registerLazySingleton<BackgroundTaskManager>(
    () => BackgroundTaskManager(
      dispatcher: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<PipelineOrchestrator>(
    () {
      final orch = PipelineOrchestrator(
        taskManager: sl(),
        logger: sl<AppLogger>(),
      );
      orch.registerAll(sl<PipelineStageFactory>().createDefaultChain());
      return orch;
    },
  );
  sl.registerLazySingleton<PipelineRepository>(
    () => PipelineRepositoryImpl(
      orchestrator: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => StartPipelineUseCase(sl()));
  sl.registerLazySingleton(() => PausePipelineUseCase(sl()));
  sl.registerLazySingleton(() => ResumePipelineUseCase(sl()));
  sl.registerLazySingleton(() => StopPipelineUseCase(sl()));
  sl.registerLazySingleton(() => ExecutePipelineTaskUseCase(sl()));
  sl.registerLazySingleton(() => RetryTaskUseCase(sl()));
  sl.registerLazySingleton(() => CancelTaskUseCase(sl()));
  sl.registerLazySingleton(() => GetPipelineMonitorUseCase(sl()));

  // --- Phase 13.1 Dataset quality assessment & training gate ---
  sl.registerLazySingleton<DatasetQualityAssessmentEngine>(
    () => const DatasetQualityAssessmentEngine(),
  );
  sl.registerLazySingleton<DatasetQualityLocalDataSource>(
    () => DatasetQualityLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<DatasetQualityRepository>(
    () => DatasetQualityRepositoryImpl(
      collectionRepository: sl(),
      storageRepository: sl(),
      analyticsRepository: sl(),
      annotationRepository: sl(),
      labelRepository: sl(),
      engine: sl(),
      localDataSource: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => AssessDatasetQualityUseCase(sl()));
  sl.registerLazySingleton(() => EvaluateQualityGateUseCase(sl()));
  sl.registerLazySingleton(() => LoadLastQualityReportUseCase(sl()));
  sl.registerLazySingleton(() => UpdateQualityThresholdsUseCase(sl()));
  sl.registerLazySingleton(() => GetQualityThresholdsUseCase(sl()));

  // --- Phase 13.2 AI model management (versions / artifacts / metadata) ---
  sl.registerLazySingleton<ModelRegistryValidator>(
    () => const ModelRegistryValidator(),
  );
  sl.registerLazySingleton<ModelRegistryLocalDataSource>(
    () => ModelRegistryLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<ModelRegistryRepository>(
    () => ModelRegistryRepositoryImpl(
      localDataSource: sl(),
      validator: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadModelRegistryUseCase(sl()));
  sl.registerLazySingleton(() => RegisterModelUseCase(sl()));
  sl.registerLazySingleton(() => UpdateModelUseCase(sl()));
  sl.registerLazySingleton(() => DeleteModelUseCase(sl()));
  sl.registerLazySingleton(() => ActivateModelUseCase(sl()));
  sl.registerLazySingleton(() => ArchiveModelUseCase(sl()));
  sl.registerLazySingleton(() => ImportLocalModelUseCase(sl()));
  sl.registerLazySingleton(() => SeedBundledModelsUseCase(sl()));

  // --- Phase 13.3 Experiment tracking (runs / params / metrics) ---
  sl.registerLazySingleton<ExperimentTrackingValidator>(
    () => const ExperimentTrackingValidator(),
  );
  sl.registerLazySingleton<ExperimentTrackingLocalDataSource>(
    () => ExperimentTrackingLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<ExperimentTrackingRepository>(
    () => ExperimentTrackingRepositoryImpl(
      localDataSource: sl(),
      validator: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadExperimentTrackerUseCase(sl()));
  sl.registerLazySingleton(() => CreateExperimentRunUseCase(sl()));
  sl.registerLazySingleton(() => StartExperimentRunUseCase(sl()));
  sl.registerLazySingleton(() => LogExperimentParamsUseCase(sl()));
  sl.registerLazySingleton(() => LogExperimentMetricUseCase(sl()));
  sl.registerLazySingleton(() => CompleteExperimentRunUseCase(sl()));
  sl.registerLazySingleton(() => FailExperimentRunUseCase(sl()));
  sl.registerLazySingleton(() => CancelExperimentRunUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExperimentRunUseCase(sl()));
  sl.registerLazySingleton(() => CreateDemoExperimentRunUseCase(sl()));

  // --- Phase 13.4 Model benchmark (offline scoring vs GT) ---
  sl.registerLazySingleton<ModelBenchmarkEngine>(
    () => const ModelBenchmarkEngine(),
  );
  sl.registerLazySingleton<ModelBenchmarkLocalDataSource>(
    () => ModelBenchmarkLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<ModelBenchmarkRepository>(
    () => ModelBenchmarkRepositoryImpl(
      localDataSource: sl(),
      engine: sl(),
      annotationRepository: sl(),
      collectionRepository: sl(),
      modelRegistryRepository: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadBenchmarkSnapshotUseCase(sl()));
  sl.registerLazySingleton(() => RunBenchmarkUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBenchmarkReportUseCase(sl()));
  sl.registerLazySingleton(() => CreateDemoBenchmarkUseCase(sl()));

  // --- Phase 13.5 Active learning (smart sample selection) ---
  sl.registerLazySingleton<ActiveLearningEngine>(
    () => const ActiveLearningEngine(),
  );
  sl.registerLazySingleton<ActiveLearningLocalDataSource>(
    () => ActiveLearningLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<ActiveLearningRepository>(
    () => ActiveLearningRepositoryImpl(
      localDataSource: sl(),
      engine: sl(),
      annotationRepository: sl(),
      collectionRepository: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadActiveLearningSnapshotUseCase(sl()));
  sl.registerLazySingleton(() => RunActiveLearningSelectionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteActiveLearningSelectionUseCase(sl()));
  sl.registerLazySingleton(() => CreateDemoActiveLearningUseCase(sl()));

  // --- Phase 13.6 Model deployment (edge package / rollback) ---
  sl.registerLazySingleton<ModelDeploymentEngine>(
    () => const ModelDeploymentEngine(),
  );
  sl.registerLazySingleton<ModelDeploymentLocalDataSource>(
    () => ModelDeploymentLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<ModelDeploymentRepository>(
    () => ModelDeploymentRepositoryImpl(
      localDataSource: sl(),
      engine: sl(),
      modelRegistryRepository: sl(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadDeploymentSnapshotUseCase(sl()));
  sl.registerLazySingleton(() => StageDeploymentUseCase(sl()));
  sl.registerLazySingleton(() => ActivateDeploymentUseCase(sl()));
  sl.registerLazySingleton(() => RollbackDeploymentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDeploymentUseCase(sl()));
  sl.registerLazySingleton(() => ResolveDeployedModelUseCase(sl()));
  sl.registerLazySingleton(() => CreateDemoDeploymentUseCase(sl()));

  // --- Phase 13.7 Sensor fusion (camera + GPS + IMU, sonar later) ---
  sl.registerLazySingleton<SensorFusionEngine>(
    () => const SensorFusionEngine(),
  );
  sl.registerLazySingleton<SensorFusionLocalDataSource>(
    () => SensorFusionLocalDataSourceImpl(
      fileManager: sl(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<SensorFusionRepository>(
    () => SensorFusionRepositoryImpl(
      localDataSource: sl(),
      engine: sl(),
      gpsRepository: sl<GpsRepository>(),
      imuRepository: sl<ImuRepository>(),
      cameraRepository: sl<CameraRepository>(),
      errorHandler: sl<ErrorHandler>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton(() => LoadSensorFusionSnapshotUseCase(sl()));
  sl.registerLazySingleton(() => StartSensorFusionUseCase(sl()));
  sl.registerLazySingleton(() => StopSensorFusionUseCase(sl()));
  sl.registerLazySingleton(() => FuseSensorTickUseCase(sl()));
  sl.registerLazySingleton(() => CreateDemoFusedSampleUseCase(sl()));
  sl.registerLazySingleton(() => ClearFusionSamplesUseCase(sl()));

  sl.registerFactory<DatasetCollectionBloc>(
    () => DatasetCollectionBloc(
      createSession: sl(),
      startSession: sl(),
      pauseSession: sl(),
      resumeSession: sl(),
      stopSession: sl(),
      cancelSession: sl(),
      renameSession: sl(),
      deleteSession: sl(),
      getSessions: sl(),
      getStatistics: sl(),
      getStorage: sl(),
      loadCurrent: sl(),
      timer: sl<SessionTimerService>(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<FrameCaptureBloc>(
    () => FrameCaptureBloc(
      startCapture: sl(),
      stopCapture: sl(),
      pauseCapture: sl(),
      resumeCapture: sl(),
      captureSingleFrame: sl(),
      clearFrameQueue: sl(),
      repository: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<MetadataBloc>(
    () => MetadataBloc(
      generateFrameMetadata: sl(),
      clearMetadata: sl(),
      repository: sl(),
      frameCaptureRepository: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<DatasetStorageBloc>(
    () => DatasetStorageBloc(
      saveCapturedImage: sl(),
      saveFrameMetadata: sl(),
      loadCapturedImage: sl(),
      loadFrameMetadata: sl(),
      deleteDatasetSession: sl(),
      calculateStorageUsage: sl(),
      cleanupCache: sl(),
      cleanupTemporaryFiles: sl(),
      recoverRecordingSession: sl(),
      repository: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<DatasetExplorerBloc>(
    () => DatasetExplorerBloc(
      loadDashboard: sl(),
      searchSessions: sl(),
      loadSessionDetails: sl(),
      renameSession: sl(),
      deleteSession: sl(),
      duplicateSession: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<DatasetAnalyticsBloc>(
    () => DatasetAnalyticsBloc(
      loadAnalytics: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<DatasetExportBloc>(
    () => DatasetExportBloc(
      exportDataset: sl(),
      exportSession: sl(),
      generateManifest: sl(),
      generateReadme: sl(),
      compressDataset: sl(),
      validateExport: sl(),
      repository: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<AnnotationBloc>(
    () => AnnotationBloc(
      repository: sl(),
      labelRepository: sl(),
      createAnnotation: sl(),
      updateAnnotation: sl(),
      deleteAnnotation: sl(),
      undoAnnotation: sl(),
      redoAnnotation: sl(),
      approveAnnotation: sl(),
      rejectAnnotation: sl(),
      loadGroundTruth: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<PipelineBloc>(
    () => PipelineBloc(
      startPipeline: sl(),
      pausePipeline: sl(),
      resumePipeline: sl(),
      stopPipeline: sl(),
      executePipelineTask: sl(),
      retryTask: sl(),
      cancelTask: sl(),
      getPipelineMonitor: sl(),
      repository: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<DatasetQualityBloc>(
    () => DatasetQualityBloc(
      assessDatasetQuality: sl(),
      loadLastQualityReport: sl(),
      getQualityThresholds: sl(),
      updateQualityThresholds: sl(),
      evaluateQualityGate: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<ModelRegistryBloc>(
    () => ModelRegistryBloc(
      loadModelRegistry: sl(),
      registerModel: sl(),
      deleteModel: sl(),
      activateModel: sl(),
      archiveModel: sl(),
      seedBundledModels: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<ExperimentTrackingBloc>(
    () => ExperimentTrackingBloc(
      loadExperimentTracker: sl(),
      createExperimentRun: sl(),
      startExperimentRun: sl(),
      logExperimentMetric: sl(),
      completeExperimentRun: sl(),
      failExperimentRun: sl(),
      cancelExperimentRun: sl(),
      deleteExperimentRun: sl(),
      createDemoExperimentRun: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<ModelBenchmarkBloc>(
    () => ModelBenchmarkBloc(
      loadBenchmarkSnapshot: sl(),
      runBenchmark: sl(),
      deleteBenchmarkReport: sl(),
      createDemoBenchmark: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<ActiveLearningBloc>(
    () => ActiveLearningBloc(
      loadActiveLearningSnapshot: sl(),
      runActiveLearningSelection: sl(),
      deleteActiveLearningSelection: sl(),
      createDemoActiveLearning: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<ModelDeploymentBloc>(
    () => ModelDeploymentBloc(
      loadDeploymentSnapshot: sl(),
      stageDeployment: sl(),
      activateDeployment: sl(),
      rollbackDeployment: sl(),
      deleteDeployment: sl(),
      createDemoDeployment: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  sl.registerFactory<SensorFusionBloc>(
    () => SensorFusionBloc(
      loadSensorFusionSnapshot: sl(),
      startSensorFusion: sl(),
      stopSensorFusion: sl(),
      fuseSensorTick: sl(),
      createDemoFusedSample: sl(),
      clearFusionSamples: sl(),
      logger: sl<AppLogger>(),
    ),
  );
}
