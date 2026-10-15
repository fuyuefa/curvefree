import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_json_keys.dart';

bool _isPlaceholderSet(WorkoutSet set) {
  return !set.completed &&
      set.weightKg == TrainingDefaults.defaultWeightKg &&
      set.reps == TrainingDefaults.defaultReps;
}

/// Weight and reps for a set the user just added.
///
/// A completed or edited set in this exercise wins. Otherwise the last
/// completed set for the movement is the default, not only a hint.
WorkoutSet nextSetTemplate({
  required List<WorkoutSet> existingSets,
  WorkoutSet? lastCompleted,
}) {
  if (existingSets.isNotEmpty) {
    final last = existingSets.last;
    if (!_isPlaceholderSet(last) || lastCompleted == null) {
      return WorkoutSet.create(weightKg: last.weightKg, reps: last.reps);
    }
  }
  if (lastCompleted != null) {
    return WorkoutSet.create(
      weightKg: lastCompleted.weightKg,
      reps: lastCompleted.reps,
    );
  }
  return WorkoutSet.create();
}

WorkoutExercise exerciseSeededFromHistory({
  required String name,
  String? catalogId,
  WorkoutSet? lastCompleted,
}) {
  final created = WorkoutExercise.create(name, catalogId: catalogId);
  if (lastCompleted == null) {
    return created;
  }
  return created.copyWith(
    sets: <WorkoutSet>[
      WorkoutSet.create(
        weightKg: lastCompleted.weightKg,
        reps: lastCompleted.reps,
      ),
    ],
  );
}

/// Keeps the plan's prescribed reps and fills weight from [lastCompleted].
WorkoutExercise applyLastCompletedWeight({
  required WorkoutExercise exercise,
  required WorkoutSet? lastCompleted,
}) {
  if (lastCompleted == null) {
    return exercise;
  }
  return exercise.copyWith(
    sets: <WorkoutSet>[
      for (final WorkoutSet set in exercise.sets)
        WorkoutSet(
          id: set.id,
          weightKg: lastCompleted.weightKg,
          reps: set.reps,
          completed: set.completed,
        ),
    ],
  );
}
