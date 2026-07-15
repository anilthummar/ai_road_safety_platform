import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/utils/responsive.dart';
import 'package:flutter/material.dart';

/// Centers and clamps page content for tablet / desktop while keeping
/// full-bleed layouts on compact phones when [constrainWidth] is true.
class AppPageContainer extends StatelessWidget {
  /// Page body.
  final Widget child;

  /// Horizontal / vertical padding.
  final EdgeInsetsGeometry? padding;

  /// When true, clamps width to [AppDimensions.maxContentWidth].
  final bool constrainWidth;

  /// Creates an [AppPageContainer].
  const AppPageContainer({
    required this.child,
    this.padding,
    this.constrainWidth = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = Responsive.isCompact(context);
    final resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isCompact
              ? AppSpacing.pageHorizontal
              : AppSpacing.pageHorizontalWide,
          vertical: AppSpacing.pageVertical,
        );

    final content = Padding(
      padding: resolvedPadding,
      child: child,
    );

    if (!constrainWidth) {
      return content;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        child: content,
      ),
    );
  }
}
