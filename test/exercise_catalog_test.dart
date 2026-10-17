import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog search filters by name and pattern', () {
    expect(ExerciseCatalog.all, isNotEmpty);
    expect(ExerciseCatalog.byId('ex_deadlift')?.nameZh, '硬拉');
    final rows = ExerciseCatalog.search('划船');
    expect(rows.every((item) => item.nameZh.contains('划船')), isTrue);
    expect(ExerciseCatalog.search('拉').isNotEmpty, isTrue);
    expect(
      ExerciseCatalog.search('臀').map((CatalogExercise item) => item.id),
      contains('ex_hip_thrust'),
    );
  });

  test('every catalog exercise has a body part and sessions resolve ids', () {
    for (final CatalogExercise item in ExerciseCatalog.all) {
      expect(ExerciseCatalog.bodyPartIds[item.id], isNotEmpty);
      expect(ExerciseCatalog.byId(item.id)?.nameZh, item.nameZh);
    }

    final List<WorkoutExercise> seeded = exercisesFromPlan(
      const PlannedSession(
        weekday: 1,
        title: '推',
        items: <PlannedItem>[
          PlannedItem(catalogId: '', nameZh: '杠铃卧推', sets: 3, reps: 8),
          PlannedItem(catalogId: 'ex_plank', nameZh: '平板支撑', sets: 2, reps: 8),
          PlannedItem(catalogId: '', nameZh: '我的自创动作', sets: 1, reps: 8),
        ],
      ),
    );
    expect(seeded[0].catalogId, 'ex_barbell_bench');
    expect(seeded[0].name, '杠铃卧推');
    expect(ExerciseCatalog.byId(seeded[0].catalogId)?.nameZh, seeded[0].name);
    expect(seeded[1].catalogId, 'ex_plank');
    expect(seeded[2].catalogId, isNull);
    expect(seeded[2].name, '我的自创动作');
  });
}
