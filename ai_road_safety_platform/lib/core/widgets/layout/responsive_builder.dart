import 'package:ai_road_safety_platform/core/utils/responsive.dart';
import 'package:flutter/material.dart';

/// Rebuilds children based on [AppWindowSize] breakpoints.
///
/// Prefer this over ad-hoc MediaQuery width checks in feature screens.
class ResponsiveBuilder extends StatelessWidget {
  /// Builder invoked with the resolved window size.
  final Widget Function(BuildContext context, AppWindowSize windowSize) builder;

  /// Creates a [ResponsiveBuilder].
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Responsive.windowSizeForWidth(constraints.maxWidth);
        return builder(context, size);
      },
    );
  }
}
