import 'package:curvefree/features/training/models/workout_models.dart';

/// The unfinished session with the latest [WorkoutSession.startedAt].
///
/// Finished sessions are ignored. When two unfinished sessions share a start
/// time, the first one in [sessions] is kept.
WorkoutSession? newestUnfinishedSession(Iterable<WorkoutSession> sessions) {
  WorkoutSession? newest;
  for (final WorkoutSession session in sessions) {
    if (session.isFinished) {
      continue;
    }
    if (newest == null || session.startedAt.isAfter(newest.startedAt)) {
      newest = session;
    }
  }
  return newest;
}
