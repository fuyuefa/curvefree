import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/nutrition/nutrition_targets.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing body metrics keep the fixed calorie and protein defaults', () {
    final NutritionTargets targets = NutritionTargetMath.resolve();
    expect(targets.calorieKcal, NutritionDefaults.calorieTargetKcal);
    expect(targets.proteinG, NutritionDefaults.proteinTargetG);
    expect(targets.fatG, greaterThan(0));
    expect(targets.carbG, greaterThan(0));

    final NutritionTargets explicit = NutritionTargetMath.resolve(
      explicitCalorieKcal: 1800,
      explicitProteinG: 100,
    );
    expect(explicit.calorieKcal, 1800);
    expect(explicit.proteinG, 100);
  });

  test('body, sex, activity, and goal move targets off the fixed defaults', () {
    final NutritionTargets female = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 55,
      activity: DailyActivity.sedentary,
    );
    expect(female.calorieKcal, 1524);
    expect(female.proteinG, 88);
    expect(female.calorieKcal, isNot(NutritionDefaults.calorieTargetKcal));
    expect(female.proteinG, isNot(NutritionDefaults.proteinTargetG));

    final NutritionTargets male = NutritionTargetMath.resolve(
      sex: BiologicalSex.male,
      heightCm: 165,
      weightKg: 55,
      activity: DailyActivity.sedentary,
    );
    expect(male.calorieKcal, greaterThan(female.calorieKcal));

    final NutritionTargets active = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 55,
      activity: DailyActivity.active,
    );
    expect(active.calorieKcal, 2191);
    expect(active.proteinG, female.proteinG);

    final NutritionTargets heavier = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 70,
      activity: DailyActivity.sedentary,
    );
    expect(heavier.proteinG, greaterThan(female.proteinG));
    expect(heavier.calorieKcal, greaterThan(female.calorieKcal));

    final NutritionTargets surplus = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 55,
      activity: DailyActivity.sedentary,
      goal: TrainingGoal.hypertrophy,
    );
    final NutritionTargets deficit = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 55,
      activity: DailyActivity.sedentary,
      goal: TrainingGoal.fatLoss,
    );
    expect(surplus.calorieKcal, greaterThan(female.calorieKcal));
    expect(deficit.calorieKcal, lessThan(female.calorieKcal));
    expect(deficit.proteinG, greaterThan(female.proteinG));

    final NutritionTargets overridden = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 165,
      weightKg: 55,
      explicitCalorieKcal: NutritionDefaults.calorieTargetKcal,
      explicitProteinG: NutritionDefaults.proteinTargetG,
    );
    expect(overridden.calorieKcal, female.calorieKcal);
    expect(overridden.proteinG, female.proteinG);
  });

  test('very small fat-loss estimates stay at the calorie floor', () {
    final NutritionTargets targets = NutritionTargetMath.resolve(
      sex: BiologicalSex.female,
      heightCm: 140,
      weightKg: 35,
      activity: DailyActivity.sedentary,
      goal: TrainingGoal.fatLoss,
    );
    expect(targets.calorieKcal, EnergyEstimate.minKcal);
  });
}
