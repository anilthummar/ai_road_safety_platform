import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/features/flood_detection/data/datasources/tflite_flood_segmentation_data_source.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:ai_road_safety_platform/features/flood_detection/presentation/bloc/flood_detection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Paints the latest segmentation RGBA mask over the camera preview.
class FloodSegmentationOverlay extends StatefulWidget {
  /// Creates [FloodSegmentationOverlay].
  const FloodSegmentationOverlay({super.key});

  @override
  State<FloodSegmentationOverlay> createState() =>
      _FloodSegmentationOverlayState();
}

class _FloodSegmentationOverlayState extends State<FloodSegmentationOverlay> {
  ui.Image? _image;
  int? _lastSequence;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _syncImage(FloodSegmentationResult result) async {
    if (_lastSequence == result.frameSequence) return;
    _lastSequence = result.frameSequence;

    final ds = sl<FloodSegmentationDataSource>();
    final rgba = ds.latestOverlayRgba;
    final w = ds.latestOverlayWidth;
    final h = ds.latestOverlayHeight;
    if (rgba == null || w <= 0 || h <= 0) return;

    final next = await _rgbaToImage(rgba, w, h);
    if (!mounted) {
      next.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = next;
    });
  }

  Future<ui.Image> _rgbaToImage(Uint8List rgba, int width, int height) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FloodDetectionBloc, FloodDetectionState>(
      listenWhen: (prev, next) {
        if (next is! FloodDetectionActive) return false;
        if (prev is! FloodDetectionActive) return true;
        return prev.latestResult?.frameSequence !=
            next.latestResult?.frameSequence;
      },
      listener: (context, state) {
        if (state is FloodDetectionActive && state.latestResult != null) {
          _syncImage(state.latestResult!);
        }
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _MaskPainter(image: _image),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final ui.Image? image;

  _MaskPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) return;
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
