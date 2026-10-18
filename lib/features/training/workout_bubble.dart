import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:flutter/material.dart';

/// Primary line, and the elapsed line shown under an active rest countdown.
final class WorkoutBubbleLines {
  const WorkoutBubbleLines({required this.primary, this.secondary});

  final String primary;
  final String? secondary;
}

/// Float copy. [resting] uses the live countdown; otherwise the elapsed line.
WorkoutBubbleLines workoutBubbleLines({
  required Duration elapsed,
  required bool resting,
  required Duration restRemaining,
}) {
  final String elapsedLine =
      '${AppStrings.workoutBubbleLabel} ${ElapsedFormat.format(elapsed)}';
  if (!resting || restRemaining <= Duration.zero) {
    return WorkoutBubbleLines(primary: elapsedLine);
  }
  return WorkoutBubbleLines(
    primary:
        '${AppStrings.restBubbleLabel} ${ElapsedFormat.countdown(restRemaining)}',
    secondary: elapsedLine,
  );
}

/// How a float tap returns to [sessionId] without starting another workout.
enum FloatResumeKind { stay, popToSession, pushSession }

final class FloatResume {
  const FloatResume({required this.kind, required this.routeName});

  final FloatResumeKind kind;
  final String routeName;
}

FloatResume planFloatResume({
  required String sessionId,
  required String? topPageRouteName,
  required Iterable<String?> pageRouteNames,
}) {
  final String routeName = SessionRoutes.nameFor(sessionId);
  if (topPageRouteName == routeName) {
    return FloatResume(kind: FloatResumeKind.stay, routeName: routeName);
  }
  if (pageRouteNames.contains(routeName)) {
    return FloatResume(
      kind: FloatResumeKind.popToSession,
      routeName: routeName,
    );
  }
  return FloatResume(kind: FloatResumeKind.pushSession, routeName: routeName);
}

/// Whether the in-progress bubble should show for [unfinished].
///
/// Hidden on that session's own page, while a dialog or sheet is up, when
/// the session is finished, and while it is still an empty draft. The wall
/// clock starts only after the session has at least one exercise.
bool workoutBubbleVisible({
  required WorkoutSession? unfinished,
  required String? topPageRouteName,
  required bool coveredByPopup,
}) {
  if (coveredByPopup) {
    return false;
  }
  if (unfinished == null || !unfinished.isTimerRunning) {
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
