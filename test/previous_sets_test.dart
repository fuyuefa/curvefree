import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/previous_sets.dart';
import 'package:curvefree/features/training/set_focus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime olderStart = DateTime.utc(2026, 10, 1);
  final DateTime newerStart = DateTime.utc(2026, 10, 8);

  WorkoutSet completed({
    required String id,
    required double weightKg,
    required int reps,
  }) {
    return WorkoutSet(id: id, weightKg: weightKg, reps: reps, completed: true);
  }

  WorkoutSession session({
    required String id,
    required DateTime startedAt,
    required List<WorkoutSet> sets,
    bool finished = true,
  }) {
    return WorkoutSession(
      id: id,
      startedAt: startedAt,
      endedAt: finished ? startedAt.add(const Duration(hours: 1)) : null,
      notes: '',
      exercises: <WorkoutExercise>[
        WorkoutExercise(id: 'e-$id', name: '杠铃卧推', sets: sets),
      ],
    );
  }

  test('previous column uses the newest completed session by set index', () {
    final WorkoutSession older = session(
      id: 'w-old',
      startedAt: olderStart,
      sets: <WorkoutSet>[
        completed(id: 'a0', weightKg: 30, reps: 10),
        completed(id: 'a1', weightKg: 30, reps: 10),
      ],
    );
    final WorkoutSession newer = session(
      id: 'w-new',
      startedAt: newerStart,
      sets: <WorkoutSet>[
        completed(id: 'b0', weightKg: 40, reps: 8),
        const WorkoutSet(id: 'b1', weightKg: 40, reps: 6, completed: false),
        completed(id: 'b2', weightKg: 42.5, reps: 5),
      ],
    );
    final WorkoutSession current = session(
      id: 'w-now',
      startedAt: newerStart.add(const Duration(days: 1)),
      finished: false,
      sets: <WorkoutSet>[completed(id: 'c0', weightKg: 99, reps: 1)],
    );

    final List<WorkoutSet?> previous = previousCompletedSetsByIndex(
      sessionsNewestFirst: <WorkoutSession>[current, newer, older],
      exerciseName: ' 杠铃卧推 ',
      exceptSessionId: current.id,
    );

    expect(previous.map(formatPreviousLoad).toList(), <String>[
      '40×8',
      AppStrings.previousEmpty,
      '42.5×5',
    ]);
  });

  test(
    'a newer session with no completed sets does not hide older history',
    () {
      final WorkoutSession abandoned = session(
        id: 'w-empty',
        startedAt: newerStart,
        finished: false,
        sets: const <WorkoutSet>[
          WorkoutSet(id: 'z', weightKg: 20, reps: 8, completed: false),
        ],
      );
      final WorkoutSession older = session(
        id: 'w-old',
        startedAt: olderStart,
        sets: <WorkoutSet>[completed(id: 'a0', weightKg: 50, reps: 5)],
      );

      final List<WorkoutSet?> previous = previousCompletedSetsByIndex(
        sessionsNewestFirst: <WorkoutSession>[abandoned, older],
        exerciseName: '杠铃卧推',
      );

      expect(formatPreviousLoad(previous.single), '50×5');
    },
  );

  test(
    'missing history and whole-number weights format without a fraction',
    () {
      expect(formatPreviousLoad(null), AppStrings.previousEmpty);
      expect(formatWeightKg(40), '40');
      expect(formatPreviousLoad(null), '—');
    },
  );

  test('next focus is the following open set and does not wrap', () {
    final List<WorkoutSet> sets = <WorkoutSet>[
      const WorkoutSet(id: 's0', weightKg: 40, reps: 8, completed: false),
      const WorkoutSet(id: 's1', weightKg: 40, reps: 8, completed: true),
      const WorkoutSet(id: 's2', weightKg: 40, reps: 8, completed: false),
    ];

    expect(nextIncompleteSetId(sets: sets, completedIndex: 0), 's2');
    expect(nextIncompleteSetId(sets: sets, completedIndex: 2), isNull);
    expect(nextIncompleteSetId(sets: sets, completedIndex: -1), isNull);
    expect(nextIncompleteSetId(sets: sets, completedIndex: 3), isNull);
  });
}
