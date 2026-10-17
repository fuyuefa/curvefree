import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/data/food_log_repository.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/nutrition/nutrition_targets.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
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

final nutritionTargetsProvider = Provider<NutritionTargets>((Ref ref) {
  final Map<String, Object?> settings =
      ref.watch(localStoreSnapshotProvider).valueOrNull?.settings ??
      const <String, Object?>{};
  final UserProfile profile = UserProfile.fromSettings(settings);
  return NutritionTargetMath.resolve(
    sex: profile.sex,
    heightCm: profile.heightCm,
    weightKg: profile.weightKg,
    activity: profile.activity,
    goal: profile.goal,
    explicitCalorieKcal: _optionalInt(
      settings[NutritionJsonKeys.calorieTarget],
    ),
    explicitProteinG: _optionalInt(settings[NutritionJsonKeys.proteinTarget]),
  );
});

int? _optionalInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value.toString());
}
