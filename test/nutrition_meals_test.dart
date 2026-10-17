import 'package:curvefree/app/theme/app_theme.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/nutrition/widgets/nutrition_home_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one meal lists every food logged into it', (
    WidgetTester tester,
  ) async {
    final FoodCatalog catalog = FoodCatalog(<FoodItem>[
      const FoodItem(
        id: 'egg',
        nameZh: '鸡蛋',
        source: 'estimate',
        kcal: 143,
        proteinG: 13,
        carbG: 1,
        fatG: 10,
      ),
      const FoodItem(
        id: 'rice',
        nameZh: '米饭',
        source: 'estimate',
        kcal: 130,
        proteinG: 2.7,
        carbG: 28,
        fatG: 0.3,
      ),
    ]);
    final DateTime at = DateTime(2026, 10, 17, 8);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCurveFreeTheme(Brightness.light),
        home: Scaffold(
          body: NutritionMealSection(
            meal: MealNames.breakfast,
            entries: <FoodLogEntry>[
              FoodLogEntry(
                id: 'a',
                loggedAt: at,
                foodId: 'egg',
                nameZh: '鸡蛋',
                grams: 50,
                meal: MealNames.breakfast,
              ),
              FoodLogEntry(
                id: 'b',
                loggedAt: at.add(const Duration(minutes: 5)),
                foodId: 'rice',
                nameZh: '米饭',
                grams: 150,
                meal: MealNames.breakfast,
              ),
            ],
            catalog: catalog,
            onAdd: () {},
            onEdit: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('鸡蛋'), findsOneWidget);
    expect(find.text('米饭'), findsOneWidget);
    expect(find.textContaining('50'), findsWidgets);
    expect(find.textContaining('150'), findsWidgets);
  });
}
