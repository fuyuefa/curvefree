import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_json_keys.dart';

/// Previous column for one exercise, aligned by set index.
///
/// The source is the newest other session that completed this movement.
/// An index that was not completed in that session is null, even if an
/// older session completed it, so the column stays one workout.
List<WorkoutSet?> previousCompletedSetsByIndex({
  required List<WorkoutSession> sessionsNewestFirst,
  required String exerciseName,
  String? exceptSessionId,
}) {
  final String needle = exerciseName.trim();
  if (needle.isEmpty) {
    return const <WorkoutSet?>[];
  }
  for (final WorkoutSession session in sessionsNewestFirst) {
    if (exceptSessionId != null && session.id == exceptSessionId) {
      continue;
    }
    for (final WorkoutExercise exercise in session.exercises) {
      if (exercise.name.trim() != needle) {
        continue;
      }
      final bool anyCompleted = exercise.sets.any(
        (WorkoutSet set) => set.completed,
      );
      if (!anyCompleted) {
        continue;
      }
      return <WorkoutSet?>[
        for (final WorkoutSet set in exercise.sets) set.completed ? set : null,
      ];
    }
  }
  return const <WorkoutSet?>[];
}

String formatWeightKg(double weightKg) {
  final bool whole = weightKg == weightKg.roundToDouble();
  final int digits = whole ? 0 : TrainingDefaults.weightFractionDigits;
  return weightKg.toStringAsFixed(digits);
}

/// `40×8`, or [AppStrings.previousEmpty] when this index has no history.
String formatPreviousLoad(WorkoutSet? set) {
  if (set == null || !set.completed) {
    return AppStrings.previousEmpty;
  }
  return '${formatWeightKg(set.weightKg)}'
      '${AppStrings.previousLoadTimes}'
      '${set.reps}';
}
