import 'package:curvefree/features/training/models/workout_models.dart';

/// The next open set after [completedIndex] in the same exercise.
///
/// Does not wrap to an earlier open set. Null when nothing later is open.
String? nextIncompleteSetId({
  required List<WorkoutSet> sets,
  required int completedIndex,
}) {
  if (completedIndex < 0 || completedIndex >= sets.length) {
    return null;
  }
  for (int index = completedIndex + 1; index < sets.length; index++) {
    if (!sets[index].completed) {
      return sets[index].id;
    }
  }
  return null;
}
