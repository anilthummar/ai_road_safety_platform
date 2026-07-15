import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/services/shell_branch_controller.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:ai_road_safety_platform/features/dashboard/domain/entities/driver_dashboard_entities.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/bloc/driver_dashboard_bloc.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/flood_detection_bloc.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/history/domain/usecases/history_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Premium Material 3 driver HUD — camera, flood, risk, speed, GPS, warnings.
class DriverDashboardPage extends StatelessWidget {
  /// Creates [DriverDashboardPage].
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CameraBloc>()..add(const CameraStarted()),
        ),
        BlocProvider(create: (_) => sl<FloodDetectionBloc>()),
        BlocProvider(
          create: (_) =>
              sl<DriverDashboardBloc>()..add(const DriverDashboardStarted()),
        ),
      ],
      child: const _DriverDashboardView(),
    );
  }
}

class _DriverDashboardView extends StatefulWidget {
  const _DriverDashboardView();

  @override
  State<_DriverDashboardView> createState() => _DriverDashboardViewState();
}

class _DriverDashboardViewState extends State<_DriverDashboardView>
    with WidgetsBindingObserver {
  bool _floodBootstrapped = false;
  late final ShellBranchController _shell;
  bool _pausedForShell = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shell = sl<ShellBranchController>();
    _shell.addListener(_onShellBranchChanged);
  }

  @override
  void dispose() {
    _shell.removeListener(_onShellBranchChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onShellBranchChanged() {
    if (!mounted) return;
    final visible = _shell.isDashboardVisible;
    final camera = context.read<CameraBloc>();
    final flood = context.read<FloodDetectionBloc>();
    final dash = context.read<DriverDashboardBloc>();
    if (!visible && !_pausedForShell) {
      _pausedForShell = true;
      camera.add(const CameraPaused());
      flood.add(const FloodDetectionStreamStopped());
      dash.add(const DriverDashboardStopped());
    } else if (visible && _pausedForShell) {
      _pausedForShell = false;
      camera.add(const CameraResumed());
      flood.add(const FloodDetectionStreamStarted());
      dash.add(const DriverDashboardStarted());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final camera = context.read<CameraBloc>();
    final flood = context.read<FloodDetectionBloc>();
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        camera.add(const CameraPaused());
        flood.add(const FloodDetectionStreamStopped());
      case AppLifecycleState.resumed:
        if (_shell.isDashboardVisible && !_pausedForShell) {
          camera.add(const CameraResumed());
          flood.add(const FloodDetectionStreamStarted());
        }
    }
  }

  void _bootstrapFlood(CameraState cameraState) {
    if (_floodBootstrapped) return;
    if (cameraState is! CameraReady || cameraState.isPaused) return;
    _floodBootstrapped = true;
    context.read<FloodDetectionBloc>().add(const FloodDetectionStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appShortName),
        actions: [
          BlocSelector<DriverDashboardBloc, DriverDashboardState, bool>(
            selector: (state) =>
                state is DriverDashboardActive && state.hud.isLive,
            builder: (context, live) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Center(
                  child: StatusPill(
                    label: live ? 'Live HUD' : 'Idle',
                    active: live,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Modules',
            onSelected: (value) => context.pushNamed(value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: RouteNames.cameraName, child: Text('Camera')),
              PopupMenuItem(
                value: RouteNames.floodDetectionName,
                child: Text('Flood detection'),
              ),
              PopupMenuItem(value: RouteNames.gpsName, child: Text('GPS')),
              PopupMenuItem(value: RouteNames.imuName, child: Text('IMU')),
              PopupMenuItem(
                value: RouteNames.riskAnalysisName,
                child: Text('Risk analysis'),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<CameraBloc, CameraState>(
        listenWhen: (prev, next) =>
            next is CameraReady || next is CameraPermissionDenied,
        listener: (context, state) => _bootstrapFlood(state),
        child: BlocBuilder<DriverDashboardBloc, DriverDashboardState>(
          buildWhen: (prev, next) {
            if (prev.runtimeType != next.runtimeType) return true;
            if (prev is DriverDashboardActive &&
                next is DriverDashboardActive) {
              return prev.hud != next.hud;
            }
            return true;
          },
          builder: (context, state) {
            return switch (state) {
              DriverDashboardInitial() => const AppLoadingIndicator.page(
                  message: 'Starting driver dashboard…',
                ),
              DriverDashboardLoading(:final message) =>
                AppLoadingIndicator.page(message: message),
              DriverDashboardError(:final failure) => AppErrorView.fromFailure(
                  failure,
                  onRetry: () => context
                      .read<DriverDashboardBloc>()
                      .add(const DriverDashboardStarted()),
                ),
              DriverDashboardActive(:final hud) => AppPageContainer(
                  child: _DriverHudBody(hud: hud),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _DriverHudBody extends StatelessWidget {
  const _DriverHudBody({required this.hud});

  final DriverDashboardHud hud;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        StatusHeroBanner(hud: hud),
        const SizedBox(height: AppSpacing.md),
        const DriverCameraPanel(),
        const SizedBox(height: AppSpacing.md),
        RiskGaugeCard(
          key: const ValueKey('risk_gauge'),
          level: hud.riskLevel,
          score: hud.riskScore,
          hasAssessment: hud.hasRiskAssessment,
          delay: Duration.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        GpsStatusCard(
          key: const ValueKey('gps_card'),
          hasFix: hud.hasGpsFix,
          latitude: hud.latitude,
          longitude: hud.longitude,
          accuracyMeters: hud.gpsAccuracyMeters,
          delay: Duration.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        WarningsPanel(
          key: const ValueKey('warnings'),
          warnings: hud.warnings,
          delay: Duration.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: () => _saveToHistory(context, hud),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Save snapshot to history'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _saveToHistory(
    BuildContext context,
    DriverDashboardHud hud,
  ) async {
    final draft = HistoryRecordDraft(
      timestamp: hud.updatedAt,
      floodPercent: hud.floodCoveragePercent,
      riskLevel: hud.riskLevel,
      riskScore: hud.riskScore,
      latitude: hud.latitude,
      longitude: hud.longitude,
      speedKmh: hud.speedKmh,
      accuracyMeters: hud.gpsAccuracyMeters,
      captureImage: true,
    );
    final result = await sl<SaveHistoryRecordUseCase>()(draft);
    if (!context.mounted) return;
    result.fold(
      onOk: (record) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              record.hasImage
                  ? 'Saved to Hive with image'
                  : 'Saved to Hive (no camera frame)',
            ),
            action: SnackBarAction(
              label: 'History',
              onPressed: () => context.goNamed(RouteNames.historyName),
            ),
          ),
        );
      },
      onErr: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  }
}
