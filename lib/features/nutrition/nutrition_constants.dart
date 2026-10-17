import 'package:flutter/material.dart';

abstract final class NutritionCopy {
  static const String calorie = '热量';
  static const String protein = '蛋白';
  static const String carb = '碳水';
  static const String fat = '脂肪';
  static const String notYet = '还没记';
  static const String editGrams = '改克数';
  static const String deleteEntry = '删除这条';

  static String logInto(String mealLabel) => '记到$mealLabel';
}

abstract final class FoodAssetKeys {
  static const String id = 'id';
  static const String nameZh = 'nameZh';
  static const String source = 'source';
  static const String kcal = 'kcal';
  static const String proteinG = 'proteinG';
  static const String carbG = 'carbG';
  static const String fatG = 'fatG';
  static const String foods = 'foods';
}

abstract final class NutritionJsonKeys {
  static const String id = 'id';
  static const String loggedAt = 'loggedAt';
  static const String foodId = 'foodId';
  static const String nameZh = 'nameZh';
  static const String grams = 'grams';
  static const String meal = 'meal';
  static const String calorieTarget = 'calorieTargetKcal';
  static const String proteinTarget = 'proteinTargetG';
}

abstract final class NutritionDefaults {
  static const int calorieTargetKcal = 2000;
  static const int proteinTargetG = 120;
  static const double gramsPerReference = 100;
  static const double defaultLogGrams = 100;
}

/// Mifflin–St Jeor inputs. Age is not collected, so [referenceAgeYears] is the
/// adult reference used instead of a measured age.
abstract final class EnergyEstimate {
  static const int referenceAgeYears = 30;

  static const double weightCoefficient = 10;
  static const double heightCoefficient = 6.25;
  static const double ageCoefficient = 5;
  static const double maleBmrConstant = 5;
  static const double femaleBmrConstant = -161;

  static const double sedentaryActivityFactor = 1.2;
  static const double lightActivityFactor = 1.375;
  static const double moderateActivityFactor = 1.55;
  static const double activeActivityFactor = 1.725;

  static const double hypertrophyFactor = 1.1;
  static const double strengthFactor = 1;
  static const double fatLossFactor = 0.85;
  static const double maintenanceFactor = 1;

  static const double proteinGramsPerKg = 1.6;
  static const double hypertrophyProteinGramsPerKg = 1.8;
  static const double fatLossProteinGramsPerKg = 2;

  static const double fatEnergyFraction = 0.25;
  static const double kcalPerProteinG = 4;
  static const double kcalPerCarbG = 4;
  static const double kcalPerFatG = 9;

  static const int minKcal = 1200;
  static const int maxKcal = 4500;
  static const int minFatG = 35;
}

abstract final class MealNames {
  static const String breakfast = 'breakfast';
  static const String lunch = 'lunch';
  static const String dinner = 'dinner';
  static const String snack = 'snack';

  static const List<String> all = <String>[breakfast, lunch, dinner, snack];

  /// Home sections, matching the daily logging order.
  static const List<String> homeOrder = <String>[
    breakfast,
    lunch,
    snack,
    dinner,
  ];

  static IconData iconFor(String meal) {
    switch (meal) {
      case breakfast:
        return Icons.wb_sunny_outlined;
      case lunch:
        return Icons.restaurant_outlined;
      case dinner:
        return Icons.nights_stay_outlined;
      case snack:
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  static String labelZh(String meal) {
    switch (meal) {
      case breakfast:
        return '早餐';
      case lunch:
        return '午餐';
      case dinner:
        return '晚餐';
      case snack:
        return '加餐';
      default:
        return meal;
    }
  }
}
