import 'dart:async';

import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/home/widgets/today_header.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/nutrition/nutrition_math.dart';
import 'package:curvefree/features/nutrition/nutrition_providers.dart';
import 'package:curvefree/features/nutrition/pages/food_picker_page.dart';
import 'package:curvefree/features/nutrition/widgets/nutrition_home_sections.dart';
import 'package:curvefree/features/training/widgets/numeric_keypad_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FoodCatalog> catalogAsync = ref.watch(foodCatalogProvider);
    final AsyncValue<List<FoodLogEntry>> logsAsync = ref.watch(
      foodLogsProvider,
    );
    final NutritionTargets targets = ref.watch(nutritionTargetsProvider);

    return Scaffold(
      key: const Key('nutri_home'),
      body: SafeArea(
        child: catalogAsync.when(
          loading: () => const Center(child: Text('正在读取食物库…')),
          error: (Object error, StackTrace stack) =>
              Center(child: Text('食物库失败：$error')),
          data: (FoodCatalog catalog) {
            return logsAsync.when(
              loading: () => const Center(child: Text('正在读取饮食记录…')),
              error: (Object error, StackTrace stack) =>
                  Center(child: Text('读取失败：$error')),
              data: (List<FoodLogEntry> logs) {
                return _NutritionHome(
                  catalog: catalog,
                  logs: logs,
                  targets: targets,
                  onAdd: (String meal) => _addFood(context, ref, catalog, meal),
                  onEdit: (FoodLogEntry entry) =>
                      _editGrams(context, ref, entry),
                  onDelete: (FoodLogEntry entry) {
                    unawaited(
                      ref.read(foodLogsProvider.notifier).delete(entry.id),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _addFood(
    BuildContext context,
    WidgetRef ref,
    FoodCatalog catalog,
    String meal,
  ) async {
    final FoodItem? food = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute<FoodItem>(
        builder: (_) => FoodPickerPage(catalog: catalog, meal: meal),
      ),
    );
    if (food == null || !context.mounted) {
      return;
    }
    final double? grams = await NumericKeypadSheet.show(
      context: context,
      kind: NumericFieldKind.weightKg,
      initial: NutritionDefaults.defaultLogGrams,
      title: AppStrings.gramsLabel,
    );
    if (grams == null || grams <= 0 || !context.mounted) {
      return;
    }
    final FoodLogEntry entry = ref
        .read(foodLogRepositoryProvider)
        .create(food: food, grams: grams, meal: meal);
    await ref.read(foodLogsProvider.notifier).add(entry);
  }

  Future<void> _editGrams(
    BuildContext context,
    WidgetRef ref,
    FoodLogEntry entry,
  ) async {
    final double? grams = await NumericKeypadSheet.show(
      context: context,
      kind: NumericFieldKind.weightKg,
      initial: entry.grams,
      title: AppStrings.gramsLabel,
    );
    if (grams == null || grams <= 0 || !context.mounted) {
      return;
    }
    await ref
        .read(foodLogsProvider.notifier)
        .replace(entry.copyWith(grams: grams));
  }
}

class _NutritionHome extends StatelessWidget {
  const _NutritionHome({
    required this.catalog,
    required this.logs,
    required this.targets,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodCatalog catalog;
  final List<FoodLogEntry> logs;
  final NutritionTargets targets;
  final ValueChanged<String> onAdd;
  final ValueChanged<FoodLogEntry> onEdit;
  final ValueChanged<FoodLogEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final MacroTotals totals = NutritionMath.dayTotals(
      logs: logs,
      day: today,
      foodById: catalog.byId,
    );
    final List<FoodLogEntry> todayLogs = logs
        .where(
          (FoodLogEntry entry) =>
              NutritionMath.isSameDay(entry.loggedAt, today),
        )
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              AppStrings.nutrition,
              key: const Key('nutri_title'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            Text(
              formatTodayDate(today),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        NutritionMacroGrid(totals: totals, targets: targets),
        const SizedBox(height: AppSpacing.sm),
        NutritionAssistNote(catalog: catalog, totals: totals, targets: targets),
        const SizedBox(height: AppSpacing.md),
        for (final String meal in MealNames.homeOrder)
          NutritionMealSection(
            meal: meal,
            entries: todayLogs
                .where((FoodLogEntry entry) => entry.meal == meal)
                .toList(growable: false),
            catalog: catalog,
            onAdd: () => onAdd(meal),
            onEdit: onEdit,
            onDelete: onDelete,
          ),
      ],
    );
  }
}
