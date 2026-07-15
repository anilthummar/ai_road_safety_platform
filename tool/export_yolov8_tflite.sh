#!/usr/bin/env bash
# Exports YOLOv8n to TFLite for the AI Road Safety Platform.
# Usage: ./tool/export_yolov8_tflite.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/models/yolov8n.tflite"

python3 -m pip install -q ultralytics
python3 - <<'PY'
from ultralytics import YOLO
model = YOLO("yolov8n.pt")
path = model.export(format="tflite", imgsz=640)
print(path)
PY

# Ultralytics writes beside weights; locate newest tflite and copy.
TFITE=$(ls -t "$HOME"/yolov8n*_saved_model/*.tflite 2>/dev/null | head -1 || true)
if [[ -z "${TFITE}" ]]; then
  TFITE=$(find . -name 'yolov8n*.tflite' -type f | head -1 || true)
fi
if [[ -z "${TFITE}" ]]; then
  echo "Could not locate exported .tflite — copy it manually to $OUT"
  exit 1
fi
cp "$TFITE" "$OUT"
echo "Installed model → $OUT"
