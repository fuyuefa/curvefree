import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/training/data/workout_repository.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/set_template.dart';
import 'package:curvefree/features/training/unfinished_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((Ref ref) {
  return WorkoutRepository(ref.watch(localStoreProvider));
});

final workoutSessionsProvider =
    AsyncNotifierProvider<WorkoutSessionsController, List<WorkoutSession>>(
      WorkoutSessionsController.new,
    );

final class WorkoutSessionsController
    extends AsyncNotifier<List<WorkoutSession>> {
  @override
  Future<List<WorkoutSession>> build() {
    return ref.read(workoutRepositoryProvider).listNewestFirst();
  }

  Future<void> _sync() async {
    await ref.read(localStoreSnapshotProvider.notifier).reload();
    state = AsyncData(
      await ref.read(workoutRepositoryProvider).listNewestFirst(),
    );
  }

  /// Opens the newest unfinished session, or records a new empty one.
  Future<WorkoutSession> startSession() {
    return _openOrCreate(WorkoutSession.create());
  }

  /// Opens the newest unfinished session, or records one seeded from [planned].
  ///
  /// Today, the training log, and the plan page all enter here or through
  /// [startSession]. An open session is resumed instead of duplicated.
  Future<WorkoutSession> startFromPlan(PlannedSession planned) async {
    final repo = ref.read(workoutRepositoryProvider);
    final existing = newestUnfinishedSession(await repo.listNewestFirst());
    if (existing != null) {
      await _sync();
      return existing;
    }
    final seeded = <WorkoutExercise>[];
    for (final WorkoutExercise exercise in exercisesFromPlan(planned)) {
      final history = await repo.lastCompletedSet(exerciseName: exercise.name);
      seeded.add(
        applyLastCompletedWeight(exercise: exercise, lastCompleted: history),
      );
    }
    return _openOrCreate(WorkoutSession.create().copyWith(exercises: seeded));
  }

  Future<WorkoutSession> _openOrCreate(WorkoutSession created) async {
    final opened = await ref
        .read(workoutRepositoryProvider)
        .openOrInsert(created);
    await _sync();
    return opened;
  }

  Future<void> save(WorkoutSession session) async {
    await ref.read(workoutRepositoryProvider).upsert(session);
    await _sync();
  }

  Future<void> edit(
    String sessionId,
    WorkoutSession Function(WorkoutSession current) update,
  ) async {
    await ref
        .read(workoutRepositoryProvider)
        .applySessionEdit(sessionId: sessionId, update: update);
    await _sync();
  }

  Future<void> finish(String sessionId) {
    return edit(sessionId, (WorkoutSession current) {
      return current.copyWith(endedAt: DateTime.now());
    });
  }

  Future<void> delete(String id) async {
    await ref.read(workoutRepositoryProvider).delete(id);
    await _sync();
  }
}
