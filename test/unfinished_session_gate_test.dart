import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/data/workout_repository.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/unfinished_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _openExerciseName = '未完成深蹲';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('newestUnfinishedSession', () {
    test('ignores finished sessions and keeps the latest open one', () {
      final older = _session(
        id: 'w-old',
        startedAt: DateTime.utc(2026, 10, 1, 8),
        name: '旧课',
      );
      final finishedLater = _session(
        id: 'w-done',
        startedAt: DateTime.utc(2026, 10, 3, 8),
        endedAt: DateTime.utc(2026, 10, 3, 9),
        name: '已完成',
      );
      final newer = _session(
        id: 'w-new',
        startedAt: DateTime.utc(2026, 10, 2, 8),
        name: '新课',
      );

      expect(newestUnfinishedSession(const <WorkoutSession>[]), isNull);
      expect(newestUnfinishedSession(<WorkoutSession>[finishedLater]), isNull);
      expect(
        newestUnfinishedSession(<WorkoutSession>[finishedLater, older, newer]),
        newer,
      );
    });
  });

  group('WorkoutRepository.openOrInsert', () {
    test('inserts when every stored session is finished', () async {
      final repo = WorkoutRepository(await _emptyStore());
      final finished = _session(
        id: 'w-done',
        startedAt: DateTime.utc(2026, 10, 1, 8),
        endedAt: DateTime.utc(2026, 10, 1, 9),
        name: '已完成',
      );
      await repo.upsert(finished);

      final created = WorkoutSession.create();
      final opened = await repo.openOrInsert(created);

      expect(opened.id, created.id);
      final listed = await repo.listNewestFirst();
      expect(listed.map((WorkoutSession session) => session.id), <String>[
        created.id,
        finished.id,
      ]);
    });

    test('returns the open session and does not insert another', () async {
      final repo = WorkoutRepository(await _emptyStore());
      final open = _session(
        id: 'w-open',
        startedAt: DateTime.utc(2026, 10, 2, 8),
        name: _openExerciseName,
      );
      await repo.upsert(open);

      final opened = await repo.openOrInsert(WorkoutSession.create());

      expect(opened.id, open.id);
      expect(opened.exercises.single.name, _openExerciseName);
      expect(await repo.listNewestFirst(), hasLength(1));
    });

    test('concurrent inserts collapse to one session', () async {
      final repo = WorkoutRepository(await _emptyStore());
      final opened = await Future.wait(<Future<WorkoutSession>>[
        repo.openOrInsert(WorkoutSession.create()),
        repo.openOrInsert(WorkoutSession.create()),
      ]);

      expect(opened[0].id, opened[1].id);
      expect(await repo.listNewestFirst(), hasLength(1));
    });
  });

  group('WorkoutSessionsController start gate', () {
    test('starts a seeded session only when nothing is unfinished', () async {
      final harness = await _harness();
      final first = await harness.notifier.startFromPlan(_pushDay());
      expect(first.exercises.single.name, '杠铃卧推');
      expect(first.exercises.single.sets, hasLength(3));

      final resumed = await harness.notifier.startSession();
      final fromPlanAgain = await harness.notifier.startFromPlan(_pullDay());

      expect(resumed.id, first.id);
      expect(fromPlanAgain.id, first.id);
      expect(fromPlanAgain.exercises.single.name, '杠铃卧推');
      expect(harness.sessions, hasLength(1));
    });

    test(
      'resumes the newest unfinished session from either start path',
      () async {
        final harness = await _harness(
          workouts: <WorkoutSession>[
            _session(
              id: 'w-old',
              startedAt: DateTime.utc(2026, 10, 1, 8),
              name: '旧课',
            ),
            _session(
              id: 'w-new',
              startedAt: DateTime.utc(2026, 10, 2, 8),
              name: _openExerciseName,
            ),
          ],
        );

        final fromPlan = await harness.notifier.startFromPlan(_pushDay());
        final fromFab = await harness.notifier.startSession();

        expect(fromPlan.id, 'w-new');
        expect(fromFab.id, 'w-new');
        expect(fromPlan.exercises.single.name, _openExerciseName);
        expect(
          harness.sessions.map((WorkoutSession session) => session.id),
          <String>['w-new', 'w-old'],
        );
      },
    );

    test('parallel start calls still leave a single session', () async {
      final harness = await _harness();
      final opened = await Future.wait(<Future<WorkoutSession>>[
        harness.notifier.startSession(),
        harness.notifier.startFromPlan(_pushDay()),
      ]);

      expect(opened[0].id, opened[1].id);
      expect(harness.sessions, hasLength(1));
    });
  });

  testWidgets('today plan resumes the open session', (
    WidgetTester tester,
  ) async {
    final seeded = await _pumpWithOpenSession(tester);
    await tester.ensureVisible(find.byKey(const Key('home_today_plan')));
    await tester.tap(find.byKey(const Key('home_today_plan')));
    await _settle(tester);
    await _expectResumed(tester, seeded.store, seeded.open.id);
  });

  testWidgets('training start resumes the open session', (
    WidgetTester tester,
  ) async {
    final seeded = await _pumpWithOpenSession(tester);
    await tester.tap(find.byKey(const Key('nav_training')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('btn_start_workout')));
    await _settle(tester);
    await _expectResumed(tester, seeded.store, seeded.open.id);
  });

  testWidgets('plan page start resumes the open session', (
    WidgetTester tester,
  ) async {
    final seeded = await _pumpWithOpenSession(tester);
    await tester.tap(find.byKey(const Key('nav_training')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('btn_open_plan')));
    await _settle(tester);
    final Finder startFromPlan = find.widgetWithText(
      TextButton,
      AppStrings.startFromPlan,
    );
    await tester.ensureVisible(startFromPlan);
    await tester.tap(startFromPlan);
    await _settle(tester);
    await _expectResumed(tester, seeded.store, seeded.open.id);
  });

  testWidgets('plan page still starts a session when none is unfinished', (
    WidgetTester tester,
  ) async {
    final store = await _emptyStore();
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        settings: <String, Object?>{
          PlanJsonKeys.settingsKey: _todayPlan().toJson(),
        },
      ),
    );

    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const Key('nav_training')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('btn_open_plan')));
    await _settle(tester);
    final Finder startFromPlan = find.widgetWithText(
      TextButton,
      AppStrings.startFromPlan,
    );
    await tester.ensureVisible(startFromPlan);
    await tester.tap(startFromPlan);
    await _settle(tester);

    expect(find.text('杠铃卧推'), findsWidgets);
    expect(find.text(AppStrings.workoutInProgress), findsOneWidget);
    expect(find.byKey(const Key('btn_add_exercise')), findsOneWidget);
    final snapshot = await store.read();
    expect(snapshot.workouts, hasLength(1));
    expect(
      snapshot.workouts.single[TrainingJsonKeys.exercises],
      contains(containsPair(TrainingJsonKeys.name, '杠铃卧推')),
    );
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<({PrefsLocalStore store, WorkoutSession open})> _pumpWithOpenSession(
  WidgetTester tester,
) async {
  final store = await _emptyStore();
  final open = _session(
    id: 'w-open',
    startedAt: DateTime.now().subtract(const Duration(hours: 1)),
    name: _openExerciseName,
  );
  await store.write(
    LocalStoreSnapshot.empty().copyWith(
      settings: <String, Object?>{
        PlanJsonKeys.settingsKey: _todayPlan().toJson(),
      },
      workouts: <Map<String, Object?>>[open.toJson()],
    ),
  );
  await tester.pumpWidget(
    CurveFreeApp(localStore: store, skipOnboarding: true),
  );
  await _settle(tester);
  return (store: store, open: open);
}

