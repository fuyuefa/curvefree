import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/home/muscle_groups.dart';
import 'package:curvefree/features/home/week_trend.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seven-day volume ignores older days and counts finished sessions', () {
    final DateTime now = DateTime(2026, 10, 17, 18);
    final WorkoutSession today = _session(
      id: 'today',
      startedAt: DateTime(2026, 10, 17, 9),
      endedAt: DateTime(2026, 10, 17, 10),
      volumeReps: 8,
    );
    final WorkoutSession sameDay = _session(
      id: 'later',
      startedAt: DateTime(2026, 10, 17, 16),
      endedAt: null,
      volumeReps: 5,
    );
    final WorkoutSession monday = _session(
      id: 'monday',
      startedAt: DateTime(2026, 10, 12, 19),
      endedAt: DateTime(2026, 10, 12, 20),
      volumeReps: 3,
    );
    final WorkoutSession beforeWindow = _session(
      id: 'old',
      startedAt: DateTime(2026, 10, 9, 19),
      endedAt: DateTime(2026, 10, 9, 20),
      volumeReps: 10,
    );

    final WeekTrend trend = summarizeWeekTrend(
      now: now,
      sessions: <WorkoutSession>[today, sameDay, monday, beforeWindow],
    );

    expect(trend.days, hasLength(WeekTrendLimits.dayCount));
    expect(trend.days.first.day, DateTime(2026, 10, 11));
    expect(trend.days.last.day, DateTime(2026, 10, 17));
    expect(trend.days.last.volumeKg, 40 * 8 + 40 * 5);
    expect(trend.days[1].volumeKg, 40 * 3);
    expect(trend.volumeKg, 40 * 8 + 40 * 5 + 40 * 3);
    expect(trend.finishedSessionCount, 2);
    expect(trend.hasVolume, isTrue);
  });

  test('muscle section title follows whether today has a plan', () {
    expect(muscleSectionTitle(plannedForToday: true), '今天会练到');
    expect(
      muscleSectionTitle(plannedForToday: false),
      AppStrings.muscleGroupsTitle,
    );
  });

  testWidgets('today opens the seven-day trend from the plan day', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PrefsLocalStore store = PrefsLocalStore(
      preferences: await SharedPreferences.getInstance(),
    );
    final DateTime now = DateTime.now();
    final TrainingPlan plan = TrainingPlan(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
      sessions: <PlannedSession>[
        PlannedSession(
          weekday: now.weekday,
          title: '推',
          items: const <PlannedItem>[
            PlannedItem(
              catalogId: 'ex_barbell_bench',
              nameZh: '杠铃卧推',
              sets: 3,
              reps: 8,
            ),
          ],
        ),
      ],
    );
    final WorkoutSession finished = _session(
      id: 'done-now',
      startedAt: now,
      endedAt: now,
      volumeReps: 8,
    );
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        settings: <String, Object?>{PlanJsonKeys.settingsKey: plan.toJson()},
        workouts: <Map<String, Object?>>[finished.toJson()],
      ),
    );

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.musclesPlannedToday), findsOneWidget);
    expect(find.byKey(const Key('home_open_trend')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_open_trend')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('train_trend_page')), findsOneWidget);
    expect(find.text(AppStrings.weekFinishedLine(1)), findsOneWidget);
    expect(find.byKey(const Key('train_trend_sparkline')), findsOneWidget);
    expect(
      find.text(
        AppStrings.recentVolumeLine(
          days: WeekTrendLimits.dayCount,
          volume: '320',
        ),
      ),
      findsOneWidget,
    );
  });
}

WorkoutSession _session({
  required String id,
  required DateTime startedAt,
  required DateTime? endedAt,
  required int volumeReps,
}) {
  return WorkoutSession(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    timerStartedAt: startedAt,
    notes: '',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-$id',
        name: '杠铃卧推',
        catalogId: 'ex_barbell_bench',
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 's-$id',
            weightKg: 40,
            reps: volumeReps,
            completed: true,
          ),
        ],
      ),
    ],
  );
}
