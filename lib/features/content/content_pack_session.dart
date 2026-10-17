import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_pack_store.dart';
import 'package:curvefree/features/content/content_pack_store_factory.dart';
import 'package:curvefree/features/content/exercise_pack.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:flutter/services.dart';

final class ContentSnapshot {
  const ContentSnapshot({
    required this.manifest,
    required this.installed,
    required this.foods,
    required this.exerciseOverlay,
    required this.attribution,
  });

  final ContentManifest manifest;
  final bool installed;
  final FoodCatalog foods;
  final ExerciseOverlay exerciseOverlay;
  final String attribution;
}

final class ContentPackLoader {
  ContentPackLoader({ContentPackStore? store})
    : _store = store ?? createContentPackStore();

  final ContentPackStore _store;

  Future<ContentSnapshot> load() async {
    final ContentManifest bundled = ContentManifest.parse(
      await rootBundle.loadString(ContentAssets.manifest),
    );
    final ExerciseOverlay exercises = parseExercisePack(
      await rootBundle.loadString(ContentAssets.exercises),
    );
    final FoodCatalog foods = FoodCatalog.parse(
      await rootBundle.loadString(ContentAssets.foods),
    );
    final String attribution = await rootBundle.loadString(
      ContentAssets.attribution,
    );
    final String? root = await _store.applicationRootPath();
    if (root != null) {
      final VerifiedPack? pack = await _store.readInstalled(root);
      if (pack != null) {
        final ContentSnapshot? overlaid = _overlayInstalled(
          pack: pack,
          exercises: exercises,
          foods: foods,
          attribution: attribution,
        );
        if (overlaid != null) {
          return overlaid;
        }
      }
    }
    return ContentSnapshot(
      manifest: bundled,
      installed: false,
      foods: foods,
      exerciseOverlay: exercises,
      attribution: attribution,
    );
  }

  ContentSnapshot? _overlayInstalled({
    required VerifiedPack pack,
    required ExerciseOverlay exercises,
    required FoodCatalog foods,
    required String attribution,
  }) {
    try {
      return ContentSnapshot(
        manifest: pack.manifest,
        installed: true,
        foods: foods.overlay(FoodCatalog.parse(pack.foodsRaw)),
        exerciseOverlay: mergeExerciseOverlays(
          exercises,
          parseExercisePack(pack.exercisesRaw),
        ),
        attribution: attribution,
      );
    } on Object {
      return null;
    }
  }
}

abstract final class ContentPackSession {
  static Future<ContentSnapshot>? _pending;

  static Future<ContentSnapshot> ensureLoaded() {
    return _pending ??= _load();
  }

  static Future<ContentSnapshot> reload() {
    _pending = null;
    return ensureLoaded();
  }

  static void invalidate() {
    _pending = null;
    ExerciseCatalog.clearOverlay();
  }

  static Future<ContentSnapshot> _load() async {
    try {
      final ContentSnapshot snapshot = await ContentPackLoader().load();
      ExerciseCatalog.applyOverlay(
        exercises: snapshot.exerciseOverlay.exercises,
        bodyParts: snapshot.exerciseOverlay.bodyParts,
      );
      return snapshot;
    } on Object {
      _pending = null;
      rethrow;
    }
  }
}
