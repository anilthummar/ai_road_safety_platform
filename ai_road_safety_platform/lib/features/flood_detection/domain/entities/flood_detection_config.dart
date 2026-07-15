import 'package:ai_road_safety_platform/core/constants/app_config.dart';

/// Configuration for the flood / road semantic segmentation pipeline.
class FloodDetectionConfig {
  FloodDetectionConfig._();

  /// Asset path for the segmentation TFLite model.
  static const String modelAssetPath = 'assets/models/flood_seg.tflite';

  /// Labels aligned with training class indices.
  static const String labelsAssetPath = 'assets/labels/flood_seg_labels.txt';

  /// Model input spatial size (must match export).
  static const int inputSize = 320;

  /// Target segmentation FPS (preview remains unsynced / non-blocking).
  static const int targetFps = 5;

  /// CPU threads for XNNPACK fallback.
  static const int cpuThreads = 4;

  /// Softmax / argmax confidence floor for mean confidence metric.
  static const double confidenceFloor = 0.15;

  /// Overlay alpha for non-background classes (0–255).
  static const int overlayAlpha = 120;

  /// Pipeline display name.
  static const String pipelineName =
      '${AppConfig.appShortName} · Flood Segmentation';
}
