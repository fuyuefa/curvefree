import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:flutter/material.dart';

ThemeData buildCurveFreeTheme(Brightness brightness) {
  final CurvePalette palette = brightness == Brightness.dark
      ? CurvePalette.dark
      : CurvePalette.light;
  final CurvePalette inverse = brightness == Brightness.dark
      ? CurvePalette.light
      : CurvePalette.dark;
  final ColorScheme scheme = _scheme(palette, inverse, brightness);
  final CurveColors colors = CurveColors(palette);

  TextStyle style({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.35,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.cjkFallback,
    );
  }

  final TextTheme textTheme = TextTheme(
    headlineMedium: style(
      size: AppLayout.screenTitleSize,
      weight: FontWeight.w600,
      color: palette.textPrimary,
      height: 1.2,
    ),
    titleLarge: style(
      size: 17,
      weight: FontWeight.w600,
      color: palette.textPrimary,
    ),
    titleMedium: style(
      size: 16,
      weight: FontWeight.w600,
      color: palette.textPrimary,
    ),
    bodyLarge: style(
      size: 15,
      weight: FontWeight.w400,
      color: palette.textPrimary,
    ),
    bodyMedium: style(
      size: 13,
      weight: FontWeight.w400,
      color: palette.textSecondary,
    ),
    labelLarge: style(
      size: 15,
      weight: FontWeight.w600,
      color: palette.onPrimary,
    ),
    labelSmall: style(
      size: 12,
      weight: FontWeight.w400,
      color: palette.textTertiary,
    ),
  );

  final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.card),
    side: BorderSide(color: palette.border),
  );
  final RoundedRectangleBorder ctaShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.cta),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppFonts.ui,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.screen,
    canvasColor: palette.screen,
    dividerColor: palette.border,
    extensions: <ThemeExtension<dynamic>>[colors],
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    iconTheme: IconThemeData(color: palette.textSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.screen,
      foregroundColor: palette.textPrimary,
      surfaceTintColor: palette.screen,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      surfaceTintColor: palette.card,
      elevation: 0,
      shape: cardShape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.elevated,
      surfaceTintColor: palette.elevated,
      shape: cardShape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.elevated,
      surfaceTintColor: palette.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.elevated,
      contentTextStyle: style(
        size: 14,
        weight: FontWeight.w400,
        color: palette.textPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.cta),
        side: BorderSide(color: palette.border),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      space: 1,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.card,
      hintStyle: style(
        size: 14,
        weight: FontWeight.w400,
        color: palette.textTertiary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.cta),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.cta),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.cta),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        disabledBackgroundColor: palette.disabledFill,
        disabledForegroundColor: palette.disabledText,
        minimumSize: const Size(48, 48),
        textStyle: style(
          size: 16,
          weight: FontWeight.w600,
          color: palette.onPrimary,
        ),
        shape: ctaShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.borderStrong),
        minimumSize: const Size(48, 48),
        shape: ctaShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.primary,
      foregroundColor: palette.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      shape: ctaShape,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.muted,
      selectedColor: palette.primarySoft,
      disabledColor: palette.disabledFill,
      labelStyle: style(
        size: 13,
        weight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      secondaryLabelStyle: style(
        size: 13,
        weight: FontWeight.w600,
        color: palette.primary,
      ),
      side: BorderSide(color: palette.border),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return palette.success;
        }
        return palette.muted;
      }),
      checkColor: WidgetStateProperty.all(palette.onPrimary),
      side: BorderSide(color: palette.borderStrong),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
      linearTrackColor: palette.muted,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.textSecondary,
      textColor: palette.textPrimary,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.elevated,
      surfaceTintColor: palette.elevated,
    ),
  );
}

ColorScheme _scheme(
  CurvePalette palette,
  CurvePalette inverse,
  Brightness brightness,
) {
  return ColorScheme(
    brightness: brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    primaryContainer: palette.primarySoft,
    onPrimaryContainer: palette.textPrimary,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    secondaryContainer: palette.warningSoft,
    onSecondaryContainer: palette.textPrimary,
    tertiary: palette.success,
    onTertiary: palette.onPrimary,
    tertiaryContainer: palette.successSoft,
    onTertiaryContainer: palette.textPrimary,
    error: palette.error,
    onError: palette.onPrimary,
    errorContainer: palette.errorSoft,
    onErrorContainer: palette.textPrimary,
    surface: palette.card,
    onSurface: palette.textPrimary,
    surfaceDim: palette.muted,
    surfaceBright: palette.elevated,
    surfaceContainerLowest: palette.screen,
    surfaceContainerLow: palette.card,
    surfaceContainer: palette.muted,
    surfaceContainerHigh: palette.elevated,
    surfaceContainerHighest: palette.muted,
    onSurfaceVariant: palette.textSecondary,
    outline: palette.border,
    outlineVariant: palette.borderStrong,
    shadow: palette.shadow,
    scrim: palette.scrim,
    inverseSurface: inverse.screen,
    onInverseSurface: inverse.textPrimary,
    inversePrimary: inverse.primary,
    surfaceTint: palette.primary,
  );
}
