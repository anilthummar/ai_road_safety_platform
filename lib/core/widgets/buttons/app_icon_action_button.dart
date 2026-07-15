import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Icon-only button with a guaranteed Material touch target.
class AppIconActionButton extends StatelessWidget {
  /// Icon to render.
  final IconData icon;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Accessibility / tooltip label.
  final String tooltip;

  /// Optional icon color override.
  final Color? color;

  /// Creates an [AppIconActionButton].
  const AppIconActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.minTouchTarget,
      height: AppDimensions.minTouchTarget,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: color),
      ),
    );
  }
}
