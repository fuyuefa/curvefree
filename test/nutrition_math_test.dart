import 'dart:io';

import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/nutrition_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foods.json parses and chicken scales to 200g', () {
    final raw = File('assets/data/foods.json').readAsStringSync();
    final catalog = FoodCatalog.parse(raw);
    expect(catalog.items, isNotEmpty);
    final chicken = catalog.byId('chicken_breast');
    expect(chicken, isNotNull);
    final macros = NutritionMath.macrosFor(chicken!, 200);
    expect(macros.proteinG, closeTo(62, 0.01));
  });

  test('protein fill suggestion uses whey density', () {
    final raw = File('assets/data/foods.json').readAsStringSync();
    final catalog = FoodCatalog.parse(raw);
    final whey = catalog.byId('whey')!;
    final grams = NutritionMath.gramsToFillProtein(
      food: whey,
      remainingProteinG: 30,
    );
    expect(grams, closeTo(40, 0.5));
  });

  test('protein gap copy has no sentence-final period', () {
    final String line = proteinGapLine(
      remainingProteinG: 12.4,
      foodNameZh: '鸡胸肉',
      grams: 80.2,
    );
    expect(line, '蛋白还差 12 g，可记 80 g 鸡胸肉');
    expect(line.contains('。'), isFalse);
  });
}
