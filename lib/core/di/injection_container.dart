import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/network/api_client.dart';
import 'package:ai_road_safety_platform/core/network/network_info.dart';
import 'package:ai_road_safety_platform/core/router/app_router.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/services/shell_branch_controller.dart';
import 'package:ai_road_safety_platform/core/theme/theme_bloc.dart';
import 'package:ai_road_safety_platform/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:ai_road_safety_platform/features/analytics/domain/usecases/analytics_usecases.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:ai_road_safety_platform/features/camera/data/repositories/camera_repository_impl.dart';
import 'package:ai_road_safety_platform/features/camera/domain/repositories/camera_repository.dart';
import 'package:ai_road_safety_platform/features/camera/domain/usecases/camera_usecases.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:ai_road_safety_platform/features/dashboard/data/datasources/driver_dashboard_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dashboard/data/datasources/fused_driver_dashboard_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dashboard/data/repositories/driver_dashboard_repository_impl.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/repositories/driver_dashboard_repository.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/usecases/driver_dashboard_usecases.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/bloc/driver_dashboard_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/di/dataset_collection_injection.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/datasources/tflite_flood_segmentation_data_source.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/datasources/tflite_inference_data_source.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/repositories/flood_detection_repository_impl.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/repositories/inference_repository_impl.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/flood_detection_repository.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/repositories/inference_repository.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/usecases/flood_detection_usecases.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/usecases/inference_usecases.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/flood_detection_bloc.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/inference_bloc.dart';
import 'package:ai_road_safety_platform/features/gps/data/datasources/gps_local_data_source.dart';
import 'package:ai_road_safety_platform/features/gps/data/repositories/gps_repository_impl.dart';
import 'package:ai_road_safety_platform/features/gps/domain/repositories/gps_repository.dart';
import 'package:ai_road_safety_platform/features/gps/domain/usecases/gps_usecases.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/bloc/gps_bloc.dart';
import 'package:ai_road_safety_platform/features/history/data/datasources/history_local_data_source.dart';
import 'package:ai_road_safety_platform/features/history/data/datasources/hive_history_local_data_source.dart';
import 'package:ai_road_safety_platform/features/history/data/models/history_record_hive.dart';
import 'package:ai_road_safety_platform/features/history/data/repositories/history_repository_impl.dart';
import 'package:ai_road_safety_platform/features/history/domain/repositories/history_repository.dart';
import 'package:ai_road_safety_platform/features/history/domain/usecases/history_usecases.dart';
import 'package:ai_road_safety_platform/features/history/presentation/bloc/history_bloc.dart';
import 'package:ai_road_safety_platform/features/imu/data/datasources/imu_local_data_source.dart';
import 'package:ai_road_safety_platform/features/imu/data/datasources/sensors_plus_imu_local_data_source.dart';
import 'package:ai_road_safety_platform/features/imu/data/repositories/imu_repository_impl.dart';
import 'package:ai_road_safety_platform/features/imu/domain/repositories/imu_repository.dart';
import 'package:ai_road_safety_platform/features/imu/domain/usecases/imu_usecases.dart';
import 'package:ai_road_safety_platform/features/imu/presentation/bloc/imu_bloc.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/datasources/fused_risk_analysis_local_data_source.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/datasources/risk_analysis_local_data_source.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/repositories/risk_analysis_repository_impl.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/default_risk_rule_engine.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/rules/risk_rules.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/repositories/risk_analysis_repository.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/usecases/risk_analysis_usecases.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/bloc/risk_analysis_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all application dependencies.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<AppLogger>(AppLogger.new);
  sl.registerLazySingleton<ShellBranchController>(ShellBranchController.new);
  sl.registerLazySingleton<ErrorHandler>(
    () => ErrorHandler(logger: sl<AppLogger>()),
  );
  sl.registerLazySingleton<NetworkInfo>(NetworkInfoImpl.new);
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(logger: sl<AppLogger>()),
  );

  sl.registerFactory<ThemeBloc>(
    () => ThemeBloc(
      prefs: sl<SharedPreferences>(),
      logger: sl<AppLogger>(),
    ),
  );

  _registerCameraFeature();
  _registerInferenceFeature();
  _registerFloodDetectionFeature();
  _registerGpsFeature();
  _registerImuFeature();
  _registerRiskAnalysisFeature();
  _registerDriverDashboardFeature();
  await _registerHistoryFeature();
  _registerAnalyticsFeature();
  await registerDatasetCollectionFeature();

  sl.registerLazySingleton<GoRouter>(createAppRouter);
}

