/// Fixed dimension tokens for components, breakpoints, and hit targets.
class AppDimensions {
  AppDimensions._();

  // ── Breakpoints (logical pixels) ────────────────────────────────────────

  /// Max width treated as compact / phone portrait.
  static const double breakpointCompact = 600;

  /// Max width treated as medium / tablet portrait.
  static const double breakpointMedium = 840;

  /// Max width treated as expanded / tablet landscape & small desktop.
  static const double breakpointExpanded = 1200;

  /// Max content width for readable single-column layouts on desktop.
  static const double maxContentWidth = 1200;

  /// Max content width for forms and settings panels.
  static const double maxFormWidth = 560;

  // ── Touch / chrome ──────────────────────────────────────────────────────

  /// Material minimum touch target size.
  static const double minTouchTarget = 48;

  /// Default app bar height.
  static const double appBarHeight = 56;

  /// Bottom navigation bar height.
  static const double bottomNavHeight = 64;

  /// Navigation rail width when collapsed.
  static const double navRailWidth = 80;

  /// Navigation rail width when extended.
  static const double navRailExtendedWidth = 256;

  // ── Components ──────────────────────────────────────────────────────────

  /// Default button height.
  static const double buttonHeight = 48;

  /// Compact button height for dense toolbars.
  static const double buttonHeightCompact = 36;

  /// Default card border radius.
  static const double cardRadius = 16;

  /// Default chip / button border radius.
  static const double controlRadius = 12;

  /// Dialog / sheet border radius.
  static const double sheetRadius = 20;

  /// Default elevation for resting cards (M3 uses surface tint primarily).
  static const double cardElevation = 0;

  /// Stroke width for outlined controls.
  static const double outlineWidth = 1;

  /// Default icon size.
  static const double iconSize = 24;

  /// Large decorative icon size (empty / error states).
  static const double iconSizeLarge = 64;

  /// Avatar / status indicator diameter.
  static const double avatarSize = 40;

  /// Skeleton shimmer line height.
  static const double skeletonLineHeight = 12;
}
