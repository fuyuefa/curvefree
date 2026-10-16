import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/training/models/workout_models.dart';

/// Display aggregate for the current local week. Not stored.
final class WeekProgress {
  const WeekProgress({
    required this.trainedDays,
    required this.plannedDays,
    required this.volumeKg,
    required this.completedSets,
    required this.plannedSets,
  });

  final int trainedDays;
  final int plannedDays;
  final double volumeKg;
  final int completedSets;
  final int plannedSets;

  double get dayFraction {
    if (plannedDays <= 0) {
      return 0;
    }
    final double ratio = trainedDays / plannedDays;
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }

  int get completionPercent {
    if (plannedSets <= 0) {
      return 0;
    }
    final int percent = (completedSets / plannedSets * 100).round();
    if (percent < 0) {
      return 0;
    }
    if (percent > 100) {
      return 100;
    }
    return percent;
  }

  String get sessionsLabel => '$trainedDays/$plannedDays';

  String get completionLabel => '$completionPercent%';
}

DateTime startOfLocalWeek(DateTime now) {
  final DateTime local = now.toLocal();
  final DateTime day = DateTime(local.year, local.month, local.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

bool isInLocalWeek(DateTime instant, DateTime weekStartLocal) {
  final DateTime local = instant.toLocal();
  final DateTime end = weekStartLocal.add(
    const Duration(days: DateTime.daysPerWeek),
  );
  return !local.isBefore(weekStartLocal) && local.isBefore(end);
}

WeekProgress summarizeWeek({
  required DateTime now,
  required List<WorkoutSession> sessions,
  required TrainingPlan? plan,
}) {
  final DateTime weekStart = startOfLocalWeek(now);
  final Set<DateTime> trainedDates = <DateTime>{};
  double volume = 0;
  int completed = 0;
  for (final WorkoutSession session in sessions) {
    if (!isInLocalWeek(session.startedAt, weekStart)) {
      continue;
    }
    volume += session.volumeKg;
    completed += session.completedSetCount;
    if (session.isFinished || session.completedSetCount > 0) {
      final DateTime local = session.startedAt.toLocal();
      trainedDates.add(DateTime(local.year, local.month, local.day));
    }
  }
  return WeekProgress(
    trainedDays: trainedDates.length,
    plannedDays: _plannedDays(plan),
    volumeKg: volume,
    completedSets: completed,
    plannedSets: _plannedSets(plan),
  );
}

int _plannedDays(TrainingPlan? plan) {
  if (plan == null) {
    return 0;
  }
  return plan.sessions
      .map((PlannedSession session) => session.weekday)
      .toSet()
      .length;
}

int _plannedSets(TrainingPlan? plan) {
  if (plan == null) {
    return 0;
  }
  int total = 0;
  for (final PlannedSession session in plan.sessions) {
    for (final PlannedItem item in session.items) {
      total += item.sets;
    }
  }
  return total;
}
