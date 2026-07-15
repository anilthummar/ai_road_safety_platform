import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/inference_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Compact HUD for delegate, latency, and skip counters.
class InferenceHudBadge extends StatelessWidget {
  /// Creates [InferenceHudBadge].
  const InferenceHudBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<InferenceBloc, InferenceState, InferenceSession?>(
      selector: (state) => state is InferenceActive ? state.session : null,
      builder: (context, session) {
        if (session == null) return const SizedBox.shrink();

        final text =
            '${session.delegate.name.toUpperCase()} · '
            '${session.averageLatencyMs.toStringAsFixed(0)} ms · '
            'ok ${session.processedFrames} / skip ${session.skippedFrames}';

        return Align(
          alignment: Alignment.bottomLeft,
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
                    text,
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
