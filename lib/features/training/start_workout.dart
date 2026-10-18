import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/unfinished_session.dart';
import 'package:curvefree/features/training/widgets/start_conflict_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks before replacing an open session, then pushes the chosen workout.
///
/// [planned] null starts an empty session (training FAB). A plan day is used
/// by today and the plan page.
Future<void> pushStartedWorkout(
  BuildContext context,
  WidgetRef ref, {
  PlannedSession? planned,
}) async {
  final WorkoutSession? session = await beginWorkout(
    context,
    ref,
    planned: planned,
  );
  if (session == null || !context.mounted) {
    return;
  }
  await Navigator.of(context).push(sessionPageRoute(session.id));
}

/// Resolves the session to open. Cancel returns null and writes nothing.
Future<WorkoutSession?> beginWorkout(
  BuildContext context,
  WidgetRef ref, {
  PlannedSession? planned,
}) async {
  final List<WorkoutSession> loaded = await ref.read(
    workoutSessionsProvider.future,
  );
  if (!context.mounted) {
    return null;
  }
  final WorkoutSession? unfinished = newestUnfinishedSession(loaded);
  final WorkoutSessionsController notifier = ref.read(
    workoutSessionsProvider.notifier,
  );
  if (unfinished == null) {
    if (planned == null) {
      return notifier.startSession();
    }
    return notifier.startFromPlan(planned);
  }
  final StartConflictChoice choice = await showStartConflictSheet(context);
  if (!context.mounted) {
    return null;
  }
  switch (choice) {
    case StartConflictChoice.resumeCurrent:
      return unfinished;
    case StartConflictChoice.finishAndStartNew:
      if (planned == null) {
        return notifier.finishOpenAndStartEmpty();
      }
      return notifier.finishOpenAndStartFromPlan(planned);
    case StartConflictChoice.cancel:
      return null;
  }
}
