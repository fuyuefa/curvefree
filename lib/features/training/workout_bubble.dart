import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:flutter/material.dart';

/// Whether the in-progress bubble should show for [unfinished].
///
/// Hidden on that session's own page, while a dialog or sheet is up, and
/// when nothing is unfinished. Shell tabs and other pushed pages show it.
bool workoutBubbleVisible({
  required WorkoutSession? unfinished,
  required String? topPageRouteName,
  required bool coveredByPopup,
}) {
  if (coveredByPopup) {
    return false;
  }
  if (unfinished == null || unfinished.isFinished) {
    return false;
  }
  return topPageRouteName != SessionRoutes.nameFor(unfinished.id);
}

/// Distance from the screen bottom. Shell tabs sit above the bottom nav.
double workoutBubbleBottomInset({
  required String? topPageRouteName,
  required double safeBottom,
}) {
  final bool aboveNav = topPageRouteName == Navigator.defaultRouteName;
  final double nav = aboveNav ? AppLayout.bottomNavHeight : 0;
  return safeBottom + nav + AppSpacing.sm;
}
