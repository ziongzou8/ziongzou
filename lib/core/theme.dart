import 'package:flutter/material.dart';

abstract final class ToolkitColors {
  static const background = Color(0xFF0F172A);
  static const card = Color(0xFF1E293B);
  static const primary = Color(0xFF22C55E);
  static const secondary = Color(0xFF0A4A7A);
  static const muted = Color(0xFF94A3B8);
}

ThemeData buildToolkitTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ToolkitColors.primary,
    brightness: Brightness.dark,
    surface: ToolkitColors.card,
    primary: ToolkitColors.primary,
    secondary: ToolkitColors.secondary,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ToolkitColors.background,
    colorScheme: scheme,
    cardTheme: CardThemeData(
      color: ToolkitColors.card,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ToolkitColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ToolkitColors.primary, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
