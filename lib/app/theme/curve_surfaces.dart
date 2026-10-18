import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/material.dart';

BoxDecoration curveSurfaceDecoration(
  CurveColors colors, {
  Color? color,
  double radius = AppRadii.card,
  Color? borderColor,
  double borderWidth = AppLayout.borderWidth,
}) {
  return BoxDecoration(
    color: color ?? colors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? colors.border, width: borderWidth),
  );
}
