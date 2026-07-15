import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/app_camera_preview.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/widgets/camera_permission_denied_view.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/animated_dashboard_card.dart';
import 'package:ai_road_safety_platform/features/dashboard/presentation/widgets/status_pill.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/widgets/flood_segmentation_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Camera preview panel for the driver HUD with optional flood overlay.
class DriverCameraPanel extends StatelessWidget {
  /// Entrance delay.
  final Duration delay;

  /// Creates [DriverCameraPanel].
  const DriverCameraPanel({
    this.delay = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedDashboardCard(
      delay: delay,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Camera',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                BlocBuilder<CameraBloc, CameraState>(
                  buildWhen: (prev, next) {
                    if (prev.runtimeType != next.runtimeType) return true;
                    if (prev is CameraReady && next is CameraReady) {
                      return prev.isPaused != next.isPaused;
                    }
                    return true;
                  },
                  builder: (context, state) {
                    final live = state is CameraReady && !state.isPaused;
                    return StatusPill(label: live ? 'Live' : 'Idle', active: live);
                  },
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppDimensions.cardRadius),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: BlocBuilder<CameraBloc, CameraState>(
                builder: (context, cameraState) {
                  if (cameraState is CameraPermissionDenied) {
                    return CameraPermissionDeniedView(
                      isPermanentlyDenied: cameraState.isPermanentlyDenied,
                      message: cameraState.message,
                    );
                  }
                  if (cameraState is! CameraReady) {
                    return const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  }

                  return AppCameraPreview(
                    dataSource: sl<CameraLocalDataSource>(),
                    overlay: const FloodSegmentationOverlay(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
