import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Visual v3.2 「奶油香芋」. Surfaces must not be pure white or pure black.
@immutable
final class CurvePalette {
  const CurvePalette({
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.screen,
    required this.card,
    required this.muted,
    required this.elevated,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onPrimary,
    required this.onAccent,
    required this.disabledFill,
    required this.disabledText,
    required this.shadow,
    required this.scrim,
  });

  static const CurvePalette light = CurvePalette(
    primary: Color(0xFF9B7EBD),
    primarySoft: Color(0xFFF0E8F4),
    accent: Color(0xFFE8C4A8),
    success: Color(0xFF7B9E8E),
    successSoft: Color(0xFFE8F0EC),
    warning: Color(0xFFC9956A),
    warningSoft: Color(0xFFF5EBE0),
    error: Color(0xFFC97B82),
    errorSoft: Color(0xFFF5E8E9),
    screen: Color(0xFFFBF7F2),
    card: Color(0xFFFDF9F5),
    muted: Color(0xFFF2EBE3),
    elevated: Color(0xFFFCFAF6),
    border: Color(0xFFE8DFD4),
    borderStrong: Color(0xFFD4C8BA),
    textPrimary: Color(0xFF2A2428),
    textSecondary: Color(0xFF7A716C),
    textTertiary: Color(0xFFA39A94),
    onPrimary: Color(0xFFFBF7F2),
    onAccent: Color(0xFF2A2428),
    disabledFill: Color(0xFFEDE6DE),
    disabledText: Color(0xFFB8AFA8),
    shadow: Color(0xFF2A2428),
    scrim: Color(0xFF17141A),
  );

  static const CurvePalette dark = CurvePalette(
    primary: Color(0xFFB8A0D4),
    primarySoft: Color(0xFF2C2434),
    accent: Color(0xFFE8C4A8),
    success: Color(0xFF95B5A6),
    successSoft: Color(0xFF1E2A24),
    warning: Color(0xFFD4A878),
    warningSoft: Color(0xFF2E2418),
    error: Color(0xFFD4949A),
    errorSoft: Color(0xFF2E1E20),
    screen: Color(0xFF17141A),
    card: Color(0xFF211E24),
    muted: Color(0xFF2A262C),
    elevated: Color(0xFF2E2A30),
    border: Color(0xFF3A343C),
    borderStrong: Color(0xFF4A434C),
    textPrimary: Color(0xFFF5F0EB),
    textSecondary: Color(0xFFB0A8A2),
    textTertiary: Color(0xFF807870),
    onPrimary: Color(0xFFFBF7F2),
    onAccent: Color(0xFF2A2428),
    disabledFill: Color(0xFF2A262C),
    disabledText: Color(0xFF5C5658),
    shadow: Color(0xFF2A2428),
    scrim: Color(0xFF17141A),
  );

  final Color primary;
  final Color primarySoft;
  final Color accent;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color screen;
  final Color card;
  final Color muted;
  final Color elevated;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color onPrimary;
  final Color onAccent;
  final Color disabledFill;
  final Color disabledText;
  final Color shadow;
  final Color scrim;

  List<Color> get auditColors => <Color>[
    primary,
    primarySoft,
    accent,
    success,
    successSoft,
    warning,
    warningSoft,
    error,
    errorSoft,
    screen,
    card,
    muted,
    elevated,
    border,
    borderStrong,
    textPrimary,
    textSecondary,
    textTertiary,
    onPrimary,
    onAccent,
    disabledFill,
    disabledText,
    shadow,
    scrim,
  ];

  static CurvePalette lerp(CurvePalette a, CurvePalette b, double t) {
    Color mix(Color from, Color to) => Color.lerp(from, to, t)!;
    return CurvePalette(
      primary: mix(a.primary, b.primary),
      primarySoft: mix(a.primarySoft, b.primarySoft),
      accent: mix(a.accent, b.accent),
      success: mix(a.success, b.success),
      successSoft: mix(a.successSoft, b.successSoft),
      warning: mix(a.warning, b.warning),
      warningSoft: mix(a.warningSoft, b.warningSoft),
      error: mix(a.error, b.error),
      errorSoft: mix(a.errorSoft, b.errorSoft),
      screen: mix(a.screen, b.screen),
      card: mix(a.card, b.card),
      muted: mix(a.muted, b.muted),
      elevated: mix(a.elevated, b.elevated),
      border: mix(a.border, b.border),
      borderStrong: mix(a.borderStrong, b.borderStrong),
      textPrimary: mix(a.textPrimary, b.textPrimary),
      textSecondary: mix(a.textSecondary, b.textSecondary),
      textTertiary: mix(a.textTertiary, b.textTertiary),
      onPrimary: mix(a.onPrimary, b.onPrimary),
      onAccent: mix(a.onAccent, b.onAccent),
      disabledFill: mix(a.disabledFill, b.disabledFill),
      disabledText: mix(a.disabledText, b.disabledText),
      shadow: mix(a.shadow, b.shadow),
      scrim: mix(a.scrim, b.scrim),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurvePalette && listEquals(auditColors, other.auditColors);
  }

  @override
  int get hashCode => Object.hashAll(auditColors);
}

/// True when [color] is fully opaque pure white or pure black.
bool isBannedSurfaceColor(Color color) {
  final int argb = color.toARGB32();
  final int rgb = argb & 0x00FFFFFF;
  final int alpha = (argb >> 24) & 0xFF;
  if (alpha == 0) {
    return false;
  }
  return rgb == 0x00FFFFFF || rgb == 0x000000;
}
