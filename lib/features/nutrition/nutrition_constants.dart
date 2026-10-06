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
