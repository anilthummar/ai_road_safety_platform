import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/camera/domain/entities/camera_raw_frame.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/inference_config.dart';
import 'package:image/image.dart' as img;

/// Payload produced by letterbox preprocessing for YOLOv8.
class PreprocessOutput {
  /// Float32 NHWC tensor flattened \[1, H, W, 3\] normalized to 0–1.
  final Float32List input;

  /// Scale used by letterbox (for remapping boxes back to preview).
  final double gain;

  /// Pad left in pixels on the letterboxed canvas.
  final double padX;

  /// Pad top in pixels on the letterboxed canvas.
  final double padY;

  /// Source frame width.
  final int sourceWidth;

  /// Source frame height.
  final int sourceHeight;

  /// Creates [PreprocessOutput].
  const PreprocessOutput({
    required this.input,
    required this.gain,
    required this.padX,
    required this.padY,
    required this.sourceWidth,
    required this.sourceHeight,
  });
}

/// Converts camera YUV/BGRA frames into a YOLOv8 float32 input tensor.
///
/// Designed to run inside [Isolate.run] so the UI / camera callback stay free.
class YoloPreprocessor {
  /// Target model input size.
  final int inputSize;

  /// Creates a [YoloPreprocessor].
  const YoloPreprocessor({this.inputSize = InferenceConfig.inputSize});

  /// Builds a letterboxed float32 tensor from [frame].
  PreprocessOutput process(CameraRawFrame frame) {
    final rgb = _toRgbImage(frame);
    return letterbox(rgb, inputSize);
  }

  /// Letterbox-resize [source] into [size]x[size] float32 NHWC tensor.
  PreprocessOutput letterbox(img.Image source, int size) {
    final gain = math.min(size / source.width, size / source.height);
    final newW = (source.width * gain).round();
    final newH = (source.height * gain).round();
    final padX = (size - newW) / 2.0;
    final padY = (size - newH) / 2.0;

    final resized = img.copyResize(
      source,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    final canvas = img.Image(width: size, height: size, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(
      canvas,
      resized,
      dstX: padX.round(),
      dstY: padY.round(),
    );

    final input = Float32List(size * size * 3);
    var i = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final pixel = canvas.getPixel(x, y);
        input[i++] = pixel.r / 255.0;
        input[i++] = pixel.g / 255.0;
        input[i++] = pixel.b / 255.0;
      }
    }

    return PreprocessOutput(
      input: input,
      gain: gain,
      padX: padX,
      padY: padY,
      sourceWidth: source.width,
      sourceHeight: source.height,
    );
  }

  img.Image _toRgbImage(CameraRawFrame frame) {
    if (frame.format == 'bgra8888' && frame.planes.isNotEmpty) {
      return img.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: frame.planes.first.buffer,
        order: img.ChannelOrder.bgra,
      );
    }

    // Default: YUV420 (Android / iOS camera plugin).
    return _yuv420ToRgb(frame);
  }

  /// Converts YUV420 planar / semi-planar buffers to RGB.
  img.Image _yuv420ToRgb(CameraRawFrame frame) {
    final width = frame.width;
    final height = frame.height;
    final out = img.Image(width: width, height: height, numChannels: 3);

    if (frame.planes.length < 3) {
      // NV21-ish 2-plane fallback: Y + interleaved VU
      if (frame.planes.length == 2) {
        return _nv21ToRgb(frame);
      }
      return out;
    }

    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    final yRowStride = frame.bytesPerRow[0];
    final uvRowStride = frame.bytesPerRow[1];
    final uvPixelStride = _guessUvPixelStride(frame);

    for (var y = 0; y < height; y++) {
      final uvRow = uvRowStride * (y >> 1);
      for (var x = 0; x < width; x++) {
        final yp = yPlane[y * yRowStride + x] & 0xff;
        final uvIndex = uvRow + (x >> 1) * uvPixelStride;
        final up = uPlane[uvIndex.clamp(0, uPlane.length - 1)] & 0xff;
        final vp = vPlane[uvIndex.clamp(0, vPlane.length - 1)] & 0xff;
        out.setPixelRgb(x, y, _yuvToR(yp, up, vp), _yuvToG(yp, up, vp), _yuvToB(yp, up, vp));
      }
    }
    return out;
  }

  img.Image _nv21ToRgb(CameraRawFrame frame) {
    final width = frame.width;
    final height = frame.height;
    final yPlane = frame.planes[0];
    final vuPlane = frame.planes[1];
    final yRowStride = frame.bytesPerRow[0];
    final out = img.Image(width: width, height: height, numChannels: 3);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yp = yPlane[y * yRowStride + x] & 0xff;
        final uvIndex = (y >> 1) * width + (x & ~1);
        final vp = vuPlane[uvIndex.clamp(0, vuPlane.length - 1)] & 0xff;
        final up = vuPlane[(uvIndex + 1).clamp(0, vuPlane.length - 1)] & 0xff;
        out.setPixelRgb(x, y, _yuvToR(yp, up, vp), _yuvToG(yp, up, vp), _yuvToB(yp, up, vp));
      }
    }
    return out;
  }

  int _guessUvPixelStride(CameraRawFrame frame) {
    if (frame.planes.length < 2) return 1;
    final plane = frame.planes[1];
    // Heuristic: when UV is interleaved, plane length ≈ (w/2)*(h/2)*2
    final expectedPlanar = (frame.width ~/ 2) * (frame.height ~/ 2);
    if (plane.length >= expectedPlanar * 2) return 2;
    return 1;
  }

  static int _yuvToR(int y, int u, int v) {
    final r = (y + 1.370705 * (v - 128)).round();
    return r.clamp(0, 255);
  }

  static int _yuvToG(int y, int u, int v) {
    final g = (y - 0.337633 * (u - 128) - 0.698001 * (v - 128)).round();
    return g.clamp(0, 255);
  }

  static int _yuvToB(int y, int u, int v) {
    final b = (y + 1.732446 * (u - 128)).round();
    return b.clamp(0, 255);
  }
}

/// Top-level isolate entry for preprocessing (must be a library function).
PreprocessOutput preprocessCameraFrameIsolate(CameraRawFrame frame) {
  return const YoloPreprocessor().process(frame);
}
