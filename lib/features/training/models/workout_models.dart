import 'package:curvefree/core/ids/entity_ids.dart';
import 'package:curvefree/features/training/training_json_keys.dart';

final class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.weightKg,
    required this.reps,
    required this.completed,
  });

  final String id;
  final double weightKg;
  final int reps;
  final bool completed;

  double get volumeKg => completed ? weightKg * reps : 0;

  factory WorkoutSet.create({
    double weightKg = TrainingDefaults.defaultWeightKg,
    int reps = TrainingDefaults.defaultReps,
  }) {
    return WorkoutSet(
      id: EntityIds.next(TrainingIdPrefix.set),
      weightKg: weightKg,
      reps: reps,
      completed: false,
    );
  }

  factory WorkoutSet.fromJson(Map<String, Object?> json) {
    return WorkoutSet(
      id:
          json[TrainingJsonKeys.id]?.toString() ??
          EntityIds.next(TrainingIdPrefix.set),
      weightKg: _asDouble(json[TrainingJsonKeys.weightKg]),
      reps: _asInt(json[TrainingJsonKeys.reps]),
      completed: json[TrainingJsonKeys.completed] == true,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      TrainingJsonKeys.id: id,
      TrainingJsonKeys.weightKg: weightKg,
      TrainingJsonKeys.reps: reps,
      TrainingJsonKeys.completed: completed,
    };
  }

  WorkoutSet copyWith({double? weightKg, int? reps, bool? completed}) {
    return WorkoutSet(
      id: id,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
    );
  }
}

final class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
  });

  final String id;
  final String name;
  final List<WorkoutSet> sets;

  double get volumeKg =>
      sets.fold<double>(0, (double sum, WorkoutSet set) => sum + set.volumeKg);

  factory WorkoutExercise.create(String name) {
    return WorkoutExercise(
      id: EntityIds.next(TrainingIdPrefix.exercise),
      name: name,
      sets: <WorkoutSet>[WorkoutSet.create()],
    );
  }

  factory WorkoutExercise.fromJson(Map<String, Object?> json) {
    final rawSets = json[TrainingJsonKeys.sets];
    return WorkoutExercise(
      id:
          json[TrainingJsonKeys.id]?.toString() ??
          EntityIds.next(TrainingIdPrefix.exercise),
      name: json[TrainingJsonKeys.name]?.toString() ?? '',
      sets: rawSets is List
          ? rawSets
                .whereType<Map<Object?, Object?>>()
                .map(
                  (Map<Object?, Object?> item) => WorkoutSet.fromJson(
                    item.map(
                      (Object? key, Object? value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList()
          : const <WorkoutSet>[],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      TrainingJsonKeys.id: id,
      TrainingJsonKeys.name: name,
      TrainingJsonKeys.sets: sets.map((WorkoutSet s) => s.toJson()).toList(),
    };
  }

  WorkoutExercise copyWith({String? name, List<WorkoutSet>? sets}) {
    return WorkoutExercise(
      id: id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
    );
  }
}

final class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.notes,
    required this.exercises,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String notes;
  final List<WorkoutExercise> exercises;

  bool get isFinished => endedAt != null;

  double get volumeKg => exercises.fold<double>(
    0,
    (double sum, WorkoutExercise exercise) => sum + exercise.volumeKg,
  );

  int get completedSetCount => exercises.fold<int>(
    0,
    (int sum, WorkoutExercise exercise) =>
        sum + exercise.sets.where((WorkoutSet s) => s.completed).length,
  );

  factory WorkoutSession.create({DateTime? startedAt}) {
    return WorkoutSession(
      id: EntityIds.next(TrainingIdPrefix.session),
      startedAt: startedAt ?? DateTime.now(),
      endedAt: null,
      notes: '',
      exercises: const <WorkoutExercise>[],
    );
  }

  factory WorkoutSession.fromJson(Map<String, Object?> json) {
    final rawExercises = json[TrainingJsonKeys.exercises];
    return WorkoutSession(
      id:
          json[TrainingJsonKeys.id]?.toString() ??
          EntityIds.next(TrainingIdPrefix.session),
      startedAt:
          DateTime.tryParse(
            json[TrainingJsonKeys.startedAt]?.toString() ?? '',
          ) ??
          DateTime.now(),
      endedAt: DateTime.tryParse(
        json[TrainingJsonKeys.endedAt]?.toString() ?? '',
      ),
      notes: json[TrainingJsonKeys.notes]?.toString() ?? '',
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map<Object?, Object?>>()
                .map(
                  (Map<Object?, Object?> item) => WorkoutExercise.fromJson(
                    item.map(
                      (Object? key, Object? value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList()
          : const <WorkoutExercise>[],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      TrainingJsonKeys.id: id,
      TrainingJsonKeys.startedAt: startedAt.toIso8601String(),
      TrainingJsonKeys.endedAt: endedAt?.toIso8601String(),
      TrainingJsonKeys.notes: notes,
      TrainingJsonKeys.exercises: exercises
          .map((WorkoutExercise e) => e.toJson())
          .toList(),
    };
  }

  WorkoutSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    String? notes,
    List<WorkoutExercise>? exercises,
  }) {
    return WorkoutSession(
      id: id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
