import 'dart:convert';

import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:flutter/services.dart';

final class FoodCatalog {
  FoodCatalog(this.items);

  final List<FoodItem> items;

  static const String assetPath = 'assets/content/foods.json';

  static Future<FoodCatalog> loadFromBundle() async {
    final raw = await rootBundle.loadString(assetPath);
    return parse(raw);
  }

  static FoodCatalog parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return FoodCatalog(const <FoodItem>[]);
    }
    final foods = decoded[FoodAssetKeys.foods];
    if (foods is! List) {
      return FoodCatalog(const <FoodItem>[]);
    }
    final items = foods
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> item) => FoodItem.fromJson(
            item.map(
              (Object? key, Object? value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
    return FoodCatalog(items);
  }

  List<FoodItem> search(String query) {
    final needle = query.trim();
    if (needle.isEmpty) {
      return items;
    }
    final String lower = needle.toLowerCase();
    return items
        .where(
          (FoodItem item) =>
              item.nameZh.contains(needle) ||
              item.nameEn.toLowerCase().contains(lower),
        )
        .toList(growable: false);
  }

  FoodItem? byId(String id) {
    for (final FoodItem item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  FoodCatalog overlay(FoodCatalog extra) {
    if (extra.items.isEmpty) {
      return this;
    }
    final Map<String, FoodItem> byId = <String, FoodItem>{
      for (final FoodItem item in items) item.id: item,
    };
    final List<FoodItem> appended = <FoodItem>[];
    for (final FoodItem item in extra.items) {
      if (byId.containsKey(item.id)) {
        byId[item.id] = item;
      } else {
        appended.add(item);
      }
    }
    return FoodCatalog(<FoodItem>[
      for (final FoodItem item in items) byId[item.id]!,
      ...appended,
    ]);
  }

  FoodItem? highestProtein() {
    if (items.isEmpty) {
      return null;
    }
    return items.reduce(
      (FoodItem a, FoodItem b) => a.proteinG >= b.proteinG ? a : b,
    );
  }
}
