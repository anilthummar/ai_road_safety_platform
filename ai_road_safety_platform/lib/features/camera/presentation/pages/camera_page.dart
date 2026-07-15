import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/app_camera_preview.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/camera_controls_bar.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/camera_permission_denied_view.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/inference_bloc.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/widgets/detection_overlay_painter.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/widgets/inference_hud_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Camera screen with live YOLOv8 TFLite inference overlay.
class CameraPage extends StatelessWidget {
  /// Creates [CameraPage].
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CameraBloc>()..add(const CameraStarted()),
        ),
        BlocProvider(
          create: (_) => sl<InferenceBloc>(),
        ),
      ],
      child: const _CameraView(),
    );
  }
}

class _CameraView extends StatefulWidget {
  const _CameraView();

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> with WidgetsBindingObserver {
  int? _lastOrientationDegrees;
  bool _inferenceBootstrapped = false;

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
    final inference = context.read<InferenceBloc>();
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        camera.add(const CameraPaused());
        inference.add(const InferenceStreamStopped());
      case AppLifecycleState.resumed:
        camera.add(const CameraResumed());
        inference.add(const InferenceStreamStarted());
    }
  }

  void _notifyOrientationIfChanged(Orientation orientation) {
    final degrees = orientation == Orientation.portrait ? 0 : 90;
    if (_lastOrientationDegrees == degrees) return;
    _lastOrientationDegrees = degrees;
    context.read<CameraBloc>().add(CameraOrientationChanged(degrees));
  }

  void _bootstrapInferenceIfNeeded(CameraState cameraState) {
    if (_inferenceBootstrapped) return;
    if (cameraState is! CameraReady || cameraState.isPaused) return;
    _inferenceBootstrapped = true;
    context.read<InferenceBloc>().add(const InferenceStarted());
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _notifyOrientationIfChanged(orientation);
        });

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Camera · AI'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            actions: [
              BlocBuilder<InferenceBloc, InferenceState>(
                builder: (context, state) {
                  final running = state is InferenceActive &&
                      state.session.isStreaming;
                  return IconButton(
                    tooltip: running ? 'Stop AI' : 'Start AI',
                    onPressed: () {
                      final bloc = context.read<InferenceBloc>();
                      if (running) {
                        bloc.add(const InferenceStreamStopped());
                      } else if (state is InferenceActive) {
                        bloc.add(const InferenceStreamStarted());
                      } else {
                        bloc.add(const InferenceStarted());
                      }
                    },
                    icon: Icon(
                      running
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocConsumer<CameraBloc, CameraState>(
            listener: (context, state) => _bootstrapInferenceIfNeeded(state),
            builder: (context, state) {
              return switch (state) {
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
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: CameraPermissionDeniedView(
                      isPermanentlyDenied: isPermanentlyDenied,
                      message: message,
                    ),
                  ),
                CameraError(:final failure) => ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: AppErrorView.fromFailure(
                      failure,
                      onRetry: () => context
                          .read<CameraBloc>()
                          .add(const CameraStarted()),
                    ),
                  ),
                CameraReady(:final session) => _ReadyBody(
                    sessionPaused: session.isPaused,
                  ),
              };
            },
          ),
        );
      },
    );
  }
}

class _ReadyBody extends StatelessWidget {
  final bool sessionPaused;

  const _ReadyBody({required this.sessionPaused});

  @override
  Widget build(BuildContext context) {
    final dataSource = sl<CameraLocalDataSource>();
    final cameraBloc = context.read<CameraBloc>();

    return Column(
      children: [
        Expanded(
          child: AppCameraPreview(
            dataSource: dataSource,
            overlay: Stack(
              fit: StackFit.expand,
              children: [
                // Detection boxes — rebuild only when detections change.
                BlocSelector<InferenceBloc, InferenceState, List<Detection>>(
                  selector: (state) {
                    if (state is InferenceActive) {
                      return state.latestResult?.detections ?? const [];
                    }
                    return const [];
                  },
                  builder: (context, detections) {
                    return DetectionOverlay(detections: detections);
                  },
                ),
                if (sessionPaused) const CameraPausedOverlay(),
                const InferenceHudBadge(),
                CameraFrameStatsBadge(frameStream: cameraBloc.frameStream),
                Align(
                  alignment: Alignment.topRight,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          BlocSelector<CameraBloc, CameraState, bool>(
                            selector: (state) =>
                                state is CameraReady && state.isStreaming,
                            builder: (context, isStreaming) {
                              return Chip(
                                avatar: Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: isStreaming
                                      ? Colors.lightGreenAccent
                                      : Colors.grey,
                                ),
                                label: Text(
                                  isStreaming ? 'Streaming' : 'Preview',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          BlocBuilder<InferenceBloc, InferenceState>(
                            builder: (context, state) {
                              if (state is InferenceLoading) {
                                return const Chip(
                                  avatar: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  label: Text('Loading AI'),
                                );
                              }
                              if (state is InferenceError) {
                                return Chip(
                                  avatar: const Icon(Icons.error_outline, size: 16),
                                  label: Text(
                                    state.failure.message,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }
                              if (state is InferenceActive) {
                                final stub = state.session.delegate ==
                                        InferenceDelegateKind.unknown &&
                                    state.session.labels.isNotEmpty;
                                final n =
                                    state.latestResult?.detections.length ?? 0;
                                return Chip(
                                  avatar: Icon(
                                    stub
                                        ? Icons.pending_outlined
                                        : Icons.auto_awesome,
                                    size: 16,
                                  ),
                                  label: Text(
                                    stub ? 'AI · model pending' : 'Detections $n',
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
