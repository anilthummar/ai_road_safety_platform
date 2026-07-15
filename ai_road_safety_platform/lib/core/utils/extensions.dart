import 'package:flutter/material.dart';

/// Common [BuildContext] extensions used across the UI layer.
extension BuildContextX on BuildContext {
  /// Shortcut to [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Shortcut to [ColorScheme].
  ColorScheme get colors => theme.colorScheme;

  /// Shortcut to [TextTheme].
  TextTheme get textTheme => theme.textTheme;

  /// Shortcut to [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Shows a floating Material snack bar with [message].
  void showAppSnackBar(
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : null,
        ),
      );
  }
}

/// [String] helpers for empty / null presentation.
extension StringX on String? {
  /// True when null or blank after trim.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// Returns itself or [fallback] when null/blank.
  String orDefault([String fallback = '']) =>
      isNullOrBlank ? fallback : this!;
}
