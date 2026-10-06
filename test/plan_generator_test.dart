import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/plan/plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('three gym days are push pull legs on Mon Wed Fri', () {
    final plan = PlanGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
    );
    expect(plan.sessions.length, 3);
    expect(plan.sessions.map((s) => s.weekday).toList(), <int>[1, 3, 5]);
    expect(plan.sessions.first.title, '推');
    expect(plan.sessions.first.items.first.catalogId, 'ex_barbell_bench');
    expect(
      plan.sessions.first.items.first.sets,
      SetPrescriptions.hypertrophySets,
    );
  });

  test('strength uses 5x5 on the first movement', () {
    final plan = PlanGenerator.generate(
      goal: TrainingGoal.strength,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
    );
    final main = plan.sessions.first.items.first;
    expect(main.sets, SetPrescriptions.strengthMainSets);
    expect(main.reps, SetPrescriptions.strengthMainReps);
  });

  test('bodyweight profile avoids barbell catalog ids', () {
    final plan = PlanGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 2,
      equipment: EquipmentProfile.bodyweight,
    );
    for (final session in plan.sessions) {
      for (final item in session.items) {
        expect(item.catalogId.contains('barbell'), isFalse);
      }
    }
  });
}
