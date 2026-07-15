import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/app_camera_preview.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/camera_controls_bar.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/camera_permission_denied_view.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/flood_detection_bloc.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/widgets/flood_segmentation_overlay.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/widgets/flood_stats_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen flood detection experience (camera + segmentation + stats).
class FloodDetectionPage extends StatelessWidget {
  /// Creates [FloodDetectionPage].
  const FloodDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CameraBloc>()..add(const CameraStarted()),
        ),
        BlocProvider(create: (_) => sl<FloodDetectionBloc>()),
      ],
      child: const _FloodDetectionView(),
    );
  }
}

class _FloodDetectionView extends StatefulWidget {
  const _FloodDetectionView();

  @override
  State<_FloodDetectionView> createState() => _FloodDetectionViewState();
}

class _FloodDetectionViewState extends State<_FloodDetectionView>
    with WidgetsBindingObserver {
  bool _bootstrapped = false;
  int? _lastOrientationDegrees;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        camera.add(const CameraResumed());
        flood.add(const FloodDetectionStreamStarted());
    }
  }

  void _bootstrap(CameraState cameraState) {
    if (_bootstrapped) return;
    if (cameraState is! CameraReady || cameraState.isPaused) return;
    _bootstrapped = true;
    context.read<FloodDetectionBloc>().add(const FloodDetectionStarted());
  }

  void _notifyOrientation(Orientation orientation) {
    final degrees = orientation == Orientation.portrait ? 0 : 90;
    if (_lastOrientationDegrees == degrees) return;
    _lastOrientationDegrees = degrees;
    context.read<CameraBloc>().add(CameraOrientationChanged(degrees));
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _notifyOrientation(orientation);
        });

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Flood Detection'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            actions: [
              BlocBuilder<FloodDetectionBloc, FloodDetectionState>(
                builder: (context, state) {
                  final running = state is FloodDetectionActive &&
                      state.session.isStreaming;
                  return IconButton(
                    tooltip: running ? 'Pause AI' : 'Resume AI',
                    icon: Icon(
                      running
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    onPressed: () {
                      final bloc = context.read<FloodDetectionBloc>();
                      if (running) {
                        bloc.add(const FloodDetectionStreamStopped());
                      } else if (state is FloodDetectionActive) {
                        bloc.add(const FloodDetectionStreamStarted());
                      } else {
                        bloc.add(const FloodDetectionStarted());
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: BlocConsumer<CameraBloc, CameraState>(
            listener: (context, state) => _bootstrap(state),
            builder: (context, cameraState) {
              return switch (cameraState) {
                CameraInitial() => const ColoredBox(
                    color: Colors.black,
                    child: AppLoadingIndicator.page(
                      message: 'Starting camera…',
                    ),
                  ),
                CameraLoading(:final message) => ColoredBox(
                    color: Colors.black,
                    child: AppLoadingIndicator.page(message: message),
                  ),
                CameraPermissionDenied(
                  :final isPermanentlyDenied,
                  :final message,
                ) =>
                  CameraPermissionDeniedView(
                    isPermanentlyDenied: isPermanentlyDenied,
                    message: message,
                  ),
                CameraError(:final failure) => AppErrorView.fromFailure(
                    failure,
                    onRetry: () => context
                        .read<CameraBloc>()
                        .add(const CameraStarted()),
                  ),
                CameraReady(:final session) => _FloodReadyBody(
                    paused: session.isPaused,
                  ),
              };
            },
          ),
        );
      },
    );
  }
}

class _FloodReadyBody extends StatelessWidget {
  final bool paused;

  const _FloodReadyBody({required this.paused});

  @override
  Widget build(BuildContext context) {
    final dataSource = sl<CameraLocalDataSource>();

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: AppCameraPreview(
            dataSource: dataSource,
            overlay: Stack(
              fit: StackFit.expand,
              children: [
                const FloodSegmentationOverlay(),
                if (paused) const CameraPausedOverlay(),
                const Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: FloodClassLegend(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: BlocBuilder<FloodDetectionBloc, FloodDetectionState>(
                        builder: (context, state) {
                          if (state is FloodDetectionLoading) {
                            return const Chip(
                              label: Text('Loading AI'),
                              avatar: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          if (state is FloodDetectionError) {
                            return Chip(
                              avatar: const Icon(Icons.error_outline, size: 16),
                              label: Text(
                                state.failure.message,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          if (state is FloodDetectionActive) {
                            final stub = state.session.delegate ==
                                    InferenceDelegateKind.unknown &&
                                state.session.labels.isNotEmpty;
                            return Chip(
                              avatar: Icon(
                                stub ? Icons.pending_outlined : Icons.water_drop,
                                size: 16,
                                color: state.latestResult?.stats.isFloodLikely ==
                                        true
                                    ? Colors.lightBlueAccent
                                    : null,
                              ),
                              label: Text(
                                stub
                                    ? (state.session.isStreaming
                                        ? 'Seg · model pending'
                                        : 'Seg paused')
                                    : (state.session.isStreaming
                                        ? 'Seg · ${state.session.delegate.name}'
                                        : 'Seg paused'),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        BlocSelector<FloodDetectionBloc, FloodDetectionState, FloodCoverageStats?>(
          selector: (state) {
            if (state is FloodDetectionActive) {
              return state.latestResult?.stats ?? const FloodCoverageStats.zero();
            }
            return null;
          },
          builder: (context, stats) {
            if (stats == null) {
              return const SizedBox(
                height: 56,
                child: AppLoadingIndicator(message: 'Waiting for segmentation…'),
              );
            }
            return FloodStatsPanel(stats: stats, compact: true);
          },
        ),
        BlocSelector<CameraBloc, CameraState, (bool, bool)>(
          selector: (state) {
            if (state is CameraReady) {
              return (state.isPaused, state.isStreaming);
            }
            return (false, false);
          },
          builder: (context, flags) {
            return CameraControlsBar(
              isPaused: flags.$1,
              isStreaming: flags.$2,
            );
          },
        ),
      ],
    );
  }
}
