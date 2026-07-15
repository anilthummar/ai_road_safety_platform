import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/widgets/layout/app_shell_scaffold.dart';
import 'package:ai_road_safety_platform/features/analytics/presentation/pages/analytics_page.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/pages/camera_page.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/pages/driver_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/annotation_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/dataset_collection_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/dataset_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/export_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/active_learning_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/model_deployment_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/sensor_fusion_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/experiment_tracking_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/model_benchmark_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/model_registry_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/dataset_quality_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/pipeline_dashboard_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/research_analytics_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/session_details_page.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/pages/session_explorer_page.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/pages/flood_detection_page.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/pages/gps_page.dart';
import 'package:ai_road_safety_platform/features/history/presentation/pages/history_page.dart';
import 'package:ai_road_safety_platform/features/imu/presentation/pages/imu_page.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/pages/risk_analysis_page.dart';
import 'package:ai_road_safety_platform/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates the application [GoRouter] with adaptive shell navigation.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: RouteNames.dashboard,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                name: RouteNames.dashboardName,
                builder: (context, state) => const DriverDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.history,
                name: RouteNames.historyName,
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.analytics,
                name: RouteNames.analyticsName,
                builder: (context, state) => const AnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                name: RouteNames.settingsName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.camera,
        name: RouteNames.cameraName,
        builder: (context, state) => const CameraPage(),
      ),
      GoRoute(
        path: RouteNames.floodDetection,
        name: RouteNames.floodDetectionName,
        builder: (context, state) => const FloodDetectionPage(),
      ),
      GoRoute(
        path: RouteNames.gps,
        name: RouteNames.gpsName,
        builder: (context, state) => const GpsPage(),
      ),
      GoRoute(
        path: RouteNames.imu,
        name: RouteNames.imuName,
        builder: (context, state) => const ImuPage(),
      ),
      GoRoute(
        path: RouteNames.riskAnalysis,
        name: RouteNames.riskAnalysisName,
        builder: (context, state) => const RiskAnalysisPage(),
      ),
      GoRoute(
        path: RouteNames.datasetCollection,
        name: RouteNames.datasetCollectionName,
        builder: (context, state) => const DatasetDashboardPage(),
        routes: [
          GoRoute(
            path: 'recording',
            name: RouteNames.datasetCollectionRecordingName,
            builder: (context, state) => const DatasetCollectionPage(),
          ),
          GoRoute(
            path: 'sessions',
            name: RouteNames.datasetCollectionSessionsName,
            builder: (context, state) => const SessionExplorerPage(),
          ),
          GoRoute(
            path: 'analytics',
            name: RouteNames.datasetCollectionAnalyticsName,
            builder: (context, state) => const ResearchAnalyticsPage(),
          ),
          GoRoute(
            path: 'export',
            name: RouteNames.datasetCollectionExportName,
            builder: (context, state) => const ExportDashboardPage(),
          ),
          GoRoute(
            path: 'annotate',
            name: RouteNames.datasetCollectionAnnotateName,
            builder: (context, state) {
              final sessionId = state.uri.queryParameters['sessionId'];
              return AnnotationDashboardPage(sessionId: sessionId);
            },
          ),
          GoRoute(
            path: 'pipeline',
            name: RouteNames.datasetCollectionPipelineName,
            builder: (context, state) => const PipelineDashboardPage(),
          ),
          GoRoute(
            path: 'quality',
            name: RouteNames.datasetCollectionQualityName,
            builder: (context, state) => const DatasetQualityDashboardPage(),
          ),
          GoRoute(
            path: 'models',
            name: RouteNames.datasetCollectionModelsName,
            builder: (context, state) => const ModelRegistryDashboardPage(),
          ),
          GoRoute(
            path: 'experiments',
            name: RouteNames.datasetCollectionExperimentsName,
            builder: (context, state) =>
                const ExperimentTrackingDashboardPage(),
          ),
          GoRoute(
            path: 'benchmark',
            name: RouteNames.datasetCollectionBenchmarkName,
            builder: (context, state) => const ModelBenchmarkDashboardPage(),
          ),
          GoRoute(
            path: 'active-learning',
            name: RouteNames.datasetCollectionActiveLearningName,
            builder: (context, state) => const ActiveLearningDashboardPage(),
          ),
          GoRoute(
            path: 'deploy',
            name: RouteNames.datasetCollectionDeployName,
            builder: (context, state) => const ModelDeploymentDashboardPage(),
          ),
          GoRoute(
            path: 'sensor-fusion',
            name: RouteNames.datasetCollectionSensorFusionName,
            builder: (context, state) => const SensorFusionDashboardPage(),
          ),
          GoRoute(
            path: 'session/:sessionId',
            name: RouteNames.datasetCollectionSessionName,
            builder: (context, state) {
              final id = state.pathParameters['sessionId'] ?? '';
              return SessionDetailsPage(sessionId: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppConfig.appShortName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Route not found: ${state.uri}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    },
  );
}
