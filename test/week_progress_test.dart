import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:curvefree/features/home/muscle_groups.dart';
import 'package:curvefree/features/home/week_progress.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'week progress counts distinct local training days and planned sets',
    () {
      final DateTime now = DateTime(2026, 10, 16);
      final TrainingPlan plan = const TrainingPlan(
        goal: TrainingGoal.hypertrophy,
        daysPerWeek: 2,
        equipment: EquipmentProfile.fullGym,
        sessions: <PlannedSession>[
          PlannedSession(
            weekday: DateTime.wednesday,
            title: '推',
            items: <PlannedItem>[
              PlannedItem(
                catalogId: 'ex_barbell_bench',
                nameZh: '杠铃卧推',
                sets: 3,
                reps: 8,
              ),
            ],
          ),
          PlannedSession(
            weekday: DateTime.friday,
            title: '拉',
            items: <PlannedItem>[
              PlannedItem(
                catalogId: 'ex_barbell_row',
                nameZh: '杠铃划船',
                sets: 4,
                reps: 8,
              ),
            ],
          ),
        ],
      );
      final WorkoutSession trained = WorkoutSession(
        id: 's-week',
        startedAt: DateTime(2026, 10, 14, 18),
        endedAt: DateTime(2026, 10, 14, 19),
        notes: '',
        exercises: const <WorkoutExercise>[
          WorkoutExercise(
            id: 'e1',
            name: '杠铃卧推',
            catalogId: 'ex_barbell_bench',
            sets: <WorkoutSet>[
              WorkoutSet(id: 'a', weightKg: 40, reps: 8, completed: true),
              WorkoutSet(id: 'b', weightKg: 40, reps: 8, completed: false),
            ],
          ),
        ],
      );
      final WorkoutSession lastWeek = WorkoutSession(
        id: 's-old',
        startedAt: DateTime(2026, 10, 9, 18),
        endedAt: DateTime(2026, 10, 9, 19),
        notes: '',
        exercises: const <WorkoutExercise>[
          WorkoutExercise(
            id: 'e-old',
            name: '深蹲',
            sets: <WorkoutSet>[
              WorkoutSet(id: 'old', weightKg: 100, reps: 5, completed: true),
            ],
          ),
        ],
      );

      final WeekProgress progress = summarizeWeek(
        now: now,
        sessions: <WorkoutSession>[trained, lastWeek],
        plan: plan,
      );

      expect(progress.trainedDays, 1);
      expect(progress.plannedDays, 2);
      expect(progress.sessionsLabel, '1/2');
      expect(progress.completedSets, 1);
      expect(progress.plannedSets, 7);
      expect(progress.volumeKg, 320);
      expect(progress.dayFraction, 0.5);
      expect(progress.completionPercent, 14);
      expect(startOfLocalWeek(now), DateTime(2026, 10, 12));
    },
  );

  test('elapsed format stays clock-like', () {
    expect(ElapsedFormat.format(const Duration(seconds: 75)), '01:15');
    expect(
      ElapsedFormat.format(const Duration(hours: 1, minutes: 2)),
      '1:02:00',
    );
    expect(ElapsedFormat.format(const Duration(seconds: -3)), '00:00');
  });

  test('catalog exercises map onto muscle dots', () {
    expect(catalogMuscleGroups, isNotEmpty);
    expect(
      muscleGroupsFor(catalogId: 'ex_barbell_bench', name: '杠铃卧推'),
      <MuscleGroup>{MuscleGroup.chest},
    );
    expect(muscleGroupsFromName('自定义弯举'), <MuscleGroup>{MuscleGroup.arms});
    for (final CatalogExercise item in ExerciseCatalog.all) {
      expect(catalogMuscleGroups.containsKey(item.id), isTrue, reason: item.id);
    }
    expect(
      muscleDotState(
        group: MuscleGroup.chest,
        trained: <MuscleGroup>{MuscleGroup.chest},
        planned: <MuscleGroup>{MuscleGroup.back},
      ),
      MuscleDotState.trained,
    );
    expect(
      muscleDotState(
        group: MuscleGroup.back,
        trained: <MuscleGroup>{},
        planned: <MuscleGroup>{MuscleGroup.back},
      ),
      MuscleDotState.planned,
    );
  });
}
