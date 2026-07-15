import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_entities.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom control strip for pause / resume / stream toggles.
class CameraControlsBar extends StatelessWidget {
  /// Whether preview is paused.
  final bool isPaused;

  /// Whether frame streaming is active.
  final bool isStreaming;

  /// Creates [CameraControlsBar].
  const CameraControlsBar({
    required this.isPaused,
    required this.isStreaming,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: isPaused ? 'Resume' : 'Pause',
                  icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  onPressed: () {
                    final bloc = context.read<CameraBloc>();
                    if (isPaused) {
                      bloc.add(const CameraResumed());
                    } else {
                      bloc.add(const CameraPaused());
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppPrimaryButton(
                  label: isStreaming ? 'Stop stream' : 'Start stream',
                  icon: isStreaming
                      ? Icons.stop_circle_outlined
                      : Icons.stream_rounded,
                  onPressed: isPaused
                      ? null
                      : () {
                          final bloc = context.read<CameraBloc>();
                          if (isStreaming) {
                            bloc.add(const CameraFrameStreamingStopped());
                          } else {
                            bloc.add(const CameraFrameStreamingStarted());
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight HUD that listens to frame metadata without Bloc rebuilds.
class CameraFrameStatsBadge extends StatelessWidget {
  /// Frame metadata stream from [CameraBloc.frameStream].
  final Stream<CameraFrameMeta> frameStream;

  /// Creates [CameraFrameStatsBadge].
  const CameraFrameStatsBadge({
    required this.frameStream,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraFrameMeta>(
      stream: frameStream,
      builder: (context, snapshot) {
        final frame = snapshot.data;
        final label = frame == null
            ? 'Stream idle'
            : 'Frame #${frame.sequence} · ${frame.width}×${frame.height}';

        return Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
