import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:flutter/material.dart';

/// Paints YOLOv8 bounding boxes + labels over the live camera preview.
class DetectionOverlayPainter extends CustomPainter {
  /// Detections in normalized preview coordinates (0–1).
  final List<Detection> detections;

  /// Creates a [DetectionOverlayPainter].
  const DetectionOverlayPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.brandCaution;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.brandCaution.withValues(alpha: 0.15);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    for (final detection in detections) {
      final rect = Rect.fromLTRB(
        detection.box.left * size.width,
        detection.box.top * size.height,
        detection.box.right * size.width,
        detection.box.bottom * size.height,
      );

      final color = _colorFor(detection.label);
      stroke.color = color;
      fill.color = color.withValues(alpha: 0.12);

      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);

      final label =
          '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          backgroundColor: color.withValues(alpha: 0.85),
        ),
      );
      textPainter.layout(maxWidth: size.width);
      final labelOffset = Offset(
        rect.left.clamp(0, size.width - textPainter.width),
        (rect.top - textPainter.height - 2).clamp(0, size.height),
      );
      textPainter.paint(canvas, labelOffset);
    }
  }

  Color _colorFor(String label) {
    final key = label.toLowerCase();
    if (key.contains('flood') || key.contains('water')) {
      return AppColors.brandHazard;
    }
    if (key.contains('person')) return AppColors.info;
    if (key.contains('car') ||
        key.contains('truck') ||
        key.contains('bus') ||
        key.contains('vehicle')) {
      return AppColors.brandSecondary;
    }
    if (key.contains('pothole') || key.contains('hazard') || key.contains('debris')) {
      return AppColors.brandHazard;
    }
    return AppColors.brandCaution;
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}

/// Widget host for [DetectionOverlayPainter].
class DetectionOverlay extends StatelessWidget {
  /// Detections to draw.
  final List<Detection> detections;

  /// Creates a [DetectionOverlay].
  const DetectionOverlay({
    required this.detections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const SizedBox.expand();
    }
    return CustomPaint(
      size: Size.infinite,
      painter: DetectionOverlayPainter(detections: detections),
    );
  }
}