void _registerCameraFeature() {
  sl.registerLazySingleton<CameraLocalDataSource>(
    () => CameraLocalDataSourceImpl(logger: sl<AppLogger>()),
  );

  sl.registerLazySingleton<CameraRepository>(
    () => CameraRepositoryImpl(
      dataSource: sl<CameraLocalDataSource>(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );

  sl.registerLazySingleton(() => CheckCameraPermissionUseCase(sl()));
  sl.registerLazySingleton(() => RequestCameraPermissionUseCase(sl()));
  sl.registerLazySingleton(() => OpenCameraPermissionSettingsUseCase(sl()));
  sl.registerLazySingleton(() => InitializeCameraUseCase(sl()));
  sl.registerLazySingleton(() => PauseCameraUseCase(sl()));
  sl.registerLazySingleton(() => ResumeCameraUseCase(sl()));
  sl.registerLazySingleton(() => StartFrameStreamingUseCase(sl()));
  sl.registerLazySingleton(() => StopFrameStreamingUseCase(sl()));
  sl.registerLazySingleton(() => DisposeCameraUseCase(sl()));
  sl.registerLazySingleton(() => HandleCameraOrientationUseCase(sl()));

  sl.registerFactory<CameraBloc>(
    () => CameraBloc(
      checkPermission: sl(),
      requestPermission: sl(),
      openSettings: sl(),
      initializeCamera: sl(),
      pauseCamera: sl(),
      resumeCamera: sl(),
      startStreaming: sl(),
      stopStreaming: sl(),
      disposeCamera: sl(),
      handleOrientation: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerInferenceFeature() {
  sl.registerLazySingleton<InferenceLocalDataSource>(
    () => TfliteInferenceDataSource(
      logger: sl<AppLogger>(),
      cameraRepository: sl<CameraRepository>(),
    ),
  );

  sl.registerLazySingleton<InferenceRepository>(
    () => InferenceRepositoryImpl(
      dataSource: sl<InferenceLocalDataSource>(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );

  sl.registerLazySingleton(() => InitializeInferenceUseCase(sl()));
  sl.registerLazySingleton(() => StartInferenceUseCase(sl()));
  sl.registerLazySingleton(() => StopInferenceUseCase(sl()));
  sl.registerLazySingleton(() => DisposeInferenceUseCase(sl()));
  sl.registerLazySingleton(() => DetectFrameUseCase(sl()));

  sl.registerFactory<InferenceBloc>(
    () => InferenceBloc(
      initialize: sl(),
      start: sl(),
      stop: sl(),
      dispose: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerFloodDetectionFeature() {
  sl.registerLazySingleton<FloodSegmentationDataSource>(
    () => TfliteFloodSegmentationDataSource(
      logger: sl<AppLogger>(),
      cameraRepository: sl<CameraRepository>(),
    ),
  );

  sl.registerLazySingleton<FloodDetectionRepository>(
    () => FloodDetectionRepositoryImpl(
      dataSource: sl<FloodSegmentationDataSource>(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );

  sl.registerLazySingleton(() => InitializeFloodDetectionUseCase(sl()));
  sl.registerLazySingleton(() => StartFloodDetectionUseCase(sl()));
  sl.registerLazySingleton(() => StopFloodDetectionUseCase(sl()));
  sl.registerLazySingleton(() => DisposeFloodDetectionUseCase(sl()));
  sl.registerLazySingleton(() => SegmentFloodFrameUseCase(sl()));

  sl.registerFactory<FloodDetectionBloc>(
    () => FloodDetectionBloc(
      initialize: sl(),
      start: sl(),
      stop: sl(),
      dispose: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerGpsFeature() {
  sl.registerLazySingleton<GpsLocalDataSource>(
    () => GpsLocalDataSourceImpl(logger: sl<AppLogger>()),
  );

  sl.registerLazySingleton<GpsRepository>(
    () => GpsRepositoryImpl(
      dataSource: sl<GpsLocalDataSource>(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );

  sl.registerLazySingleton(() => CheckGpsPermissionUseCase(sl()));
  sl.registerLazySingleton(() => RequestGpsPermissionUseCase(sl()));
  sl.registerLazySingleton(() => OpenGpsSettingsUseCase(sl()));
  sl.registerLazySingleton(() => OpenGpsLocationSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentLocationUseCase(sl()));
  sl.registerLazySingleton(() => StartGpsTrackingUseCase(sl()));
  sl.registerLazySingleton(() => StopGpsTrackingUseCase(sl()));
  sl.registerLazySingleton(() => DisposeGpsUseCase(sl()));

  sl.registerFactory<GpsBloc>(
    () => GpsBloc(
      checkPermission: sl(),
      requestPermission: sl(),
      openSettings: sl(),
      openLocationSettings: sl(),
      getCurrentLocation: sl(),
      startTracking: sl(),
      stopTracking: sl(),
      disposeGps: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerImuFeature() {
  sl.registerLazySingleton<ImuLocalDataSource>(
    () => SensorsPlusImuLocalDataSource(
      preferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<ImuRepository>(
    () => ImuRepositoryImpl(
      localDataSource: sl<ImuLocalDataSource>(),
      errorHandler: sl<ErrorHandler>(),
    ),
  );

  sl.registerLazySingleton(() => StartImuStreamingUseCase(sl()));
  sl.registerLazySingleton(() => StopImuStreamingUseCase(sl()));
  sl.registerLazySingleton(() => CalibrateImuUseCase(sl()));
  sl.registerLazySingleton(() => DisposeImuUseCase(sl()));

  sl.registerFactory<ImuBloc>(
    () => ImuBloc(
      startStreaming: sl(),
      stopStreaming: sl(),
      calibrate: sl(),
      disposeImu: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerRiskAnalysisFeature() {
  sl.registerLazySingleton<RiskRuleEngine>(
    () => DefaultRiskRuleEngine(rules: createDefaultRiskRules()),
  );

  sl.registerLazySingleton<RiskAnalysisLocalDataSource>(
    () => FusedRiskAnalysisLocalDataSource(
      ruleEngine: sl(),
      floodRepository: sl(),
      gpsRepository: sl(),
      imuRepository: sl(),
    ),
  );

  sl.registerLazySingleton<RiskAnalysisRepository>(
    () => RiskAnalysisRepositoryImpl(
      localDataSource: sl(),
      errorHandler: sl(),
    ),
  );

  sl.registerLazySingleton(() => EvaluateRiskUseCase(sl()));
  sl.registerLazySingleton(() => StartRiskMonitoringUseCase(sl()));
  sl.registerLazySingleton(() => StopRiskMonitoringUseCase(sl()));
  sl.registerLazySingleton(() => DisposeRiskAnalysisUseCase(sl()));

  sl.registerFactory<RiskAnalysisBloc>(
    () => RiskAnalysisBloc(
      evaluateRisk: sl(),
      startMonitoring: sl(),
      stopMonitoring: sl(),
      disposeRisk: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerDriverDashboardFeature() {
  sl.registerLazySingleton<DriverDashboardLocalDataSource>(
    () => FusedDriverDashboardLocalDataSource(
      floodRepository: sl(),
      gpsRepository: sl(),
      riskRepository: sl(),
    ),
  );

  sl.registerLazySingleton<DriverDashboardRepository>(
    () => DriverDashboardRepositoryImpl(
      localDataSource: sl(),
      errorHandler: sl(),
    ),
  );

  sl.registerLazySingleton(() => StartDriverDashboardUseCase(sl()));
  sl.registerLazySingleton(() => StopDriverDashboardUseCase(sl()));
  sl.registerLazySingleton(() => DisposeDriverDashboardUseCase(sl()));

  sl.registerFactory<DriverDashboardBloc>(
    () => DriverDashboardBloc(
      startLive: sl(),
      stopLive: sl(),
      disposeDashboard: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

Future<void> _registerHistoryFeature() async {
  final box = await openHistoryHiveBox();
  sl.registerSingleton<Box<HistoryRecordHive>>(box);

  sl.registerLazySingleton<HistoryLocalDataSource>(
    () => HiveHistoryLocalDataSource(
      box: sl<Box<HistoryRecordHive>>(),
      cameraDataSource: sl<CameraLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      localDataSource: sl(),
      errorHandler: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetHistoryRecordsUseCase(sl()));
  sl.registerLazySingleton(() => QueryHistoryRecordsUseCase(sl()));
  sl.registerLazySingleton(() => SaveHistoryRecordUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHistoryRecordUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHistoryRecordsUseCase(sl()));
  sl.registerLazySingleton(() => ClearHistoryUseCase(sl()));
  sl.registerLazySingleton(() => ExportHistoryJsonUseCase(sl()));

  sl.registerFactory<HistoryBloc>(
    () => HistoryBloc(
      getRecords: sl(),
      saveRecord: sl(),
      deleteRecord: sl(),
      deleteRecords: sl(),
      clearHistory: sl(),
      exportJson: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}

void _registerAnalyticsFeature() {
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      historyRepository: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAnalyticsReportUseCase(sl()));

  sl.registerFactory<AnalyticsBloc>(
    () => AnalyticsBloc(
      getReport: sl(),
      repository: sl(),
      logger: sl(),
    ),
  );
}
