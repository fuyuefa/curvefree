import 'dart:async';

import 'package:curvefree/core/constants/app_tokens.dart';
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
    this.restStartedAt,
    this.accountedSessionId,
    this.accumulatedRest = Duration.zero,
    this.endFlashSessionId,
    this.endFlashExerciseId,
    this.endFlashUntil,
  });

  final int preferredSeconds;
  final String? sessionId;
  final String? exerciseId;
  final String? setId;
  final DateTime? endsAt;

  /// When the current countdown began. Closed intervals live in [accumulatedRest].
  final DateTime? restStartedAt;

  /// Session that owns [accumulatedRest], including after the countdown stops.
  final String? accountedSessionId;

  /// Rest already taken in [accountedSessionId], excluding the open countdown.
  final Duration accumulatedRest;

  /// Session whose rest UI should flash until [endFlashUntil].
  final String? endFlashSessionId;

  /// Exercise label kept for the flash after the countdown closes.
  final String? endFlashExerciseId;

  /// When the rest-end flash should drop. Null when no flash is showing.
  final DateTime? endFlashUntil;

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

  /// True while the rest-end flash for [id] should stay on screen.
  bool endFlashActiveFor(String id, DateTime now) {
    final DateTime? until = endFlashUntil;
    return endFlashSessionId == id && until != null && now.isBefore(until);
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

  /// Rest taken so far for [id]. Null when this countdown belongs elsewhere
  /// or nothing has been rested yet.
  Duration? restTotalFor(String id, DateTime now) {
    if (sessionId != id && accountedSessionId != id) {
      return null;
    }
    final Duration open = sessionId == id
        ? _elapsedCurrent(now)
        : Duration.zero;
    final Duration total = accumulatedRest + open;
    if (total <= Duration.zero) {
      return null;
    }
    return total;
  }

  RestTimerState restarted({
    required String sessionId,
    required String exerciseId,
    required String setId,
    required DateTime now,
  }) {
    final bool sameOwner =
        accountedSessionId == null || accountedSessionId == sessionId;
    final Duration carried = sameOwner
        ? accumulatedRest + _elapsedCurrent(now)
        : Duration.zero;
    return RestTimerState(
      preferredSeconds: preferredSeconds,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setId: setId,
      restStartedAt: now,
      endsAt: now.add(Duration(seconds: preferredSeconds)),
      accountedSessionId: sessionId,
      accumulatedRest: carried,
    );
  }

  RestTimerState adjustedBy(int deltaSeconds, DateTime now) {
    final int nextPreferred = clampRestSeconds(preferredSeconds + deltaSeconds);
    final DateTime? end = endsAt;
    final String? activeSession = sessionId;
    if (activeSession == null || end == null) {
      return RestTimerState(
        preferredSeconds: nextPreferred,
        accountedSessionId: accountedSessionId,
        accumulatedRest: accumulatedRest,
      );
    }
    final DateTime nextEnd = end.add(Duration(seconds: deltaSeconds));
    if (!nextEnd.isAfter(now)) {
      return RestTimerState(
        preferredSeconds: nextPreferred,
        accountedSessionId: accountedSessionId ?? activeSession,
        accumulatedRest: accumulatedRest + _elapsedCurrent(now),
      );
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
      restStartedAt: restStartedAt,
      endsAt: cappedEnd,
      accountedSessionId: accountedSessionId ?? activeSession,
      accumulatedRest: accumulatedRest,
    );
  }

  RestTimerState skipped({DateTime? now}) {
    final Duration extra = now == null ? Duration.zero : _elapsedCurrent(now);
    return RestTimerState(
      preferredSeconds: preferredSeconds,
      accountedSessionId: sessionId ?? accountedSessionId,
      accumulatedRest: accumulatedRest + extra,
    );
  }

  RestTimerState withEndFlash({
    required String sessionId,
    required String? exerciseId,
    required DateTime until,
  }) {
    return RestTimerState(
      preferredSeconds: preferredSeconds,
      accountedSessionId: accountedSessionId,
      accumulatedRest: accumulatedRest,
      endFlashSessionId: sessionId,
      endFlashExerciseId: exerciseId,
      endFlashUntil: until,
    );
  }

  RestTimerState clearEndFlash() {
    if (endFlashUntil == null &&
        endFlashSessionId == null &&
        endFlashExerciseId == null) {
      return this;
    }
    return RestTimerState(
      preferredSeconds: preferredSeconds,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setId: setId,
      endsAt: endsAt,
      restStartedAt: restStartedAt,
      accountedSessionId: accountedSessionId,
      accumulatedRest: accumulatedRest,
    );
  }

  RestTimerState clearedIfSession(String id) {
    final bool ownsCountdown = sessionId == id || accountedSessionId == id;
    final bool ownsFlash = endFlashSessionId == id;
    if (!ownsCountdown && !ownsFlash) {
      return this;
    }
    return RestTimerState(preferredSeconds: preferredSeconds);
  }

  Duration _elapsedCurrent(DateTime now) {
    final DateTime? start = restStartedAt;
    final DateTime? end = endsAt;
    if (start == null || end == null || sessionId == null) {
      return Duration.zero;
    }
    final DateTime capped = now.isBefore(end) ? now : end;
    final Duration elapsed = capped.difference(start);
    if (elapsed.isNegative) {
      return Duration.zero;
    }
    return elapsed;
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

  Timer? _flashTimer;
  DateTime? _claimedEnd;

  @override
  RestTimerState build() {
    ref.onDispose(_cancelFlashTimer);
    return const RestTimerState();
  }

  void restart({
    required String sessionId,
    required String exerciseId,
    required String setId,
  }) {
    _dropEndFlash();
    state = state.restarted(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setId: setId,
      now: clock(),
    );
  }

  void adjust(int deltaSeconds) {
    _dropEndFlash();
    state = state.adjustedBy(deltaSeconds, clock());
  }

  void skip() {
    _dropEndFlash();
    state = state.skipped(now: clock());
  }

  void clearSession(String sessionId) {
    _cancelFlashTimer();
    _claimedEnd = null;
    state = state.clearedIfSession(sessionId);
  }

  /// Closes an open countdown the first time [now] is at or past its end.
  ///
  /// Skip, adjust, and a new check do not call this. A second caller for the
  /// same end returns false so the haptic plays once.
  bool noteNaturalEnd(DateTime now) {
    final DateTime? end = state.endsAt;
    final String? sessionId = state.sessionId;
    if (sessionId == null || end == null || end.isAfter(now)) {
      return false;
    }
    if (_claimedEnd == end) {
      return false;
    }
    _claimedEnd = end;
    final String? exerciseId = state.exerciseId;
    _flashTimer?.cancel();
    state = state
        .skipped(now: now)
        .withEndFlash(
          sessionId: sessionId,
          exerciseId: exerciseId,
          until: now.add(AppMotion.restEndFlash),
        );
    _flashTimer = Timer(AppMotion.restEndFlash, _clearEndFlash);
    return true;
  }

  void _dropEndFlash() {
    _cancelFlashTimer();
    _claimedEnd = null;
    if (state.endFlashUntil != null || state.endFlashSessionId != null) {
      state = state.clearEndFlash();
    }
  }

  void _clearEndFlash() {
    _flashTimer = null;
    _claimedEnd = null;
    if (state.endFlashUntil == null && state.endFlashSessionId == null) {
      return;
    }
    state = state.clearEndFlash();
  }

  void _cancelFlashTimer() {
    _flashTimer?.cancel();
    _flashTimer = null;
  }
}
