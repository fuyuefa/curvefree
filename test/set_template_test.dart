import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/set_template.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const history = WorkoutSet(
    id: 'hist',
    weightKg: 100,
    reps: 3,
    completed: true,
  );

  test('first set uses last completed weight and reps', () {
    final seeded = exerciseSeededFromHistory(
      name: '深蹲',
      lastCompleted: history,
    );
    expect(seeded.sets.single.weightKg, 100);
    expect(seeded.sets.single.reps, 3);
    expect(seeded.sets.single.completed, isFalse);
  });

  test('added set copies an edited set instead of history', () {
    final next = nextSetTemplate(
      existingSets: const <WorkoutSet>[
        WorkoutSet(id: 's1', weightKg: 110, reps: 5, completed: false),
      ],
      lastCompleted: history,
    );
    expect(next.weightKg, 110);
    expect(next.reps, 5);
    expect(next.completed, isFalse);
  });

  test('added set replaces an untouched default with last completed', () {
    final next = nextSetTemplate(
      existingSets: const <WorkoutSet>[
        WorkoutSet(
          id: 's1',
          weightKg: TrainingDefaults.defaultWeightKg,
          reps: TrainingDefaults.defaultReps,
          completed: false,
        ),
      ],
      lastCompleted: history,
    );
    expect(next.weightKg, 100);
    expect(next.reps, 3);
  });

  test('plan sets keep prescribed reps and take last weight', () {
    final exercise = WorkoutExercise.create('卧推').copyWith(
      sets: <WorkoutSet>[
        WorkoutSet.create(reps: 5),
        WorkoutSet.create(reps: 5),
      ],
    );
    final weighted = applyLastCompletedWeight(
      exercise: exercise,
      lastCompleted: history,
    );
    expect(weighted.sets, hasLength(2));
    expect(weighted.sets.first.id, exercise.sets.first.id);
    expect(
      weighted.sets.every((WorkoutSet set) => set.weightKg == 100),
      isTrue,
    );
    expect(weighted.sets.every((WorkoutSet set) => set.reps == 5), isTrue);
  });
}
