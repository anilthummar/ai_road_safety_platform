import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/frame_capture_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Capture engine status card (Phase 12.3 — no disk save).
class CaptureStatusCard extends StatelessWidget {
  /// Creates [CaptureStatusCard].
  const CaptureStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FrameCaptureBloc, FrameCaptureState>(
      buildWhen: (p, n) =>
          n is FrameCaptureInitial ||
          n is FrameCaptureCapturing ||
          n is FrameCapturePaused ||
          n is FrameCaptureStopped ||
          n is FrameCaptureError,
      builder: (context, state) {
        final (label, color) = switch (state) {
          FrameCaptureCapturing() => ('Capturing', Colors.redAccent),
          FrameCapturePaused() => ('Paused', Colors.orange),
          FrameCaptureStopped() => ('Stopped', Colors.blueGrey),
          FrameCaptureError() => ('Error', Theme.of(context).colorScheme.error),
          _ => ('Idle', Theme.of(context).colorScheme.outline),
        };
        final sessionId = switch (state) {
          FrameCaptureCapturing(:final sessionId) => sessionId,
          FrameCapturePaused(:final sessionId) => sessionId,
          _ => null,
        };
        return AppSectionCard(
          title: 'Frame acquisition',
          subtitle: 'Memory queue only — images are not saved yet',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          children: [
            Text(
              sessionId == null
                  ? 'Start a recording session to begin acquiring frames.'
                  : 'Session: $sessionId',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

/// Queue fill + counters.
class QueueStatusWidget extends StatelessWidget {
  /// Creates [QueueStatusWidget].
  const QueueStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FrameCaptureBloc, FrameCaptureState>(
      builder: (context, state) {
        final queue = _queueOf(state);
        return AppSectionCard(
          title: 'Frame queue',
          subtitle: 'FIFO · max ${queue.maxSize}',
          children: [
            LinearProgressIndicator(value: queue.fillRatio),
            const SizedBox(height: AppSpacing.sm),
            QueueSizeIndicator(size: queue.size, maxSize: queue.maxSize),
            const SizedBox(height: AppSpacing.sm),
            FrameCounter(
              captured: queue.capturedCount,
              dropped: queue.droppedCount,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context
                    .read<FrameCaptureBloc>()
                    .add(const FrameCaptureClearQueue()),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear queue'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Capture rate readout.
class CaptureRateWidget extends StatelessWidget {
  /// Creates [CaptureRateWidget].
  const CaptureRateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FrameCaptureBloc, FrameCaptureState>(
      builder: (context, state) {
        final fps = _queueOf(state).captureRateFps;
        return AppCard(
          child: Row(
            children: [
              const Icon(Icons.speed),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capture rate',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      '${fps.toStringAsFixed(2)} FPS (target ~1.0)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Captured / dropped counters.
class FrameCounter extends StatelessWidget {
  /// Admitted frames.
  final int captured;

  /// Dropped frames.
  final int dropped;

  /// Creates [FrameCounter].
  const FrameCounter({
    required this.captured,
    required this.dropped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _chip(context, 'Captured', '$captured')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _chip(context, 'Dropped', '$dropped')),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Queue size indicator text.
class QueueSizeIndicator extends StatelessWidget {
  /// Current size.
  final int size;

  /// Max size.
  final int maxSize;

  /// Creates [QueueSizeIndicator].
  const QueueSizeIndicator({
    required this.size,
    required this.maxSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Queue size: $size / $maxSize',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Manual capture control.
class ManualCaptureButton extends StatelessWidget {
  /// Whether the button is enabled.
  final bool enabled;

  /// Creates [ManualCaptureButton].
  const ManualCaptureButton({this.enabled = true, super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled
          ? () => context
              .read<FrameCaptureBloc>()
              .add(const FrameCaptureManualCapture())
          : null,
      icon: const Icon(Icons.camera),
      label: const Text('Manual capture'),
    );
  }
}

FrameQueueSnapshot _queueOf(FrameCaptureState state) {
  return switch (state) {
    FrameCaptureCapturing(:final queue) => queue,
    FrameCapturePaused(:final queue) => queue,
    FrameCaptureStopped(:final queue) => queue,
    FrameCaptureFrameCaptured(:final queue) => queue,
    FrameCaptureQueueUpdatedState(:final snapshot) => snapshot,
    _ => const FrameQueueSnapshot.empty(),
  };
}
