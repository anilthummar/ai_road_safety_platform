import 'package:flutter/material.dart';

/// Application typography tokens (Material 3 type scale).
///
/// Uses a purposeful non-default stack: Plus Jakarta Sans for UI body/labels
/// and Source Serif 4 for display emphasis. Until custom font assets are
/// bundled, Flutter falls back gracefully via [fontFamilyFallback].
class AppTextStyles {
  AppTextStyles._();

  static const String _uiFont = 'PlusJakartaSans';
  static const String _displayFont = 'SourceSerif4';

  static const List<String> _uiFallback = [
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
    'Arial',
  ];

  static const List<String> _displayFallback = [
    'Iowan Old Style',
    'Georgia',
    'Times New Roman',
    'serif',
  ];

  /// Full Material 3 [TextTheme] wired to brand fonts.
  static TextTheme get textTheme {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: _displayFont,
        fontFamilyFallback: _displayFallback,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontFamily: _displayFont,
        fontFamilyFallback: _displayFallback,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontFamily: _displayFont,
        fontFamilyFallback: _displayFallback,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontFamily: _uiFont,
        fontFamilyFallback: _uiFallback,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  /// Convenience accessors for widgets outside [Theme.of].
  static TextStyle get labelLarge => textTheme.labelLarge!;
}
