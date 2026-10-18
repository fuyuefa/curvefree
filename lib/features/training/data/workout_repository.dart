import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/previous_sets.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:curvefree/features/training/unfinished_session.dart';

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

  /// Returns the newest unfinished session, or stores [created] when none is open.
  ///
  /// The check and the insert share one store mutation, so two start taps
  /// cannot each observe an empty log and write a second session.
  Future<WorkoutSession> openOrInsert(WorkoutSession created) async {
    final LocalStoreSnapshot snapshot = await _store.mutate((
      LocalStoreSnapshot current,
    ) {
      final List<WorkoutSession> sessions = current.workouts
          .map(WorkoutSession.fromJson)
          .toList(growable: false);
      if (newestUnfinishedSession(sessions) != null) {
        return current;
      }
      return current.copyWith(
        workouts: <Map<String, Object?>>[created.toJson(), ...current.workouts],
      );
    });
    final List<WorkoutSession> sessions = snapshot.workouts
        .map(WorkoutSession.fromJson)
        .toList(growable: false);
    final WorkoutSession? opened = newestUnfinishedSession(sessions);
    if (opened == null) {
      throw StateError('未能打开这次训练');
    }
    return opened;
  }

  /// Ends the newest unfinished session, if any, and stores [created].
  ///
  /// One mutation so "结束并开新" cannot observe the session it just finished
  /// and resume it instead of inserting.
  Future<WorkoutSession> finishNewestAndInsert(WorkoutSession created) async {
    final DateTime endedAt = DateTime.now();
    final LocalStoreSnapshot snapshot = await _store.mutate((
      LocalStoreSnapshot current,
    ) {
      final List<WorkoutSession> sessions = current.workouts
          .map(WorkoutSession.fromJson)
          .toList(growable: false);
      final WorkoutSession? open = newestUnfinishedSession(sessions);
      final List<Map<String, Object?>> next = <Map<String, Object?>>[
        created.toJson(),
      ];
      for (final WorkoutSession session in sessions) {
        if (open != null && session.id == open.id) {
          next.add(session.copyWith(endedAt: endedAt).toJson());
        } else {
          next.add(session.toJson());
        }
      }
      return current.copyWith(workouts: next);
    });
    for (final Map<String, Object?> item in snapshot.workouts) {
      if (item[TrainingJsonKeys.id]?.toString() == created.id) {
        return WorkoutSession.fromJson(item);
      }
    }
    throw StateError('未能开始这次训练');
  }

  Future<void> upsert(WorkoutSession session) async {
    await _store.mutate((snapshot) {
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
      return snapshot.copyWith(workouts: next);
    });
  }

  /// Applies [update] to the session currently on disk.
  ///
  /// Set completions must not rebuild the document from a widget snapshot
  /// captured before the previous write finished.
  Future<void> applySessionEdit({
    required String sessionId,
    required WorkoutSession Function(WorkoutSession current) update,
  }) async {
    await _store.mutate((snapshot) {
      final sessions = snapshot.workouts
          .map(WorkoutSession.fromJson)
          .toList(growable: true);
      final index = sessions.indexWhere(
        (WorkoutSession item) => item.id == sessionId,
      );
      if (index < 0) {
        throw StateError('这次训练不存在');
      }
      sessions[index] = update(sessions[index]);
      return snapshot.copyWith(
        workouts: sessions
            .map((WorkoutSession item) => item.toJson())
            .toList(growable: false),
      );
    });
  }

  Future<void> delete(String id) async {
    await _store.mutate((snapshot) {
      final next = snapshot.workouts
          .where(
            (Map<String, Object?> item) =>
                item[TrainingJsonKeys.id]?.toString() != id,
          )
          .toList(growable: false);
      return snapshot.copyWith(workouts: next);
    });
  }

  /// Latest completed set for [exerciseName] in sessions other than [exceptSessionId].
  Future<WorkoutSet?> lastCompletedSet({
    required String exerciseName,
    String? exceptSessionId,
  }) async {
    final needle = exerciseName.trim();
    if (needle.isEmpty) {
      return null;
    }
    final sessions = await listNewestFirst();
    for (final WorkoutSession session in sessions) {
      if (exceptSessionId != null && session.id == exceptSessionId) {
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

  /// Completed sets from the last time [exerciseName] was logged, by index.
  ///
  /// [exceptSessionId] is the open session, so today's rows are not their own history.
  Future<List<WorkoutSet?>> previousSetsByIndex({
    required String exerciseName,
    String? exceptSessionId,
  }) async {
    final List<WorkoutSession> sessions = await listNewestFirst();
    return previousCompletedSetsByIndex(
      sessionsNewestFirst: sessions,
      exerciseName: exerciseName,
      exceptSessionId: exceptSessionId,
    );
  }
}
