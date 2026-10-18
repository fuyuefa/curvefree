import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';

/// Name shown on the resume card.
///
/// A session started from a plan keeps that day's title. Older rows, and a
/// free session that already has movements, fall back to the first exercise.
String sessionDisplayName(WorkoutSession session) {
  final String title = session.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  for (final WorkoutExercise exercise in session.exercises) {
    final String name = exercise.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
  }
  return AppStrings.freeWorkoutName;
}
