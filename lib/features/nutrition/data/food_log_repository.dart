import 'package:curvefree/core/ids/entity_ids.dart';
import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';

abstract final class FoodLogIdPrefix {
  static const String entry = 'f';
}

final class FoodLogRepository {
  const FoodLogRepository(this._store);

  final LocalStore _store;

  Future<List<FoodLogEntry>> list() async {
    final snapshot = await _store.read();
    return snapshot.foodLogs.map(FoodLogEntry.fromJson).toList(growable: false);
  }

  Future<void> add(FoodLogEntry entry) async {
    final snapshot = await _store.read();
    final next = <Map<String, Object?>>[entry.toJson(), ...snapshot.foodLogs];
    await _store.write(snapshot.copyWith(foodLogs: next));
  }

  Future<void> delete(String id) async {
    final snapshot = await _store.read();
    final next = snapshot.foodLogs
        .where(
          (Map<String, Object?> item) =>
              item[NutritionJsonKeys.id]?.toString() != id,
        )
        .toList(growable: false);
    await _store.write(snapshot.copyWith(foodLogs: next));
  }

  FoodLogEntry create({
    required FoodItem food,
    required double grams,
    required String meal,
    DateTime? at,
  }) {
    return FoodLogEntry(
      id: EntityIds.next(FoodLogIdPrefix.entry),
      loggedAt: at ?? DateTime.now(),
      foodId: food.id,
      nameZh: food.nameZh,
      grams: grams,
      meal: meal,
    );
  }
}
