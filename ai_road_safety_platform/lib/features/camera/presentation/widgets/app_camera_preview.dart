import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Reusable live camera preview backed by [CameraLocalDataSource.activeController].
///
/// Keeps preview logic out of feature pages so flood-detection (later) can
/// embed the same widget. Handles aspect ratio and letterboxing.
class AppCameraPreview extends StatelessWidget {
  /// Data source that owns the [CameraController].
  final CameraLocalDataSource dataSource;

  /// Optional overlay drawn above the preview (HUD, guides).
  final Widget? overlay;

  /// Box fit for the preview surface.
  final BoxFit fit;

  /// Creates an [AppCameraPreview].
  const AppCameraPreview({
    required this.dataSource,
    this.overlay,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = dataSource.activeController;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Preview unavailable',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _FittedPreview(
                controller: controller,
                fit: fit,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              ?overlay,
            ],
          );
        },
      ),
    );
  }
}

class _FittedPreview extends StatelessWidget {
  final CameraController controller;
  final BoxFit fit;
  final double maxWidth;
  final double maxHeight;

  const _FittedPreview({
    required this.controller,
    required this.fit,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    // previewSize is in landscape sensor coordinates; swap for portrait UI.
    final previewAspect = previewSize.height / previewSize.width;

    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: FittedBox(
        fit: fit,
        child: SizedBox(
          width: maxHeight * previewAspect,
          height: maxHeight,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// Compact paused overlay for [AppCameraPreview].
class CameraPausedOverlay extends StatelessWidget {
  /// Creates [CameraPausedOverlay].
  const CameraPausedOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline, size: 56, color: Colors.white),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Camera paused',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
