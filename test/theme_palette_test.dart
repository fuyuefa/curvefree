import 'package:curvefree/app/theme/app_theme.dart';
import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes use taro primary and ban pure surfaces', () {
    final ThemeData light = buildCurveFreeTheme(Brightness.light);
    final ThemeData dark = buildCurveFreeTheme(Brightness.dark);

    expect(light.colorScheme.primary, const Color(0xFF9B7EBD));
    expect(light.scaffoldBackgroundColor, const Color(0xFFFBF7F2));
    expect(light.colorScheme.secondary, const Color(0xFFE8C4A8));
    expect(light.colorScheme.tertiary, const Color(0xFF7B9E8E));
    expect(light.brightness, Brightness.light);
    expect(light.textTheme.bodyLarge?.fontFamily, AppFonts.ui);
    expect(dark.textTheme.titleLarge?.fontFamily, AppFonts.ui);
    expect(light.extension<CurveColors>()!.success, CurvePalette.light.success);

    expect(dark.colorScheme.primary, const Color(0xFFB8A0D4));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF17141A));
    expect(dark.colorScheme.tertiary, const Color(0xFF95B5A6));
    expect(dark.brightness, Brightness.dark);
    expect(dark.extension<CurveColors>()!.card, CurvePalette.dark.card);

    for (final ThemeData theme in <ThemeData>[light, dark]) {
      final ColorScheme scheme = theme.colorScheme;
      final List<Color> surfaces = <Color>[
        theme.scaffoldBackgroundColor,
        scheme.primary,
        scheme.onPrimary,
        scheme.primaryContainer,
        scheme.secondary,
        scheme.onSecondary,
        scheme.tertiary,
        scheme.error,
        scheme.onError,
        scheme.surface,
        scheme.onSurface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
        scheme.surfaceBright,
        scheme.surfaceDim,
        scheme.shadow,
        scheme.scrim,
      ];
      for (final Color color in surfaces) {
        expect(isBannedSurfaceColor(color), isFalse, reason: '$color');
      }
    }

    for (final Color color in <Color>[
      ...CurvePalette.light.auditColors,
      ...CurvePalette.dark.auditColors,
    ]) {
      expect(isBannedSurfaceColor(color), isFalse, reason: '$color');
    }
  });
}
