import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/material.dart';

ThemeData buildCurveFreeTheme() {
  const Color bg = Color(AppColors.bg);
  const Color surface = Color(AppColors.surface);
  const Color surfaceHigh = Color(AppColors.surfaceHigh);
  const Color text = Color(AppColors.text);
  const Color muted = Color(AppColors.textMuted);
  const Color accent = Color(AppColors.accent);

  final ColorScheme scheme = const ColorScheme.dark(
    surface: surface,
    primary: accent,
    onPrimary: bg,
    secondary: accent,
    onSecondary: bg,
    error: Color(AppColors.danger),
    onSurface: text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: surfaceHigh,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: text,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: text, height: 1.4),
      bodyMedium: TextStyle(color: muted, height: 1.4),
      labelLarge: TextStyle(color: text, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: bg,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: const BorderSide(color: surfaceHigh),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
  );
}
