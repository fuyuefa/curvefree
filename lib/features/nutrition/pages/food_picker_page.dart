import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:flutter/material.dart';

class FoodPickerPage extends StatefulWidget {
  const FoodPickerPage({super.key, required this.catalog, required this.meal});

  final FoodCatalog catalog;
  final String meal;

  @override
  State<FoodPickerPage> createState() => _FoodPickerPageState();
}

class _FoodPickerPageState extends State<FoodPickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<FoodItem> items = widget.catalog.search(_query);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.pickFood)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                NutritionCopy.logInto(MealNames.labelZh(widget.meal)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              key: const Key('field_food_search'),
              decoration: const InputDecoration(
                hintText: AppStrings.searchFoodHint,
              ),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final FoodItem food = items[index];
                return ListTile(
                  title: Text(food.nameZh),
                  subtitle: Text(
                    '${food.kcal.round()} kcal · 蛋白 ${food.proteinG} g / 100g',
                  ),
                  onTap: () => Navigator.pop(context, food),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
