import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product defaults for the per-set rest countdown.
abstract final class RestTimerLimits {
  static const int defaultSeconds = 90;
  static const int stepSeconds = 15;
  static const int minSeconds = 15;
  static const int maxSeconds = 300;
  static const Duration tick = Duration(seconds: 1);
}

typedef RestClock = DateTime Function();

int clampRestSeconds(int seconds) {
  if (seconds < RestTimerLimits.minSeconds) {
    return RestTimerLimits.minSeconds;
  }
  if (seconds > RestTimerLimits.maxSeconds) {
    return RestTimerLimits.maxSeconds;
  }
  return seconds;
}

/// In-memory rest countdown. Survives leaving the session page and coming back.
///
/// It is not written into the workout document: finishing, deleting, or
/// skipping drops the active countdown and keeps only [preferredSeconds].
final class RestTimerState {
  const RestTimerState({
    this.preferredSeconds = RestTimerLimits.defaultSeconds,
    this.sessionId,
    this.exerciseId,
    this.setId,
    this.endsAt,
  });

  final int preferredSeconds;
  final String? sessionId;
  final String? exerciseId;
  final String? setId;
  final DateTime? endsAt;

  bool isRunningAt(DateTime now) {
    final DateTime? end = endsAt;
    if (sessionId == null || end == null) {
      return false;
    }
    return end.isAfter(now);
  }

  bool isRunningFor(String id, DateTime now) {
    return sessionId == id && isRunningAt(now);
  }

  Duration remainingAt(DateTime now) {
    final DateTime? end = endsAt;
    if (end == null) {
      return Duration.zero;
    }
    final Duration remaining = end.difference(now);
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  RestTimerState restarted({
    required String sessionId,
    required String exerciseId,
    required String setId,
    required DateTime now,
  }) {
    return RestTimerState(
      preferredSeconds: preferredSeconds,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setId: setId,
      endsAt: now.add(Duration(seconds: preferredSeconds)),
    );
  }

  RestTimerState adjustedBy(int deltaSeconds, DateTime now) {
    final int nextPreferred = clampRestSeconds(preferredSeconds + deltaSeconds);
    final DateTime? end = endsAt;
    final String? activeSession = sessionId;
    if (activeSession == null || end == null) {
      return RestTimerState(preferredSeconds: nextPreferred);
    }
    final DateTime nextEnd = end.add(Duration(seconds: deltaSeconds));
    if (!nextEnd.isAfter(now)) {
      return RestTimerState(preferredSeconds: nextPreferred);
    }
    final int remainingSeconds = nextEnd.difference(now).inSeconds;
    final DateTime cappedEnd = remainingSeconds > RestTimerLimits.maxSeconds
        ? now.add(const Duration(seconds: RestTimerLimits.maxSeconds))
        : nextEnd;
    return RestTimerState(
      preferredSeconds: nextPreferred,
      sessionId: activeSession,
      exerciseId: exerciseId,
      setId: setId,
      endsAt: cappedEnd,
    );
  }

  RestTimerState skipped() {
    return RestTimerState(preferredSeconds: preferredSeconds);
  }

  RestTimerState clearedIfSession(String id) {
    if (sessionId != id) {
      return this;
    }
    return skipped();
  }
}

String restAdjustLabel({required bool increase}) {
  final String sign = increase ? '+' : '−';
  return '$sign${RestTimerLimits.stepSeconds}';
}

String restShorterTooltip() {
  return '少休息 ${RestTimerLimits.stepSeconds} 秒';
}

String restLongerTooltip() {
  return '多休息 ${RestTimerLimits.stepSeconds} 秒';
}

final restTimerProvider = NotifierProvider<RestTimerController, RestTimerState>(
  RestTimerController.new,
);

final class RestTimerController extends Notifier<RestTimerState> {
  /// Wall clock for the countdown. Tests replace this to move time.
  RestClock clock = DateTime.now;

  @override
  RestTimerState build() => const RestTimerState();

  void restart({
    required String sessionId,
    required String exerciseId,
    required String setId,
  }) {
    state = state.restarted(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setId: setId,
      now: clock(),
    );
  }

  void adjust(int deltaSeconds) {
    state = state.adjustedBy(deltaSeconds, clock());
  }

  void skip() {
    state = state.skipped();
  }

  void clearSession(String sessionId) {
    state = state.clearedIfSession(sessionId);
  }
}
