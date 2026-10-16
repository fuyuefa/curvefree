import 'package:curvefree/features/nutrition/nutrition_constants.dart';

final class FoodItem {
  const FoodItem({
    required this.id,
    required this.nameZh,
    required this.source,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final String id;
  final String nameZh;
  final String source;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  double scale(double per100, double grams) =>
      per100 * grams / NutritionDefaults.gramsPerReference;

  factory FoodItem.fromJson(Map<String, Object?> json) {
    return FoodItem(
      id: json[FoodAssetKeys.id]?.toString() ?? '',
      nameZh: json[FoodAssetKeys.nameZh]?.toString() ?? '',
      source: json[FoodAssetKeys.source]?.toString() ?? 'estimate',
      kcal: _asDouble(json[FoodAssetKeys.kcal]),
      proteinG: _asDouble(json[FoodAssetKeys.proteinG]),
      carbG: _asDouble(json[FoodAssetKeys.carbG]),
      fatG: _asDouble(json[FoodAssetKeys.fatG]),
    );
  }
}

final class FoodLogEntry {
  const FoodLogEntry({
    required this.id,
    required this.loggedAt,
    required this.foodId,
    required this.nameZh,
    required this.grams,
    required this.meal,
  });

  final String id;
  final DateTime loggedAt;
  final String foodId;
  final String nameZh;
  final double grams;
  final String meal;

  factory FoodLogEntry.fromJson(Map<String, Object?> json) {
    return FoodLogEntry(
      id: json[NutritionJsonKeys.id]?.toString() ?? '',
      loggedAt:
          DateTime.tryParse(
            json[NutritionJsonKeys.loggedAt]?.toString() ?? '',
          ) ??
          DateTime.now(),
      foodId: json[NutritionJsonKeys.foodId]?.toString() ?? '',
      nameZh: json[NutritionJsonKeys.nameZh]?.toString() ?? '',
      grams: _asDouble(json[NutritionJsonKeys.grams]),
      meal: json[NutritionJsonKeys.meal]?.toString() ?? MealNames.snack,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      NutritionJsonKeys.id: id,
      NutritionJsonKeys.loggedAt: loggedAt.toIso8601String(),
      NutritionJsonKeys.foodId: foodId,
      NutritionJsonKeys.nameZh: nameZh,
      NutritionJsonKeys.grams: grams,
      NutritionJsonKeys.meal: meal,
    };
  }

  FoodLogEntry copyWith({double? grams, String? meal}) {
    return FoodLogEntry(
      id: id,
      loggedAt: loggedAt,
      foodId: foodId,
      nameZh: nameZh,
      grams: grams ?? this.grams,
      meal: meal ?? this.meal,
    );
  }
}

final class MacroTotals {
  const MacroTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  static const MacroTotals zero = MacroTotals(
    kcal: 0,
    proteinG: 0,
    carbG: 0,
    fatG: 0,
  );

  MacroTotals operator +(MacroTotals other) {
    return MacroTotals(
      kcal: kcal + other.kcal,
      proteinG: proteinG + other.proteinG,
      carbG: carbG + other.carbG,
      fatG: fatG + other.fatG,
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
