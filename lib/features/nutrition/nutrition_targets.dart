import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/plan/plan_constants.dart';

final class NutritionTargets {
  const NutritionTargets({
    required this.calorieKcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final int calorieKcal;
  final int proteinG;
  final int carbG;
  final int fatG;
}

/// Calorie and macro targets from on-device body metrics.
/// Height and weight are required; otherwise the fixed defaults stay.
abstract final class NutritionTargetMath {
  static NutritionTargets resolve({
    BiologicalSex? sex,
    double? heightCm,
    double? weightKg,
    DailyActivity? activity,
    TrainingGoal? goal,
    int? explicitCalorieKcal,
    int? explicitProteinG,
  }) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return _fromAnchors(
        calorieKcal: _positiveOr(
          explicitCalorieKcal,
          NutritionDefaults.calorieTargetKcal,
        ),
        proteinG: _positiveOr(
          explicitProteinG,
          NutritionDefaults.proteinTargetG,
        ),
      );
    }
    return _fromAnchors(
      calorieKcal: _calorieKcal(
        sex: sex,
        heightCm: heightCm,
        weightKg: weightKg,
        activity: activity,
        goal: goal,
      ),
      proteinG: _proteinG(weightKg: weightKg, goal: goal),
    );
  }

  static int _calorieKcal({
    required BiologicalSex? sex,
    required double heightCm,
    required double weightKg,
    required DailyActivity? activity,
    required TrainingGoal? goal,
  }) {
    final double bmr =
        EnergyEstimate.weightCoefficient * weightKg +
        EnergyEstimate.heightCoefficient * heightCm -
        EnergyEstimate.ageCoefficient * EnergyEstimate.referenceAgeYears +
        _sexConstant(sex);
    final double raw = bmr * _activityFactor(activity) * _goalFactor(goal);
    return raw.round().clamp(EnergyEstimate.minKcal, EnergyEstimate.maxKcal);
  }

  static int _proteinG({
    required double weightKg,
    required TrainingGoal? goal,
  }) {
    final double grams = weightKg * _proteinPerKg(goal);
    final int rounded = grams.round();
    if (rounded < 1) {
      return 1;
    }
    return rounded;
  }

  static NutritionTargets _fromAnchors({
    required int calorieKcal,
    required int proteinG,
  }) {
    final int fatG = _fatG(calorieKcal);
    final int carbG = _carbG(
      calorieKcal: calorieKcal,
      proteinG: proteinG,
      fatG: fatG,
    );
    return NutritionTargets(
      calorieKcal: calorieKcal,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
    );
  }

  static int _fatG(int calorieKcal) {
    final int raw =
        (calorieKcal *
                EnergyEstimate.fatEnergyFraction /
                EnergyEstimate.kcalPerFatG)
            .round();
    if (raw < EnergyEstimate.minFatG) {
      return EnergyEstimate.minFatG;
    }
    return raw;
  }

  static int _carbG({
    required int calorieKcal,
    required int proteinG,
    required int fatG,
  }) {
    final double used =
        proteinG * EnergyEstimate.kcalPerProteinG +
        fatG * EnergyEstimate.kcalPerFatG;
    final double remain = calorieKcal - used;
    if (remain <= 0) {
      return 0;
    }
    return (remain / EnergyEstimate.kcalPerCarbG).round();
  }

  static double _sexConstant(BiologicalSex? sex) {
    switch (sex) {
      case BiologicalSex.male:
        return EnergyEstimate.maleBmrConstant;
      case BiologicalSex.female:
        return EnergyEstimate.femaleBmrConstant;
      case null:
        return (EnergyEstimate.maleBmrConstant +
                EnergyEstimate.femaleBmrConstant) /
            2;
    }
  }

  static double _activityFactor(DailyActivity? activity) {
    switch (activity) {
      case DailyActivity.light:
        return EnergyEstimate.lightActivityFactor;
      case DailyActivity.moderate:
        return EnergyEstimate.moderateActivityFactor;
      case DailyActivity.active:
        return EnergyEstimate.activeActivityFactor;
      case DailyActivity.sedentary:
      case null:
        return EnergyEstimate.sedentaryActivityFactor;
    }
  }

  static double _goalFactor(TrainingGoal? goal) {
    switch (goal) {
      case TrainingGoal.hypertrophy:
        return EnergyEstimate.hypertrophyFactor;
      case TrainingGoal.strength:
        return EnergyEstimate.strengthFactor;
      case TrainingGoal.fatLoss:
        return EnergyEstimate.fatLossFactor;
      case null:
        return EnergyEstimate.maintenanceFactor;
    }
  }

  static double _proteinPerKg(TrainingGoal? goal) {
    switch (goal) {
      case TrainingGoal.hypertrophy:
        return EnergyEstimate.hypertrophyProteinGramsPerKg;
      case TrainingGoal.fatLoss:
        return EnergyEstimate.fatLossProteinGramsPerKg;
      case TrainingGoal.strength:
      case null:
        return EnergyEstimate.proteinGramsPerKg;
    }
  }

  static int _positiveOr(int? value, int fallback) {
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }
}
