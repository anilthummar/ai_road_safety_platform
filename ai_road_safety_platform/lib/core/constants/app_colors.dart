import 'package:flutter/material.dart';

/// Semantic color tokens for light and dark Material 3 palettes.
///
/// Prefer these tokens over hard-coded [Color] literals in widgets.
class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────────────────────────────────────

  /// Primary brand blue — trust, safety systems, navigation chrome.
  static const Color brandPrimary = Color(0xFF0B6E4F);

  /// Secondary teal accent for highlights and secondary actions.
  static const Color brandSecondary = Color(0xFF08A4BD);

  /// Warm amber for caution / elevated risk (not error-critical).
  static const Color brandCaution = Color(0xFFE09F3E);

  /// Strong red for critical hazard / flood alerts.
  static const Color brandHazard = Color(0xFFC1121F);

  /// Deep navy for surfaces in light mode headers.
  static const Color brandInk = Color(0xFF0D1B2A);

  // ── Light surface ───────────────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF5F7F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE8EEEC);
  static const Color lightOnBackground = Color(0xFF0D1B2A);
  static const Color lightOnSurface = Color(0xFF1B263B);
  static const Color lightOutline = Color(0xFFB7C4BE);

  // ── Dark surface ────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF0A1210);
  static const Color darkSurface = Color(0xFF13201C);
  static const Color darkSurfaceVariant = Color(0xFF1C2E28);
  static const Color darkOnBackground = Color(0xFFE8F0ED);
  static const Color darkOnSurface = Color(0xFFD5E0DB);
  static const Color darkOutline = Color(0xFF3D524A);

  // ── Semantic status ─────────────────────────────────────────────────────

  static const Color success = Color(0xFF2A9D8F);
  static const Color warning = Color(0xFFE9C46A);
  static const Color error = Color(0xFFE76F51);
  static const Color info = Color(0xFF457B9D);

  /// Risk level tints for dashboard chips (used from Phase 7+).
  static const Color riskLow = Color(0xFF2A9D8F);
  static const Color riskMedium = Color(0xFFE9C46A);
  static const Color riskHigh = Color(0xFFE76F51);
  static const Color riskCritical = Color(0xFFC1121F);
}
