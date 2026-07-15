import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Secondary outlined action button.
class AppSecondaryButton extends StatelessWidget {
  /// Button label.
  final String label;

  /// Tap callback; when null the button is disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Expands to parent width when true.
  final bool isExpanded;

  /// Creates an [AppSecondaryButton].
  const AppSecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isExpanded = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(label)),
            ],
          );

    final button = OutlinedButton(
      onPressed: onPressed,
      child: child,
    );

    if (!isExpanded) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: button,
    );
  }
}
