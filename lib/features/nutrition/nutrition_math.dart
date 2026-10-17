import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';

abstract final class NutritionMath {
  static MacroTotals macrosFor(FoodItem food, double grams) {
    return MacroTotals(
      kcal: food.scale(food.kcal, grams),
      proteinG: food.scale(food.proteinG, grams),
      carbG: food.scale(food.carbG, grams),
      fatG: food.scale(food.fatG, grams),
    );
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static MacroTotals dayTotals({
    required List<FoodLogEntry> logs,
    required DateTime day,
    required FoodItem? Function(String id) foodById,
  }) {
    var total = MacroTotals.zero;
    for (final FoodLogEntry entry in logs) {
      if (!isSameDay(entry.loggedAt, day)) {
        continue;
      }
      final food = foodById(entry.foodId);
      if (food == null) {
        continue;
      }
      total += macrosFor(food, entry.grams);
    }
    return total;
  }

  /// Grams of [food] needed to close remaining protein, capped by default log size * 4.
  static double gramsToFillProtein({
    required FoodItem food,
    required double remainingProteinG,
  }) {
    if (food.proteinG <= 0 || remainingProteinG <= 0) {
      return 0;
    }
    final grams =
        remainingProteinG * NutritionDefaults.gramsPerReference / food.proteinG;
    const maxGrams = NutritionDefaults.defaultLogGrams * 4;
    if (grams > maxGrams) {
      return maxGrams;
    }
    return grams;
  }
}

/// Soft gap line. Sentence-final full-width periods stay off user copy.
String proteinGapLine({
  required double remainingProteinG,
  required String foodNameZh,
  required double grams,
}) {
  final int protein = remainingProteinG.round();
  final int portion = grams.round();
  return '蛋白还差 $protein g，可记 $portion g $foodNameZh';
}
