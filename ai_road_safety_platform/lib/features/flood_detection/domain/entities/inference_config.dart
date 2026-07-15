import 'package:ai_road_safety_platform/core/constants/app_config.dart';

/// Configuration for the YOLOv8 TensorFlow Lite inference pipeline.
class InferenceConfig {
  InferenceConfig._();

  /// Asset path to the YOLOv8 TFLite model.
  static const String modelAssetPath = 'assets/models/yolov8n.tflite';

  /// Asset path for class labels (one label per line, index order).
  ///
  /// Use [hazardLabelsAssetPath] after fine-tuning on road-safety classes.
  static const String labelsAssetPath = 'assets/labels/coco_labels.txt';

  /// Research hazard taxonomy labels (swap via DI when custom model is ready).
  static const String hazardLabelsAssetPath = 'assets/labels/hazard_labels.txt';

  /// YOLOv8 input spatial size (must match export `imgsz`).
  static const int inputSize = 640;

  /// Minimum detection confidence retained after post-processing.
  static const double confidenceThreshold = 0.45;

  /// IoU threshold for Non-Maximum Suppression.
  static const double iouThreshold = 0.45;

  /// Target inference frames per second (throttles AI work — not preview).
  static const int targetInferenceFps = 6;

  /// Maximum detections drawn per frame (HUD clarity).
  static const int maxDetections = 25;

  /// Number of CPU threads when GPU / NNAPI are unavailable.
  static const int cpuThreads = 4;

  /// Product context for logs.
  static const String pipelineName =
      '${AppConfig.appShortName} · YOLOv8 TFLite';
}
