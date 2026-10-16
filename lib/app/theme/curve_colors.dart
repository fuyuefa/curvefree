import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:flutter/material.dart';

/// Theme extension so screens read v3.2 tokens instead of raw hex.
@immutable
final class CurveColors extends ThemeExtension<CurveColors> {
  const CurveColors(this.palette);

  final CurvePalette palette;

  static CurveColors of(BuildContext context) {
    final CurveColors? colors = Theme.of(context).extension<CurveColors>();
    if (colors == null) {
      throw FlutterError(
        'CurveColors is missing from ThemeData.extensions. '
        'Use buildCurveFreeTheme.',
      );
    }
    return colors;
  }

  Color get primary => palette.primary;
  Color get primarySoft => palette.primarySoft;
  Color get accent => palette.accent;
  Color get success => palette.success;
  Color get successSoft => palette.successSoft;
  Color get warning => palette.warning;
  Color get warningSoft => palette.warningSoft;
  Color get error => palette.error;
  Color get errorSoft => palette.errorSoft;
  Color get screen => palette.screen;
  Color get card => palette.card;
  Color get muted => palette.muted;
  Color get elevated => palette.elevated;
  Color get border => palette.border;
  Color get borderStrong => palette.borderStrong;
  Color get textPrimary => palette.textPrimary;
  Color get textSecondary => palette.textSecondary;
  Color get textTertiary => palette.textTertiary;
  Color get onPrimary => palette.onPrimary;
  Color get onAccent => palette.onAccent;
  Color get disabledFill => palette.disabledFill;
  Color get disabledText => palette.disabledText;

  @override
  CurveColors copyWith({CurvePalette? palette}) {
    return CurveColors(palette ?? this.palette);
  }

  @override
  CurveColors lerp(ThemeExtension<CurveColors>? other, double t) {
    if (other is! CurveColors) {
      return this;
    }
    return CurveColors(CurvePalette.lerp(palette, other.palette, t));
  }

  @override
  bool operator ==(Object other) {
    return other is CurveColors && other.palette == palette;
  }

  @override
  int get hashCode => palette.hashCode;
}
