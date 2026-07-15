#!/usr/bin/env python3
"""Export a tiny stub flood-seg TFLite matching app I/O contracts.

Input:  float32 [1, 320, 320, 3]  (NHWC, 0–1 normalized RGB)
Output: float32 [1, 320, 320, 5]  (background / road / water / vehicle / obstacle)

The stub is intentionally untrained — it biases toward "road" so the
pipeline, overlay, and risk fusion can be exercised without a research model.
Replace assets/models/flood_seg.tflite with your fine-tuned export when ready.
"""

from __future__ import annotations

import pathlib
import sys

SIZE = 320
NUM_CLASSES = 5
OUT_REL = pathlib.Path("assets/models/flood_seg.tflite")


def main() -> int:
  try:
    import tensorflow as tf
  except ImportError:
    print(
      "tensorflow is required. Example:\n"
      "  python3.11 -m pip install 'tensorflow==2.16.2'",
      file=sys.stderr,
    )
    return 1

  # DepthwiseSeparable-ish tiny CNN → upsample to full res logits.
  inputs = tf.keras.Input(shape=(SIZE, SIZE, 3), name="image")
  x = tf.keras.layers.Conv2D(8, 3, strides=2, padding="same", activation="relu")(
    inputs
  )
  x = tf.keras.layers.Conv2D(16, 3, strides=2, padding="same", activation="relu")(x)
  x = tf.keras.layers.Conv2D(NUM_CLASSES, 1, padding="same")(x)
  # Bilinear upsample back to 320×320 logits.
  logits = tf.keras.layers.UpSampling2D(size=(4, 4), interpolation="bilinear")(x)
  model = tf.keras.Model(inputs, logits, name="flood_seg_stub")

  # Bias class 1 (road) slightly so argmax isn't random noise everywhere.
  last = model.layers[-2]  # Conv2D before upsample
  weights, bias = last.get_weights()
  bias = bias * 0.0
  bias[1] = 1.5  # road
  last.set_weights([weights, bias])

  converter = tf.lite.TFLiteConverter.from_keras_model(model)
  converter.optimizations = []
  tflite_model = converter.convert()

  root = pathlib.Path(__file__).resolve().parents[1]
  out = root / OUT_REL
  out.parent.mkdir(parents=True, exist_ok=True)
  out.write_bytes(tflite_model)

  # Sanity-check shapes with the interpreter.
  interpreter = tf.lite.Interpreter(model_path=str(out))
  interpreter.allocate_tensors()
  inp = interpreter.get_input_details()[0]
  outp = interpreter.get_output_details()[0]
  print(f"Wrote {out} ({out.stat().st_size} bytes)")
  print(f"  input:  {inp['shape']} {inp['dtype']}")
  print(f"  output: {outp['shape']} {outp['dtype']}")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
