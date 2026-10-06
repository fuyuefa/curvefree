import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/nutrition/nutrition_math.dart';
import 'package:curvefree/features/nutrition/nutrition_providers.dart';
import 'package:curvefree/features/training/widgets/numeric_keypad_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(foodCatalogProvider);
    final logsAsync = ref.watch(foodLogsProvider);
    final targets = ref.watch(nutritionTargetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.nutritionLogTitle)),
      floatingActionButton: catalogAsync.maybeWhen(
        data: (FoodCatalog catalog) => FloatingActionButton.extended(
          key: const Key('btn_add_food'),
          onPressed: () => _addFood(context, ref, catalog),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.addFood),
        ),
        orElse: () => null,
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: Text('正在读取食物库…')),
        error: (Object error, StackTrace stack) =>
            Center(child: Text('食物库失败：$error')),
        data: (FoodCatalog catalog) {
          return logsAsync.when(
            loading: () => const Center(child: Text('正在读取饮食记录…')),
            error: (Object error, StackTrace stack) =>
                Center(child: Text('读取失败：$error')),
            data: (List<FoodLogEntry> logs) {
              final today = DateTime.now();
              final totals = NutritionMath.dayTotals(
                logs: logs,
                day: today,
                foodById: catalog.byId,
              );
              final todayLogs = logs
                  .where(
                    (FoodLogEntry e) =>
                        NutritionMath.isSameDay(e.loggedAt, today),
                  )
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  96,
                ),
                children: [
                  _SummaryCard(totals: totals, targets: targets),
                  const SizedBox(height: AppSpacing.md),
                  _AssistCard(
                    catalog: catalog,
                    totals: totals,
                    targets: targets,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('今日明细', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (todayLogs.isEmpty) const Text(AppStrings.emptyFoodLogs),
                  for (final FoodLogEntry entry in todayLogs)
                    _LogTile(
                      entry: entry,
                      onDelete: () =>
                          ref.read(foodLogsProvider.notifier).delete(entry.id),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addFood(
    BuildContext context,
    WidgetRef ref,
    FoodCatalog catalog,
  ) async {
    final food = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute<FoodItem>(
        builder: (_) => _FoodPickerPage(catalog: catalog),
      ),
    );
    if (food == null || !context.mounted) {
      return;
    }
    final grams = await NumericKeypadSheet.show(
      context: context,
      kind: NumericFieldKind.weightKg,
      initial: NutritionDefaults.defaultLogGrams,
      title: AppStrings.gramsLabel,
    );
    if (grams == null || grams <= 0 || !context.mounted) {
      return;
    }
    final entry = ref
        .read(foodLogRepositoryProvider)
        .create(food: food, grams: grams, meal: MealNames.snack);
    await ref.read(foodLogsProvider.notifier).add(entry);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals, required this.targets});

  final MacroTotals totals;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.todayMacros,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${totals.kcal.round()} / ${targets.calorieKcal} kcal',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            '蛋白 ${totals.proteinG.toStringAsFixed(0)} / ${targets.proteinG} g',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '碳 ${totals.carbG.toStringAsFixed(0)} g · 脂 ${totals.fatG.toStringAsFixed(0)} g',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AssistCard extends StatelessWidget {
  const _AssistCard({
    required this.catalog,
    required this.totals,
    required this.targets,
  });

  final FoodCatalog catalog;
  final MacroTotals totals;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final remainingProtein = targets.proteinG - totals.proteinG;
    final remainingKcal = targets.calorieKcal - totals.kcal;
    final proteinFood = catalog.highestProtein();
    String suggestion = AppStrings.dietAssistMet;
    if (remainingProtein > 0 && proteinFood != null) {
      final grams = NutritionMath.gramsToFillProtein(
        food: proteinFood,
        remainingProteinG: remainingProtein,
      );
      suggestion =
          '蛋白还差 ${remainingProtein.toStringAsFixed(0)} g。可记 ${grams.round()} g ${proteinFood.nameZh}。';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.dietAssistTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
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

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.onDelete});

  final FoodLogEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.nameZh),
      subtitle: Text(
        '${MealNames.labelZh(entry.meal)} · ${entry.grams.round()} g',
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

class _FoodPickerPage extends StatefulWidget {
  const _FoodPickerPage({required this.catalog});

  final FoodCatalog catalog;

  @override
  State<_FoodPickerPage> createState() => _FoodPickerPageState();
}

class _FoodPickerPageState extends State<_FoodPickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.catalog.search(_query);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.pickFood)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              key: const Key('field_food_search'),
              decoration: const InputDecoration(
                hintText: AppStrings.searchFoodHint,
                filled: true,
                fillColor: Color(AppColors.surface),
                border: InputBorder.none,
              ),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final food = items[index];
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
