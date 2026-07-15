import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:flutter/widgets.dart';

/// Viewport size classification for responsive layouts.
enum AppWindowSize {
  /// Phone portrait (width &lt; 600).
  compact,

  /// Tablet portrait / large phone landscape (600–839).
  medium,

  /// Tablet landscape / small desktop (840–1199).
  expanded,

  /// Large desktop (≥ 1200).
  large,
}

/// Helpers for responsive breakpoints and content width clamping.
class Responsive {
  Responsive._();

  /// Resolves [AppWindowSize] from a logical [width].
  static AppWindowSize windowSizeForWidth(double width) {
    if (width < AppDimensions.breakpointCompact) {
      return AppWindowSize.compact;
    }
    if (width < AppDimensions.breakpointMedium) {
      return AppWindowSize.medium;
    }
    if (width < AppDimensions.breakpointExpanded) {
      return AppWindowSize.expanded;
    }
    return AppWindowSize.large;
  }

  /// Resolves [AppWindowSize] from [MediaQuery] of [context].
  static AppWindowSize of(BuildContext context) {
    return windowSizeForWidth(MediaQuery.sizeOf(context).width);
  }

  /// Whether the viewport is phone-sized.
  static bool isCompact(BuildContext context) =>
      of(context) == AppWindowSize.compact;

  /// Whether the viewport should use navigation rail (≥ medium).
  static bool useNavigationRail(BuildContext context) =>
      of(context) != AppWindowSize.compact;

  /// Clamps child content to [AppDimensions.maxContentWidth] when wide.
  static double contentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width.clamp(0, AppDimensions.maxContentWidth).toDouble();
  }
}
