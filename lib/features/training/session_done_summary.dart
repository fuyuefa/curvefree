import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
import 'package:curvefree/features/training/models/workout_models.dart';

/// Numbers shown before a session is marked finished.
final class SessionDoneSummary {
  const SessionDoneSummary({
    required this.completedSets,
    required this.volumeKg,
    required this.wallClock,
    required this.rest,
  });

  final int completedSets;
  final double volumeKg;

  /// Wall clock from the timer origin to finish. Null before the clock starts.
  final Duration? wallClock;

  /// Rest actually taken. Null when this session did not record any.
  final Duration? rest;

  /// Wall clock minus rest. Null until both sides of the split exist.
  Duration? get active {
    final Duration? wall = wallClock;
    final Duration? pause = rest;
    if (wall == null || pause == null) {
      return null;
    }
    final Duration training = wall - pause;
    if (training.isNegative) {
      return Duration.zero;
    }
    return training;
  }
}

SessionDoneSummary sessionDoneSummary({
  required WorkoutSession session,
  required DateTime now,
  Duration? rest,
}) {
  return SessionDoneSummary(
    completedSets: session.completedSetCount,
    volumeKg: session.volumeKg,
    wallClock: _wallClock(session, now),
    rest: _knownRest(rest),
  );
}

String formatSessionDoneBody(SessionDoneSummary summary) {
  final String volume = summary.volumeKg.toStringAsFixed(0);
  final List<String> lines = <String>[
    '${AppStrings.setsCountLabel} ${summary.completedSets}',
    '${AppStrings.volumeLabel} $volume ${AppStrings.weightColumn}',
  ];
  final Duration? wall = summary.wallClock;
  if (wall != null) {
    lines.add('${AppStrings.wallClockLabel} ${ElapsedFormat.format(wall)}');
  }
  final Duration? pause = summary.rest;
  final Duration? active = summary.active;
  if (wall != null && pause != null && active != null) {
    lines.add(
      '${AppStrings.restTimerLabel} ${ElapsedFormat.format(pause)}'
      ' · ${AppStrings.activeTrainingLabel} ${ElapsedFormat.format(active)}',
    );
  }
  return lines.join('\n');
}

Duration? _wallClock(WorkoutSession session, DateTime now) {
  final DateTime? origin = session.timerOrigin;
  if (origin == null) {
    return null;
  }
  final DateTime end = session.endedAt ?? now;
  final Duration raw = end.difference(origin);
  if (raw.isNegative) {
    return Duration.zero;
  }
  return raw;
}

Duration? _knownRest(Duration? rest) {
  if (rest == null || rest <= Duration.zero) {
    return null;
  }
  return rest;
}
