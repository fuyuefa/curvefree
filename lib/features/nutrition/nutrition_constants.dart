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
