import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/training/data/workout_repository.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/set_template.dart';
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

  Future<WorkoutSession> startSession() async {
    final session = WorkoutSession.create();
    await ref.read(workoutRepositoryProvider).upsert(session);
    await _sync();
    return session;
  }

  Future<WorkoutSession> startFromPlan(PlannedSession planned) async {
    final repo = ref.read(workoutRepositoryProvider);
    final seeded = <WorkoutExercise>[];
    for (final WorkoutExercise exercise in exercisesFromPlan(planned)) {
      final history = await repo.lastCompletedSet(exerciseName: exercise.name);
      seeded.add(
        applyLastCompletedWeight(exercise: exercise, lastCompleted: history),
      );
    }
    final session = WorkoutSession.create().copyWith(exercises: seeded);
    await repo.upsert(session);
    await _sync();
    return session;
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
