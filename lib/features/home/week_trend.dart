import 'package:curvefree/features/home/week_progress.dart';
import 'package:curvefree/features/training/models/workout_models.dart';

/// Rolling window for the today-page trend. Not a stored series.
abstract final class WeekTrendLimits {
  static const int dayCount = 7;
}

final class DayVolume {
  const DayVolume({required this.day, required this.volumeKg});

  /// Local calendar date, time fields at midnight.
  final DateTime day;
  final double volumeKg;
}

final class WeekTrend {
  const WeekTrend({required this.days, required this.finishedSessionCount});

  final List<DayVolume> days;

  /// Finished sessions whose start falls in the current local week.
  final int finishedSessionCount;

  double get volumeKg {
    return days.fold<double>(
      0,
      (double sum, DayVolume day) => sum + day.volumeKg,
    );
  }

  bool get hasVolume => volumeKg > 0;
}

DateTime localDate(DateTime instant) {
  final DateTime local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

WeekTrend summarizeWeekTrend({
  required DateTime now,
  required List<WorkoutSession> sessions,
}) {
  final DateTime today = localDate(now);
  final List<DateTime> days = <DateTime>[
    for (int offset = WeekTrendLimits.dayCount - 1; offset >= 0; offset--)
      today.subtract(Duration(days: offset)),
  ];
  final Map<DateTime, double> volumeByDay = <DateTime, double>{
    for (final DateTime day in days) day: 0,
  };
  final DateTime weekStart = startOfLocalWeek(now);
  int finished = 0;
  for (final WorkoutSession session in sessions) {
    final DateTime day = localDate(session.startedAt);
    final double? current = volumeByDay[day];
    if (current != null) {
      volumeByDay[day] = current + session.volumeKg;
    }
    if (session.isFinished && isInLocalWeek(session.startedAt, weekStart)) {
      finished += 1;
    }
  }
  return WeekTrend(
    days: <DayVolume>[
      for (final DateTime day in days)
        DayVolume(day: day, volumeKg: volumeByDay[day] ?? 0),
    ],
    finishedSessionCount: finished,
  );
}
