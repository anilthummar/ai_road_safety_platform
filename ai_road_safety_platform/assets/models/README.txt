# YOLOv8 TFLite model for AI Road Safety Platform
#
# Place your exported model as:
#   assets/models/yolov8n.tflite
#
# Export (Ultralytics):
#   pip install ultralytics
#   yolo export model=yolov8n.pt format=tflite imgsz=640
#   cp yolov8n_float32.tflite assets/models/yolov8n.tflite
#
# Until a real model is present, Camera · AI runs in stub mode (live preview,
# empty detections, chip: "AI · model pending").
#
# Labels must match training class order (see assets/labels/).
