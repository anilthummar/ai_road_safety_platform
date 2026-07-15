# Flood / road semantic segmentation TFLite model
#
# Expected classes (index order — see assets/labels/flood_seg_labels.txt):
#   0 background
#   1 road
#   2 water
#   3 vehicle
#   4 obstacle
#
# Place your exported model as:
#   assets/models/flood_seg.tflite
#
# Recommended export (example with a DeepLab / SegFormer / YOLO-seg pipeline):
#   - Input:  float32 NHWC [1, 320, 320, 3] normalized 0–1
#   - Output: float32 [1, 320, 320, 5] per-class logits/probabilities
#             OR int32/uint8 [1, 320, 320] class-index map
#
# Until a real research model is ready, a tiny Conv2D placeholder may be present:
#   assets/models/flood_seg.tflite  (320×320×3 → 320×320×5 logits, class-0 background)
# Replace it with your trained export to enable real flood segmentation.
# If the file is missing, the app falls back to stub mode (empty masks, camera stays live).
# GPU/NNAPI may be skipped on some devices; CPU (XNNPACK) is a normal fallback.
