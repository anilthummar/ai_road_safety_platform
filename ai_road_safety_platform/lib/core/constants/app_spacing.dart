/// Spacing scale based on a 4dp grid for consistent vertical/horizontal rhythm.
///
/// Use these constants instead of magic numbers in padding / gaps.
class AppSpacing {
  AppSpacing._();

  /// 0 dp
  static const double none = 0;

  /// 2 dp — hairline insets
  static const double xxs = 2;

  /// 4 dp
  static const double xs = 4;

  /// 8 dp
  static const double sm = 8;

  /// 12 dp
  static const double md = 12;

  /// 16 dp — default screen padding unit
  static const double lg = 16;

  /// 24 dp
  static const double xl = 24;

  /// 32 dp
  static const double xxl = 32;

  /// 48 dp — section separators
  static const double xxxl = 48;

  /// 64 dp — hero / empty-state vertical breathing room
  static const double huge = 64;

  /// Standard horizontal page inset for phone layouts.
  static const double pageHorizontal = lg;

  /// Standard vertical page inset for phone layouts.
  static const double pageVertical = lg;

  /// Comfortable horizontal inset for tablet / desktop content columns.
  static const double pageHorizontalWide = xxl;
}
