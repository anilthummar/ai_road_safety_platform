/// Centralized GoRouter path and name constants.
///
/// Always reference these instead of string literals to avoid route drift.
class RouteNames {
  RouteNames._();

  // ── Path segments ───────────────────────────────────────────────────────

  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String camera = '/camera';
  static const String floodDetection = '/flood-detection';
  static const String gps = '/gps';
  static const String imu = '/imu';
  static const String riskAnalysis = '/risk-analysis';
  static const String history = '/history';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  static const String datasetCollection = '/dataset-collection';
  static const String datasetCollectionRecording =
      '/dataset-collection/recording';
  static const String datasetCollectionSessions =
      '/dataset-collection/sessions';
  static const String datasetCollectionAnalytics =
      '/dataset-collection/analytics';
  static const String datasetCollectionExport =
      '/dataset-collection/export';
  static const String datasetCollectionAnnotate =
      '/dataset-collection/annotate';
  static const String datasetCollectionPipeline =
      '/dataset-collection/pipeline';
  static const String datasetCollectionQuality =
      '/dataset-collection/quality';
  static const String datasetCollectionModels =
      '/dataset-collection/models';
  static const String datasetCollectionExperiments =
      '/dataset-collection/experiments';
  static const String datasetCollectionBenchmark =
      '/dataset-collection/benchmark';
  static const String datasetCollectionActiveLearning =
      '/dataset-collection/active-learning';
  static const String datasetCollectionDeploy =
      '/dataset-collection/deploy';
  static const String datasetCollectionSensorFusion =
      '/dataset-collection/sensor-fusion';

  /// Session details path for [sessionId].
  static String datasetCollectionSessionPath(String sessionId) =>
      '/dataset-collection/session/$sessionId';

  /// Annotation workspace optionally scoped to [sessionId].
  static String datasetCollectionAnnotatePath([String? sessionId]) =>
      sessionId == null || sessionId.isEmpty
          ? datasetCollectionAnnotate
          : '$datasetCollectionAnnotate?sessionId=$sessionId';

  // ── Named routes (GoRouter `name:`) ─────────────────────────────────────

  static const String splashName = 'splash';
  static const String dashboardName = 'dashboard';
  static const String cameraName = 'camera';
  static const String floodDetectionName = 'floodDetection';
  static const String gpsName = 'gps';
  static const String imuName = 'imu';
  static const String riskAnalysisName = 'riskAnalysis';
  static const String historyName = 'history';
  static const String analyticsName = 'analytics';
  static const String settingsName = 'settings';
  static const String datasetCollectionName = 'datasetCollection';
  static const String datasetCollectionRecordingName =
      'datasetCollectionRecording';
  static const String datasetCollectionSessionsName =
      'datasetCollectionSessions';
  static const String datasetCollectionSessionName =
      'datasetCollectionSession';
  static const String datasetCollectionAnalyticsName =
      'datasetCollectionAnalytics';
  static const String datasetCollectionExportName =
      'datasetCollectionExport';
  static const String datasetCollectionAnnotateName =
      'datasetCollectionAnnotate';
  static const String datasetCollectionPipelineName =
      'datasetCollectionPipeline';
  static const String datasetCollectionQualityName =
      'datasetCollectionQuality';
  static const String datasetCollectionModelsName =
      'datasetCollectionModels';
  static const String datasetCollectionExperimentsName =
      'datasetCollectionExperiments';
  static const String datasetCollectionBenchmarkName =
      'datasetCollectionBenchmark';
  static const String datasetCollectionActiveLearningName =
      'datasetCollectionActiveLearning';
  static const String datasetCollectionDeployName =
      'datasetCollectionDeploy';
  static const String datasetCollectionSensorFusionName =
      'datasetCollectionSensorFusion';
}
