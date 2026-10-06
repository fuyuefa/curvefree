import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_json_keys.dart';

final class WorkoutRepository {
  const WorkoutRepository(this._store);

  final LocalStore _store;

  Future<List<WorkoutSession>> listNewestFirst() async {
    final snapshot = await _store.read();
    final sessions = snapshot.workouts
        .map(WorkoutSession.fromJson)
        .toList(growable: true);
    sessions.sort(
      (WorkoutSession a, WorkoutSession b) =>
          b.startedAt.compareTo(a.startedAt),
    );
    return List<WorkoutSession>.unmodifiable(sessions);
  }

  Future<WorkoutSession?> getById(String id) async {
    final sessions = await listNewestFirst();
    for (final WorkoutSession session in sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  Future<void> upsert(WorkoutSession session) async {
    final snapshot = await _store.read();
    final next = snapshot.workouts
        .map((Map<String, Object?> item) => Map<String, Object?>.from(item))
        .toList(growable: true);
    final index = next.indexWhere(
      (Map<String, Object?> item) =>
          item[TrainingJsonKeys.id]?.toString() == session.id,
    );
    final encoded = session.toJson();
    if (index >= 0) {
      next[index] = encoded;
    } else {
      next.insert(0, encoded);
    }
    await _store.write(snapshot.copyWith(workouts: next));
  }

  Future<void> delete(String id) async {
    final snapshot = await _store.read();
    final next = snapshot.workouts
        .where(
          (Map<String, Object?> item) =>
              item[TrainingJsonKeys.id]?.toString() != id,
        )
        .toList(growable: false);
    await _store.write(snapshot.copyWith(workouts: next));
  }

  /// Latest completed set for [exerciseName] in sessions other than [exceptSessionId].
  Future<WorkoutSet?> lastCompletedSet({
    required String exerciseName,
    required String exceptSessionId,
  }) async {
    final needle = exerciseName.trim();
    if (needle.isEmpty) {
      return null;
    }
    final sessions = await listNewestFirst();
    for (final WorkoutSession session in sessions) {
      if (session.id == exceptSessionId) {
        continue;
      }
      for (final WorkoutExercise exercise in session.exercises) {
        if (exercise.name.trim() != needle) {
          continue;
        }
        for (final WorkoutSet set in exercise.sets.reversed) {
          if (set.completed) {
            return set;
          }
        }
      }
    }
    return null;
  }
}
