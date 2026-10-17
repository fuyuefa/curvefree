import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/nutrition/nutrition_math.dart';
import 'package:curvefree/features/nutrition/nutrition_targets.dart';
import 'package:flutter/material.dart';

class NutritionMacroGrid extends StatelessWidget {
  const NutritionMacroGrid({
    super.key,
    required this.totals,
    required this.targets,
  });

  final MacroTotals totals;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MacroCard(
                label: NutritionCopy.calorie,
                value: '${totals.kcal.round()}',
                detail: '/ ${targets.calorieKcal} kcal',
                fraction: _fraction(totals.kcal, targets.calorieKcal),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MacroCard(
                label: NutritionCopy.protein,
                value: '${totals.proteinG.round()}',
                detail: '/ ${targets.proteinG} g',
                fraction: _fraction(totals.proteinG, targets.proteinG),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _MacroCard(
                label: NutritionCopy.carb,
                value: '${totals.carbG.round()}',
                detail: '/ ${targets.carbG} g',
                fraction: _fraction(totals.carbG, targets.carbG),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MacroCard(
                label: NutritionCopy.fat,
                value: '${totals.fatG.round()}',
                detail: '/ ${targets.fatG} g',
                fraction: _fraction(totals.fatG, targets.fatG),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NutritionAssistNote extends StatelessWidget {
  const NutritionAssistNote({
    super.key,
    required this.catalog,
    required this.totals,
    required this.targets,
  });

  final FoodCatalog catalog;
  final MacroTotals totals;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final double remainingProtein = targets.proteinG - totals.proteinG;
    final double remainingKcal = targets.calorieKcal - totals.kcal;
    final FoodItem? proteinFood = catalog.highestProtein();
    String suggestion = AppStrings.dietAssistMet;
    if (remainingProtein > 0 && proteinFood != null) {
      final double grams = NutritionMath.gramsToFillProtein(
        food: proteinFood,
        remainingProteinG: remainingProtein,
      );
      suggestion = proteinGapLine(
        remainingProteinG: remainingProtein,
        foodNameZh: proteinFood.nameZh,
        grams: grams,
      );
    }
    final CurveColors colors = CurveColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors, color: colors.muted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.dietAssistTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '热量剩余 ${remainingKcal.round()} kcal',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(suggestion, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class NutritionMealSection extends StatelessWidget {
  const NutritionMealSection({
    super.key,
    required this.meal,
    required this.entries,
    required this.catalog,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String meal;
  final List<FoodLogEntry> entries;
  final FoodCatalog catalog;
  final VoidCallback onAdd;
  final ValueChanged<FoodLogEntry> onEdit;
  final ValueChanged<FoodLogEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Container(
      key: Key('nutri_meal_$meal'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: curveSurfaceDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(MealNames.iconFor(meal), color: colors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  MealNames.labelZh(meal),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: Key('btn_add_meal_$meal'),
                tooltip: AppStrings.addFood,
                onPressed: onAdd,
                icon: Icon(Icons.add, color: colors.primary),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xxs,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                NutritionCopy.notYet,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final FoodLogEntry entry in entries)
              _FoodRow(
                entry: entry,
                detail: _detail(entry),
                onEdit: () => onEdit(entry),
                onDelete: () => onDelete(entry),
              ),
        ],
      ),
    );
  }

  String _detail(FoodLogEntry entry) {
    final FoodItem? food = catalog.byId(entry.foodId);
    final String grams = '${entry.grams.round()} ${AppStrings.gramsLabel}';
    if (food == null) {
      return grams;
    }
    final MacroTotals macros = NutritionMath.macrosFor(food, entry.grams);
    return '$grams · ${macros.kcal.round()} kcal';
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.entry,
    required this.detail,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodLogEntry entry;
  final String detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.nameZh,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            key: Key('btn_edit_grams_${entry.id}'),
            tooltip: NutritionCopy.editGrams,
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
          ),
          IconButton(
            key: Key('btn_delete_food_${entry.id}'),
            tooltip: NutritionCopy.deleteEntry,
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.detail,
    this.fraction,
  });

  final String label;
  final String value;
  final String detail;
  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final double? progress = fraction;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(detail, style: Theme.of(context).textTheme.labelSmall),
          if (progress != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.chip),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppLayout.progressBarHeight,
                backgroundColor: colors.muted,
                color: colors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double _fraction(double current, int target) {
  if (target <= 0) {
    return 0;
  }
  final double raw = current / target;
  if (raw < 0) {
    return 0;
  }
  if (raw > 1) {
    return 1;
  }
  return raw;
}
