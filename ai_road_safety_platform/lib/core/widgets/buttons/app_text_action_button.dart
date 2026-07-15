import 'package:flutter/material.dart';

/// Text-style tertiary action.
class AppTextActionButton extends StatelessWidget {
  /// Button label.
  final String label;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Creates an [AppTextActionButton].
  const AppTextActionButton({
    required this.label,
    this.onPressed,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return TextButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