Future<void> _expectResumed(
  WidgetTester tester,
  PrefsLocalStore store,
  String sessionId,
) async {
  expect(find.text(_openExerciseName), findsOneWidget);
  expect(find.text(AppStrings.workoutInProgress), findsWidgets);
  final snapshot = await store.read();
  expect(snapshot.workouts, hasLength(1));
  expect(snapshot.workouts.single[TrainingJsonKeys.id], sessionId);
  expect(
    snapshot.workouts.single[TrainingJsonKeys.exercises],
    contains(containsPair(TrainingJsonKeys.name, _openExerciseName)),
  );
}

Future<PrefsLocalStore> _emptyStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return PrefsLocalStore(preferences: prefs);
}

final class _Harness {
  _Harness(this.container);

  final ProviderContainer container;

  WorkoutSessionsController get notifier =>
      container.read(workoutSessionsProvider.notifier);

  List<WorkoutSession> get sessions =>
      container.read(workoutSessionsProvider).requireValue;
}

Future<_Harness> _harness({List<WorkoutSession> workouts = const []}) async {
  final store = await _emptyStore();
  if (workouts.isNotEmpty) {
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        workouts: <Map<String, Object?>>[
          for (final WorkoutSession session in workouts) session.toJson(),
        ],
      ),
    );
  }
  final container = ProviderContainer(
    overrides: [localStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  await container.read(workoutSessionsProvider.future);
  await container.read(localStoreSnapshotProvider.future);
  return _Harness(container);
}

WorkoutSession _session({
  required String id,
  required DateTime startedAt,
  required String name,
  DateTime? endedAt,
}) {
  return WorkoutSession(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    notes: '',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-$id',
        name: name,
        sets: <WorkoutSet>[
          WorkoutSet(id: 's-$id', weightKg: 90, reps: 5, completed: true),
        ],
      ),
    ],
  );
}

TrainingPlan _todayPlan() {
  return TrainingPlan(
    goal: TrainingGoal.hypertrophy,
    daysPerWeek: 3,
    equipment: EquipmentProfile.fullGym,
    sessions: <PlannedSession>[_pushDay(weekday: DateTime.now().weekday)],
  );
}

PlannedSession _pushDay({int weekday = DateTime.monday}) {
  return PlannedSession(
    weekday: weekday,
    title: '推',
    items: const <PlannedItem>[
      PlannedItem(
        catalogId: 'ex_barbell_bench',
        nameZh: '杠铃卧推',
        sets: 3,
        reps: 8,
      ),
    ],
  );
}

PlannedSession _pullDay() {
  return const PlannedSession(
    weekday: DateTime.tuesday,
    title: '拉',
    items: <PlannedItem>[
      PlannedItem(catalogId: 'ex_row', nameZh: '杠铃划船', sets: 3, reps: 8),
    ],
  );
}
