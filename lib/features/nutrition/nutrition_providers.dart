import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/data/food_log_repository.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final foodCatalogProvider = FutureProvider<FoodCatalog>((Ref ref) {
  return FoodCatalog.loadFromBundle();
});

final foodLogRepositoryProvider = Provider<FoodLogRepository>((Ref ref) {
  return FoodLogRepository(ref.watch(localStoreProvider));
});

final foodLogsProvider =
    AsyncNotifierProvider<FoodLogsController, List<FoodLogEntry>>(
      FoodLogsController.new,
    );

final class FoodLogsController extends AsyncNotifier<List<FoodLogEntry>> {
  @override
  Future<List<FoodLogEntry>> build() {
    return ref.read(foodLogRepositoryProvider).list();
  }

  Future<void> _sync() async {
    await ref.read(localStoreSnapshotProvider.notifier).reload();
    state = AsyncData(await ref.read(foodLogRepositoryProvider).list());
  }

  Future<void> add(FoodLogEntry entry) async {
    await ref.read(foodLogRepositoryProvider).add(entry);
    await _sync();
  }

  Future<void> replace(FoodLogEntry entry) async {
    await ref.read(foodLogRepositoryProvider).update(entry);
    await _sync();
  }

  Future<void> delete(String id) async {
    await ref.read(foodLogRepositoryProvider).delete(id);
    await _sync();
  }
}

final class NutritionTargets {
  const NutritionTargets({required this.calorieKcal, required this.proteinG});

  final int calorieKcal;
  final int proteinG;
}

final nutritionTargetsProvider = Provider<NutritionTargets>((Ref ref) {
  final settings = ref.watch(localStoreSnapshotProvider).valueOrNull?.settings;
  return NutritionTargets(
    calorieKcal: _asInt(
      settings?[NutritionJsonKeys.calorieTarget],
      NutritionDefaults.calorieTargetKcal,
    ),
    proteinG: _asInt(
      settings?[NutritionJsonKeys.proteinTarget],
      NutritionDefaults.proteinTargetG,
    ),
  );
});

int _asInt(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
