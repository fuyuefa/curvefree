import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_adjustments.dart';
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

  test('experience, body size, and activity change sets when present', () {
    final int base = _sets(_baseline(), 'ex_barbell_bench');

    expect(
      _sets(
        _baseline(experience: TrainingExperience.beginner),
        'ex_barbell_bench',
      ),
      base + PlanVolumeLimits.beginnerSetDelta,
    );
    expect(
      _sets(
        _baseline(experience: TrainingExperience.advanced),
        'ex_barbell_bench',
      ),
      base + PlanVolumeLimits.advancedSetDelta,
    );
    expect(
      _sets(
        _baseline(experience: TrainingExperience.intermediate),
        'ex_barbell_bench',
      ),
      base,
    );

    expect(
      _sets(_baseline(heightCm: 180, weightKg: 55), 'ex_barbell_bench'),
      base + PlanVolumeLimits.underweightSetDelta,
    );
    expect(
      _sets(_baseline(heightCm: 150, weightKg: 55), 'ex_barbell_bench'),
      base,
    );
    expect(_sets(_baseline(weightKg: 55), 'ex_barbell_bench'), base);
    final TrainingPlan beginnerStrength = PlanGenerator.generate(
      goal: TrainingGoal.strength,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
      experience: TrainingExperience.beginner,
      heightCm: 175,
      weightKg: 70,
    );
    final TrainingPlan heavyBeginner = PlanGenerator.generate(
      goal: TrainingGoal.strength,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
      experience: TrainingExperience.beginner,
      heightCm: 170,
      weightKg: 90,
    );
    expect(
      _sets(beginnerStrength, 'ex_barbell_bench'),
      SetPrescriptions.strengthMainSets + PlanVolumeLimits.beginnerSetDelta,
    );
    expect(
      _sets(heavyBeginner, 'ex_barbell_bench'),
      SetPrescriptions.strengthMainSets +
          PlanVolumeLimits.beginnerSetDelta +
          PlanVolumeLimits.highBmiBeginnerSetDelta,
    );

    final TrainingPlan neutral = _baseline(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 60,
      experience: TrainingExperience.intermediate,
      preferences: TrainingPreference.values,
      activity: DailyActivity.light,
    );
    expect(_sets(neutral, 'ex_barbell_bench'), base);
    expect(neutral.sessions.map((s) => s.weekday).toList(), <int>[1, 3, 5]);
    expect(neutral.periodAdjusted, isFalse);

    expect(
      _sets(_baseline(activity: DailyActivity.active), 'ex_barbell_bench'),
      base + PlanVolumeLimits.activeSetDelta,
    );
    expect(
      _sets(_baseline(activity: DailyActivity.sedentary), 'ex_barbell_bench'),
      base,
    );
    expect(
      _sets(_baseline(activity: DailyActivity.moderate), 'ex_barbell_bench'),
      base,
    );
  });

  test('preferred patterns gain a set and missing patterns are filled', () {
    final plan = _baseline(
      preferences: const <TrainingPreference>[TrainingPreference.push],
    );
    expect(
      _sets(plan, 'ex_barbell_bench'),
      SetPrescriptions.hypertrophySets + PlanVolumeLimits.preferenceSetDelta,
    );
    expect(_sets(plan, 'ex_barbell_row'), SetPrescriptions.hypertrophySets);

    final TrainingPlan all = _baseline(preferences: TrainingPreference.values);
    expect(_sets(all, 'ex_barbell_bench'), SetPrescriptions.hypertrophySets);
    expect(all.sessions.first.items, hasLength(3));

    expect(
      missingPreferenceCatalogIds(
        presentCatalogIds: const <String>['ex_barbell_row'],
        preferences: const <TrainingPreference>[TrainingPreference.push],
        equipment: EquipmentProfile.fullGym,
      ),
      <String>['ex_barbell_bench'],
    );
    expect(
      missingPreferenceCatalogIds(
        presentCatalogIds: const <String>['ex_plank'],
        preferences: const <TrainingPreference>[TrainingPreference.core],
        equipment: EquipmentProfile.bodyweight,
      ),
      isEmpty,
    );
  });

  test('female period window reduces sets and a missing cycle does not', () {
    final TrainingPlan base = _baseline(sex: BiologicalSex.female);
    expect(_sets(base, 'ex_barbell_bench'), SetPrescriptions.hypertrophySets);
    expect(base.periodAdjusted, isFalse);
    expect(base.toJson()['periodAdjusted'], isFalse);

    const CycleProfile cycle = CycleProfile(
      periodDays: 5,
      cycleDays: 28,
      lastStart: null,
    );
    final CycleProfile placed = CycleProfile(
      periodDays: 5,
      cycleDays: 28,
      lastStart: DateTime(2026, 10, 1),
    );
    final TrainingPlan during = PlanGenerator.adjustForPeriod(
      base,
      sex: BiologicalSex.female,
      cycle: placed,
      onDate: DateTime(2026, 10, 3),
    );
    expect(during.periodAdjusted, isTrue);
    expect(
      _sets(during, 'ex_barbell_bench'),
      SetPrescriptions.hypertrophySets + PlanVolumeLimits.periodSetDelta,
    );
    final TrainingPlan again = PlanGenerator.adjustForPeriod(
      during,
      sex: BiologicalSex.female,
      cycle: placed,
      onDate: DateTime(2026, 10, 3),
    );
    expect(_sets(again, 'ex_barbell_bench'), _sets(during, 'ex_barbell_bench'));

    final TrainingPlan later = PlanGenerator.adjustForPeriod(
      base,
      sex: BiologicalSex.female,
      cycle: placed,
      onDate: DateTime(2026, 10, 20),
    );
    expect(later.periodAdjusted, isFalse);
    expect(_sets(later, 'ex_barbell_bench'), SetPrescriptions.hypertrophySets);

    final TrainingPlan noDate = PlanGenerator.adjustForPeriod(
      base,
      sex: BiologicalSex.female,
      cycle: cycle,
      onDate: DateTime(2026, 10, 3),
    );
    expect(_sets(noDate, 'ex_barbell_bench'), SetPrescriptions.hypertrophySets);

    final TrainingPlan male = PlanGenerator.adjustForPeriod(
      _baseline(sex: BiologicalSex.male),
      sex: BiologicalSex.male,
      cycle: placed,
      onDate: DateTime(2026, 10, 3),
    );
    expect(_sets(male, 'ex_barbell_bench'), SetPrescriptions.hypertrophySets);

    final CycleProfile unknownLength = CycleProfile(
      periodDays: 5,
      cycleUnknown: true,
      lastStart: DateTime(2026, 10, 1),
    );
    expect(
      _sets(
        PlanGenerator.adjustForPeriod(
          base,
          sex: BiologicalSex.female,
          cycle: unknownLength,
          onDate: DateTime(2026, 10, 3),
        ),
        'ex_barbell_bench',
      ),
      SetPrescriptions.hypertrophySets + PlanVolumeLimits.periodSetDelta,
    );
    expect(
      PlanGenerator.adjustForPeriod(
        base,
        sex: BiologicalSex.female,
        cycle: unknownLength,
        onDate: DateTime(2026, 11, 1),
      ).periodAdjusted,
      isFalse,
    );

    final TrainingPlan preview = PlanGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
      sex: BiologicalSex.female,
      cycle: placed,
      onDate: DateTime(2026, 10, 3),
    );
    expect(preview.periodAdjusted, isTrue);
    expect(preview.sessions.map((s) => s.title).toList(), <String>[
      '推',
      '拉',
      '腿',
    ]);
  });
}

TrainingPlan _baseline({
  BiologicalSex? sex,
  int? heightCm,
  double? weightKg,
  TrainingExperience? experience,
  List<TrainingPreference> preferences = const <TrainingPreference>[],
  DailyActivity? activity,
}) {
  return PlanGenerator.generate(
    goal: TrainingGoal.hypertrophy,
    daysPerWeek: 3,
    equipment: EquipmentProfile.fullGym,
    sex: sex,
    heightCm: heightCm,
    weightKg: weightKg,
    experience: experience,
    preferences: preferences,
    activity: activity,
  );
}

int _sets(TrainingPlan plan, String catalogId) {
  for (final session in plan.sessions) {
    for (final item in session.items) {
      if (item.catalogId == catalogId) {
        return item.sets;
      }
    }
  }
  fail('missing $catalogId');
}
