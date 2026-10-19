import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/material.dart';

/// Peak fill for the brief rest-end flash.
///
/// Surfaces that are not already [primarySoft] flash that cream. The rest bar
/// is [primarySoft] for the whole countdown, so its peak leans toward
/// [primary] by [AppMotion.restEndFlashLean] and stays in the taro family.
Color restEndPeakFill({
  required Color idle,
  required Color primarySoft,
  required Color primary,
}) {
  if (idle.toARGB32() == primarySoft.toARGB32()) {
    return Color.lerp(primarySoft, primary, AppMotion.restEndFlashLean)!;
  }
  return primarySoft;
}
