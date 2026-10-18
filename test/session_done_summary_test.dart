import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/session_done_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const List<WorkoutExercise> oneExercise = <WorkoutExercise>[
    WorkoutExercise(
      id: 'e',
      name: '深蹲',
      sets: <WorkoutSet>[
        WorkoutSet(id: 'a', weightKg: 100, reps: 5, completed: true),
        WorkoutSet(id: 'b', weightKg: 100, reps: 5, completed: true),
      ],
    ),
  ];

  test('finish summary lists sets, volume, wall clock, and rest split', () {
    final DateTime origin = DateTime(2026, 10, 17, 8);
    final WorkoutSession session = WorkoutSession(
      id: 's',
      startedAt: origin,
      timerStartedAt: origin,
      endedAt: null,
      notes: '',
      exercises: oneExercise,
    );
    final SessionDoneSummary summary = sessionDoneSummary(
      session: session,
      now: origin.add(const Duration(minutes: 45)),
      rest: const Duration(minutes: 10),
    );

    expect(summary.completedSets, 2);
    expect(summary.volumeKg, 1000);
    expect(summary.wallClock, const Duration(minutes: 45));
    expect(summary.active, const Duration(minutes: 35));
    final String body = formatSessionDoneBody(summary);
    expect(body, '组数 2\n容量 1000 kg\n总时长 45:00\n组间休息 10:00 · 不含休息 35:00');
    expect(body.contains('。'), isFalse);
    final SessionFinishFigures figures = sessionFinishFigures(summary);
    expect(figures.sets, '2');
    expect(figures.volumeKg, '1000');
    expect(figures.wallClock, '45:00');
    expect(figures.rest, '10:00');
  });

  test('omits the clock before it starts and clamps rest past the wall', () {
    final WorkoutSession empty = WorkoutSession(
      id: 'empty',
      startedAt: DateTime(2026, 10, 17, 8),
      endedAt: null,
      notes: '',
      exercises: const <WorkoutExercise>[],
    );
    expect(
      formatSessionDoneBody(
        sessionDoneSummary(session: empty, now: DateTime(2026, 10, 17, 9)),
      ),
      '组数 0\n容量 0 kg',
    );
    final SessionFinishFigures quiet = sessionFinishFigures(
      sessionDoneSummary(session: empty, now: DateTime(2026, 10, 17, 9)),
    );
    expect(quiet.sets, '0');
    expect(quiet.volumeKg, '0');
    expect(quiet.wallClock, '00:00');
    expect(quiet.rest, '00:00');

    final DateTime origin = DateTime(2026, 10, 17, 8);
    final WorkoutSession worked = WorkoutSession(
      id: 'worked',
      startedAt: origin,
      timerStartedAt: origin,
      endedAt: origin.add(const Duration(minutes: 20)),
      notes: '',
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e',
          name: '深蹲',
          sets: <WorkoutSet>[
            WorkoutSet(id: 'a', weightKg: 20, reps: 5, completed: true),
          ],
        ),
      ],
    );
    final SessionDoneSummary over = sessionDoneSummary(
      session: worked,
      now: origin.add(const Duration(hours: 1)),
      rest: const Duration(minutes: 30),
    );
    expect(over.wallClock, const Duration(minutes: 20));
    expect(over.active, Duration.zero);
    expect(
      formatSessionDoneBody(
        sessionDoneSummary(session: worked, now: origin, rest: Duration.zero),
      ).contains('组间休息'),
      isFalse,
    );
  });
}
