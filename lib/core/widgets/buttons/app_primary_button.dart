import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Primary call-to-action button (filled Material 3).
///
/// Prefer this over ad-hoc [FilledButton] for visual consistency.
class AppPrimaryButton extends StatelessWidget {
  /// Button label.
  final String label;

  /// Tap callback; when null the button is disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Expands to parent width when true.
  final bool isExpanded;

  /// Shows an inline progress indicator and disables taps.
  final bool isLoading;

  /// Creates an [AppPrimaryButton].
  const AppPrimaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isExpanded = true,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : _Label(label: label, icon: icon);

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
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

class _Label extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Label({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    );
  }
}
