import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

/// Standard surface card used for interactive or informational containers.
///
/// Prefer this over raw [Card] so radius, padding, and ink behavior stay
/// consistent. Avoid nesting cards inside cards.
class AppCard extends StatelessWidget {
  /// Card body.
  final Widget child;

  /// Optional tap handler — enables ink splash when non-null.
  final VoidCallback? onTap;

  /// Inner padding; defaults to [AppSpacing.lg].
  final EdgeInsetsGeometry? padding;

  /// Optional border color override.
  final Color? borderColor;

  /// Creates an [AppCard].
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return Material(
      color: scheme.surface,
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        side: BorderSide(
          color: borderColor ?? scheme.outlineVariant,
          width: AppDimensions.outlineWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              child: content,
            ),
    );
  }
}
