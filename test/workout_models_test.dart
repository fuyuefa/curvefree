import 'dart:io';

import 'package:curvefree/core/storage/file_local_store.dart';
import 'package:curvefree/features/training/data/workout_repository.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('volume counts only completed sets', () {
    final session = WorkoutSession.create().copyWith(
      exercises: <WorkoutExercise>[
        const WorkoutExercise(
          id: 'e1',
          name: '卧推',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's1', weightKg: 60, reps: 5, completed: true),
            WorkoutSet(id: 's2', weightKg: 80, reps: 5, completed: false),
          ],
        ),
      ],
    );
    expect(session.volumeKg, 300);
    expect(session.completedSetCount, 1);
  });

  test('repository upserts and finds last completed set', () async {
    final directory = await Directory.systemTemp.createTemp('curvefree_w_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final repo = WorkoutRepository(
      FileLocalStore(overrideDirectory: directory),
    );

    final previous = WorkoutSession.create().copyWith(
      endedAt: DateTime.now(),
      exercises: <WorkoutExercise>[
        const WorkoutExercise(
          id: 'e-old',
          name: '深蹲',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's-old', weightKg: 100, reps: 3, completed: true),
          ],
        ),
      ],
    );
    await repo.upsert(previous);

    final current = WorkoutSession.create();
    await repo.upsert(current);

    final hint = await repo.lastCompletedSet(
      exerciseName: '深蹲',
      exceptSessionId: current.id,
    );
    expect(hint?.weightKg, 100);
    expect(hint?.reps, 3);

    final listed = await repo.listNewestFirst();
    expect(listed.length, 2);
  });

  test('parallel set completions on one session all persist', () async {
    final directory = await Directory.systemTemp.createTemp('curvefree_sets_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final repo = WorkoutRepository(
      FileLocalStore(overrideDirectory: directory),
    );
    const setCount = 8;
    final session = WorkoutSession.create().copyWith(
      exercises: <WorkoutExercise>[
        WorkoutExercise(
          id: 'e1',
          name: '卧推',
          sets: <WorkoutSet>[
            for (var i = 0; i < setCount; i++)
              WorkoutSet(id: 's$i', weightKg: 20, reps: 8, completed: false),
          ],
        ),
      ],
    );
    await repo.upsert(session);

    await Future.wait(<Future<void>>[
      for (var i = 0; i < setCount; i++)
        repo.applySessionEdit(
          sessionId: session.id,
          update: (WorkoutSession current) {
            final exercise = current.exercises.single;
            return current.copyWith(
              exercises: <WorkoutExercise>[
                exercise.copyWith(
                  sets: exercise.sets
                      .map((WorkoutSet set) {
                        if (set.id != 's$i') {
                          return set;
                        }
                        return set.copyWith(
                          completed: true,
                          weightKg: 40 + i.toDouble(),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            );
          },
        ),
    ]);

    final stored = await repo.getById(session.id);
    final storedSets = stored!.exercises.single.sets;
    expect(
      storedSets.where((WorkoutSet set) => set.completed),
      hasLength(setCount),
    );
    for (var i = 0; i < setCount; i++) {
      final match = storedSets.singleWhere((WorkoutSet set) => set.id == 's$i');
      expect(match.weightKg, 40 + i);
    }
  });
}
