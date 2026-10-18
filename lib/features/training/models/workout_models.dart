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
    this.catalogId,
  });

  final String id;
  final String name;
  final String? catalogId;
  final List<WorkoutSet> sets;

  double get volumeKg =>
      sets.fold<double>(0, (double sum, WorkoutSet set) => sum + set.volumeKg);

  factory WorkoutExercise.create(String name, {String? catalogId}) {
    return WorkoutExercise(
      id: EntityIds.next(TrainingIdPrefix.exercise),
      name: name,
      catalogId: catalogId,
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
      catalogId: json[TrainingJsonKeys.catalogId]?.toString(),
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
      TrainingJsonKeys.catalogId: catalogId,
      TrainingJsonKeys.sets: sets.map((WorkoutSet s) => s.toJson()).toList(),
    };
  }

  WorkoutExercise copyWith({
    String? name,
    String? catalogId,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id,
      name: name ?? this.name,
      catalogId: catalogId ?? this.catalogId,
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
    this.timerStartedAt,
    this.title = '',
  });

  final String id;
  final DateTime startedAt;

  /// Wall clock origin. Null while the session has no exercise yet.
  final DateTime? timerStartedAt;
  final DateTime? endedAt;
  final String notes;

  /// Plan-day name captured when the session was opened from a plan.
  /// Empty for a free session and for rows written before the field existed.
  final String title;
  final List<WorkoutExercise> exercises;

  bool get isFinished => endedAt != null;

  /// When the visible workout clock started. Legacy rows that already had
  /// exercises fall back to [startedAt]. An empty draft has no origin.
  DateTime? get timerOrigin {
    if (exercises.isEmpty) {
      return null;
    }
    return timerStartedAt ?? startedAt;
  }

  bool get isTimerRunning => !isFinished && timerOrigin != null;

  double get volumeKg => exercises.fold<double>(
    0,
    (double sum, WorkoutExercise exercise) => sum + exercise.volumeKg,
  );

  int get completedSetCount => exercises.fold<int>(
    0,
    (int sum, WorkoutExercise exercise) =>
        sum + exercise.sets.where((WorkoutSet s) => s.completed).length,
  );

  factory WorkoutSession.create({DateTime? startedAt, String title = ''}) {
    return WorkoutSession(
      id: EntityIds.next(TrainingIdPrefix.session),
      startedAt: startedAt ?? DateTime.now(),
      endedAt: null,
      notes: '',
      exercises: const <WorkoutExercise>[],
      title: title,
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
      timerStartedAt: DateTime.tryParse(
        json[TrainingJsonKeys.timerStartedAt]?.toString() ?? '',
      ),
      endedAt: DateTime.tryParse(
        json[TrainingJsonKeys.endedAt]?.toString() ?? '',
      ),
      notes: json[TrainingJsonKeys.notes]?.toString() ?? '',
      title: json[TrainingJsonKeys.title]?.toString() ?? '',
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
      if (timerStartedAt != null)
        TrainingJsonKeys.timerStartedAt: timerStartedAt!.toIso8601String(),
      TrainingJsonKeys.endedAt: endedAt?.toIso8601String(),
      TrainingJsonKeys.notes: notes,
      if (title.isNotEmpty) TrainingJsonKeys.title: title,
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
    String? title,
    List<WorkoutExercise>? exercises,
    DateTime? timerStartedAt,
  }) {
    final List<WorkoutExercise> nextExercises = exercises ?? this.exercises;
    return WorkoutSession(
      id: id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      notes: notes ?? this.notes,
      title: title ?? this.title,
      exercises: nextExercises,
      timerStartedAt: _nextTimerOrigin(
        nextExercises: nextExercises,
        explicit: timerStartedAt,
      ),
    );
  }

  DateTime? _nextTimerOrigin({
    required List<WorkoutExercise> nextExercises,
    required DateTime? explicit,
  }) {
    if (nextExercises.isEmpty) {
      return null;
    }
    if (explicit != null) {
      return explicit;
    }
    if (exercises.isEmpty) {
      return DateTime.now();
    }
    return timerStartedAt;
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
