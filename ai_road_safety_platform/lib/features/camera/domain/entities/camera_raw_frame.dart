import 'dart:typed_data';

/// Camera plane payload copied for isolate-safe preprocessing.
///
/// Bytes are owned [Uint8List] copies — safe after the camera callback returns.
class CameraRawFrame {
  /// Frame sequence from the camera pipeline.
  final int sequence;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// YUV / BGRA plane byte copies (typed for lower GC pressure).
  final List<Uint8List> planes;

  /// Bytes per row for each plane.
  final List<int> bytesPerRow;

  /// Sensor orientation degrees.
  final int rotationDegrees;

  /// Format hint: `yuv420` or `bgra8888`.
  final String format;

  /// Creates a [CameraRawFrame].
  const CameraRawFrame({
    required this.sequence,
    required this.width,
    required this.height,
    required this.planes,
    required this.bytesPerRow,
    required this.rotationDegrees,
    required this.format,
  });
}
