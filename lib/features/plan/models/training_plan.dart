import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:curvefree/features/training/models/workout_models.dart';

final class PlannedItem {
  const PlannedItem({
    required this.catalogId,
    required this.nameZh,
    required this.sets,
    required this.reps,
  });

  final String catalogId;
  final String nameZh;
  final int sets;
  final int reps;

  PlannedItem copyWith({int? sets, int? reps}) {
    return PlannedItem(
      catalogId: catalogId,
      nameZh: nameZh,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
    );
  }

  factory PlannedItem.fromJson(Map<String, Object?> json) {
    return PlannedItem(
      catalogId: json[PlanJsonKeys.catalogId]?.toString() ?? '',
      nameZh: json[PlanJsonKeys.nameZh]?.toString() ?? '',
      sets: _asInt(json[PlanJsonKeys.sets], SetPrescriptions.hypertrophySets),
      reps: _asInt(json[PlanJsonKeys.reps], SetPrescriptions.hypertrophyReps),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      PlanJsonKeys.catalogId: catalogId,
      PlanJsonKeys.nameZh: nameZh,
      PlanJsonKeys.sets: sets,
      PlanJsonKeys.reps: reps,
    };
  }
}

final class PlannedSession {
  const PlannedSession({
    required this.weekday,
    required this.title,
    required this.items,
  });

  /// Dart [DateTime.weekday]: 1 Monday … 7 Sunday.
  final int weekday;
  final String title;
  final List<PlannedItem> items;

  factory PlannedSession.fromJson(Map<String, Object?> json) {
    final rawItems = json[PlanJsonKeys.items];
    return PlannedSession(
      weekday: _asInt(json[PlanJsonKeys.weekday], 1),
      title: json[PlanJsonKeys.title]?.toString() ?? '',
      items: rawItems is List
          ? rawItems
                .whereType<Map<Object?, Object?>>()
                .map(
                  (Map<Object?, Object?> item) => PlannedItem.fromJson(
                    item.map(
                      (Object? key, Object? value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList()
          : const <PlannedItem>[],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      PlanJsonKeys.weekday: weekday,
      PlanJsonKeys.title: title,
      PlanJsonKeys.items: items.map((PlannedItem i) => i.toJson()).toList(),
    };
  }
}

final class TrainingPlan {
  const TrainingPlan({
    required this.goal,
    required this.daysPerWeek,
    required this.equipment,
    required this.sessions,
    this.periodAdjusted = false,
  });

  final TrainingGoal goal;
  final int daysPerWeek;
  final EquipmentProfile equipment;
  final List<PlannedSession> sessions;

  /// True only for the in-memory view during a period window.
  /// Saved plans keep this false so the window can move day to day.
  final bool periodAdjusted;

  PlannedSession? sessionForWeekday(int weekday) {
    for (final PlannedSession session in sessions) {
      if (session.weekday == weekday) {
        return session;
      }
    }
    return null;
  }

  factory TrainingPlan.fromJson(Map<String, Object?> json) {
    final rawSessions = json[PlanJsonKeys.sessions];
    return TrainingPlan(
      goal: trainingGoalFromWire(json[PlanJsonKeys.goal]?.toString()),
      daysPerWeek: _asInt(
        json[PlanJsonKeys.daysPerWeek],
        PlanLimits.defaultDaysPerWeek,
      ),
      equipment: equipmentProfileFromWire(
        json[PlanJsonKeys.equipment]?.toString(),
      ),
      periodAdjusted: json[PlanJsonKeys.periodAdjusted] == true,
      sessions: rawSessions is List
          ? rawSessions
                .whereType<Map<Object?, Object?>>()
                .map(
                  (Map<Object?, Object?> item) => PlannedSession.fromJson(
                    item.map(
                      (Object? key, Object? value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList()
          : const <PlannedSession>[],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      PlanJsonKeys.goal: goal.wireName,
      PlanJsonKeys.daysPerWeek: daysPerWeek,
      PlanJsonKeys.equipment: equipment.wireName,
      PlanJsonKeys.periodAdjusted: periodAdjusted,
      PlanJsonKeys.sessions: sessions
          .map((PlannedSession s) => s.toJson())
          .toList(),
    };
  }
}

int _asInt(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<WorkoutExercise> exercisesFromPlan(PlannedSession session) {
  return session.items.map((PlannedItem item) {
    final CatalogExercise? resolved = ExerciseCatalog.resolve(
      catalogId: item.catalogId,
      nameZh: item.nameZh,
    );
    final String? catalogId = resolved?.id ?? _storedCatalogId(item.catalogId);
    final built = WorkoutExercise.create(
      resolved?.nameZh ?? item.nameZh,
      catalogId: catalogId,
    );
    final sets = <WorkoutSet>[
      for (int i = 0; i < item.sets; i++) WorkoutSet.create(reps: item.reps),
    ];
    return built.copyWith(sets: sets);
  }).toList();
}

String? _storedCatalogId(String catalogId) {
  if (catalogId.isEmpty) {
    return null;
  }
  return catalogId;
}
