import 'dart:convert';

import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';

final class ExerciseOverlay {
  const ExerciseOverlay({required this.exercises, required this.bodyParts});

  static const ExerciseOverlay empty = ExerciseOverlay(
    exercises: <CatalogExercise>[],
    bodyParts: <String, List<String>>{},
  );

  final List<CatalogExercise> exercises;
  final Map<String, List<String>> bodyParts;
}

ExerciseOverlay parseExercisePack(String raw) {
  final Object? decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const ContentPackFormatException(ContentJsonKeys.exercises);
  }
  final Object? list = decoded[ContentJsonKeys.exercises];
  if (list is! List) {
    throw const ContentPackFormatException(ContentJsonKeys.exercises);
  }
  final List<CatalogExercise> exercises = <CatalogExercise>[];
  final Map<String, List<String>> bodyParts = <String, List<String>>{};
  for (final Object? item in list) {
    if (item is! Map) {
      continue;
    }
    final Map<String, Object?> json = item.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    final CatalogExercise? exercise = _exerciseFromJson(json);
    if (exercise == null) {
      continue;
    }
    final List<String> parts = _bodyParts(json[ContentJsonKeys.bodyParts]);
    if (parts.isEmpty) {
      continue;
    }
    exercises.add(exercise);
    bodyParts[exercise.id] = parts;
  }
  return ExerciseOverlay(exercises: exercises, bodyParts: bodyParts);
}

ExerciseOverlay mergeExerciseOverlays(
  ExerciseOverlay base,
  ExerciseOverlay extra,
) {
  if (extra.exercises.isEmpty) {
    return base;
  }
  final List<CatalogExercise> order = List<CatalogExercise>.of(base.exercises);
  final Map<String, int> indexById = <String, int>{
    for (int i = 0; i < order.length; i++) order[i].id: i,
  };
  for (final CatalogExercise item in extra.exercises) {
    final int? index = indexById[item.id];
    if (index == null) {
      indexById[item.id] = order.length;
      order.add(item);
    } else {
      order[index] = item;
    }
  }
  final Map<String, List<String>> parts = <String, List<String>>{
    ...base.bodyParts,
  };
  for (final CatalogExercise item in extra.exercises) {
    final List<String>? next = extra.bodyParts[item.id];
    if (next != null && next.isNotEmpty) {
      parts[item.id] = next;
    }
  }
  return ExerciseOverlay(exercises: order, bodyParts: parts);
}

CatalogExercise? _exerciseFromJson(Map<String, Object?> json) {
  final Object? id = json[ContentJsonKeys.id];
  final Object? nameZh = json[ContentJsonKeys.nameZh];
  final Object? patternRaw = json[ContentJsonKeys.pattern];
  final Object? equipmentRaw = json[ContentJsonKeys.equipment];
  if (id is! String ||
      id.isEmpty ||
      nameZh is! String ||
      nameZh.trim().isEmpty ||
      patternRaw is! String ||
      equipmentRaw is! String) {
    return null;
  }
  final MovementPattern? pattern = _pattern(patternRaw);
  final EquipmentKind? equipment = _equipment(equipmentRaw);
  if (pattern == null || equipment == null) {
    return null;
  }
  final Object? nameEn = json[ContentJsonKeys.nameEn];
  final Object? sourceId = json[ContentJsonKeys.sourceId];
  return CatalogExercise(
    id: id,
    nameZh: nameZh.trim(),
    nameEn: nameEn is String ? nameEn.trim() : '',
    sourceId: sourceId is String ? sourceId.trim() : '',
    pattern: pattern,
    equipment: equipment,
  );
}

List<String> _bodyParts(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  final List<String> parts = <String>[];
  for (final Object? item in raw) {
    if (item is! String || !BodyPartIds.known.contains(item)) {
      continue;
    }
    if (!parts.contains(item)) {
      parts.add(item);
    }
  }
  return parts;
}

MovementPattern? _pattern(String raw) {
  for (final MovementPattern pattern in MovementPattern.values) {
    if (pattern.name == raw) {
      return pattern;
    }
  }
  return null;
}

EquipmentKind? _equipment(String raw) {
  for (final EquipmentKind equipment in EquipmentKind.values) {
    if (equipment.name == raw) {
      return equipment;
    }
  }
  return null;
}
