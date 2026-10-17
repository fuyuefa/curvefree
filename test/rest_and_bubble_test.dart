import 'package:curvefree/app/app.dart';
import 'package:curvefree/app/shell/app_shell.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:curvefree/features/training/widgets/session_summary_bar.dart';
import 'package:curvefree/features/training/workout_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _exerciseName = '深蹲';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RestTimerState', () {
    final DateTime start = DateTime.utc(2026, 10, 17, 8);

    test('starts at the default and restart moves the end forward', () {
      const RestTimerState idle = RestTimerState();
      expect(idle.preferredSeconds, RestTimerLimits.defaultSeconds);
      expect(idle.isRunningAt(start), isFalse);

      final RestTimerState running = idle.restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-1',
        now: start,
      );
      expect(
        running.endsAt,
        start.add(const Duration(seconds: RestTimerLimits.defaultSeconds)),
      );
      expect(running.remainingAt(start), const Duration(seconds: 90));

      final DateTime later = start.add(const Duration(seconds: 20));
      final RestTimerState restarted = running.restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-2',
        now: later,
      );
      expect(restarted.setId, 's-2');
      expect(
        restarted.endsAt,
        later.add(const Duration(seconds: RestTimerLimits.defaultSeconds)),
      );
      expect(restarted.remainingAt(later), const Duration(seconds: 90));
      expect(running.endsAt == restarted.endsAt, isFalse);
    });

    test('adjust, skip, and clear keep the preferred length', () {
      final RestTimerState running = const RestTimerState().restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-1',
        now: start,
      );
      final RestTimerState longer = running.adjustedBy(
        RestTimerLimits.stepSeconds,
        start,
      );
      expect(longer.preferredSeconds, 105);
      expect(longer.remainingAt(start), const Duration(seconds: 105));

      final RestTimerState skipped = longer.skipped();
      expect(skipped.sessionId, isNull);
      expect(skipped.preferredSeconds, 105);
      expect(skipped.isRunningAt(start), isFalse);

      final RestTimerState again = skipped.restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-2',
        now: start,
      );
      expect(again.remainingAt(start), const Duration(seconds: 105));

      final RestTimerState other = again.clearedIfSession('w-other');
      expect(other.sessionId, 'w-1');
      expect(again.clearedIfSession('w-1').sessionId, isNull);
    });

    test('shortening past zero ends the countdown', () {
      RestTimerState rest = const RestTimerState().restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-1',
        now: start,
      );
      for (int i = 0; i < 5; i++) {
        rest = rest.adjustedBy(-RestTimerLimits.stepSeconds, start);
        expect(rest.isRunningAt(start), isTrue);
      }
      rest = rest.adjustedBy(-RestTimerLimits.stepSeconds, start);
      expect(rest.isRunningAt(start), isFalse);
      expect(rest.preferredSeconds, RestTimerLimits.minSeconds);
    });
  });

  group('workout bubble visibility', () {
    final WorkoutSession open = _session(id: 'w-open');
    final String sessionRoute = SessionRoutes.nameFor(open.id);

    test('shows off the session page and hides on it or when finished', () {
      expect(
        workoutBubbleVisible(
          unfinished: open,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isTrue,
      );
      expect(
        workoutBubbleVisible(
          unfinished: open,
          topPageRouteName: null,
          coveredByPopup: false,
        ),
        isTrue,
      );
      expect(
        workoutBubbleVisible(
          unfinished: open,
          topPageRouteName: sessionRoute,
          coveredByPopup: false,
        ),
        isFalse,
      );
      expect(
        workoutBubbleVisible(
          unfinished: open,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: true,
        ),
        isFalse,
      );
      expect(
        workoutBubbleVisible(
          unfinished: null,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isFalse,
      );
      expect(
        workoutBubbleVisible(
          unfinished: _session(
            id: 'w-done',
            endedAt: DateTime.utc(2026, 10, 17, 9),
          ),
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isFalse,
      );
    });

    test('empty draft does not look like a timed workout', () {
      final DateTime createdAt = DateTime.utc(2026, 10, 17, 8);
      final WorkoutSession draft = WorkoutSession.create(startedAt: createdAt);
      expect(draft.isTimerRunning, isFalse);
      expect(draft.timerOrigin, isNull);
      expect(
        workoutBubbleVisible(
          unfinished: draft,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isFalse,
      );

      final WorkoutSession live = draft.copyWith(
        exercises: const <WorkoutExercise>[
          WorkoutExercise(
            id: 'e-1',
            name: '杠铃卧推',
            catalogId: 'ex_barbell_bench',
            sets: <WorkoutSet>[],
          ),
        ],
        timerStartedAt: DateTime.utc(2026, 10, 17, 8, 5),
      );
      expect(live.timerOrigin, DateTime.utc(2026, 10, 17, 8, 5));
      expect(live.startedAt, createdAt);
      expect(live.isTimerRunning, isTrue);
      expect(
        workoutBubbleVisible(
          unfinished: live,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isTrue,
      );
      expect(
        workoutBubbleVisible(
          unfinished: live,
          topPageRouteName: SessionRoutes.nameFor(live.id),
          coveredByPopup: false,
        ),
        isFalse,
      );

      final WorkoutSession cleared = live.copyWith(
        exercises: const <WorkoutExercise>[],
      );
      expect(cleared.isTimerRunning, isFalse);
      expect(
        workoutBubbleVisible(
          unfinished: cleared,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isFalse,
      );

      final WorkoutSession finished = live.copyWith(
        endedAt: DateTime.utc(2026, 10, 17, 9),
      );
      expect(finished.isTimerRunning, isFalse);
      expect(
        workoutBubbleVisible(
          unfinished: finished,
          topPageRouteName: Navigator.defaultRouteName,
          coveredByPopup: false,
        ),
        isFalse,
      );

      final WorkoutSession legacy = WorkoutSession.fromJson(<String, Object?>{
        'id': 'w-legacy',
        'startedAt': createdAt.toIso8601String(),
        'exercises': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'e-legacy',
            'name': '杠铃卧推',
            'catalogId': 'ex_barbell_bench',
            'sets': <Map<String, Object?>>[],
          },
        ],
      });
      expect(legacy.timerOrigin, createdAt);
      expect(legacy.isTimerRunning, isTrue);
    });

    test('shell tabs sit above the bottom nav', () {
      expect(
        workoutBubbleBottomInset(
          topPageRouteName: Navigator.defaultRouteName,
          safeBottom: 0,
        ),
        AppLayout.bottomNavHeight + AppSpacing.sm,
      );
      expect(
        workoutBubbleBottomInset(topPageRouteName: null, safeBottom: 8),
        8 + AppSpacing.sm,
      );
    });
  });

  testWidgets('completing a set starts rest; another set restarts it', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seed();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);

    expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
    expect(find.byKey(const Key('session_summary')), findsOneWidget);
    expect(find.byType(ElapsedClock), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);

    await tester.tap(find.byKey(const Key('set_complete_0')));
    await _settle(tester);
    final _PinnedClock clock = _pinClock(tester);
    await tester.pump(RestTimerLimits.tick);
    await tester.pump();
    expect(find.text('01:30'), findsOneWidget);
    expect(find.textContaining(_exerciseName), findsWidgets);
    final Container bar = tester.widget<Container>(
      find.byKey(const Key('rest_timer_bar')),
    );
    expect(
      (bar.decoration! as BoxDecoration).color,
      CurvePalette.light.primarySoft,
    );
    final DateTime firstEnd = _rest(tester).endsAt!;

    clock.moment = clock.moment.add(const Duration(seconds: 20));
    await tester.pump(RestTimerLimits.tick);
    await tester.pump();
    expect(find.text('01:10'), findsOneWidget);

    await _popRoute(tester);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);
    expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    expect(find.text('01:10'), findsOneWidget);
    expect((await store.read()).workouts, hasLength(1));

    await tester.tap(find.byKey(const Key('set_complete_1')));
    await _settle(tester);
    expect(find.text('01:30'), findsOneWidget);
    expect(
      _rest(tester).endsAt,
      clock.moment.add(const Duration(seconds: RestTimerLimits.defaultSeconds)),
    );
    expect(_rest(tester).endsAt, isNot(firstEnd));
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
  });

  testWidgets(
    'skip, adjust, finish, and delete clear rest without a new session',
    (WidgetTester tester) async {
      final PrefsLocalStore store = await _seed();
      await _pump(tester, store);
      await tester.tap(find.byKey(const Key('workout_float_bubble')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('set_complete_0')));
      await _settle(tester);
      _pinClock(tester);
      await tester.pump(RestTimerLimits.tick);
      await tester.pump();
      expect(find.text('01:30'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_rest_plus')));
      await _settle(tester);
      expect(find.text('01:45'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_rest_minus')));
      await _settle(tester);
      expect(find.text('01:30'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_rest_skip')));
      await _settle(tester);
      expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
      expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
      expect(_endedAt(await store.read()), isNull);

      await tester.tap(find.byKey(const Key('set_complete_1')));
      await _settle(tester);
      expect(find.text('01:30'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_finish_workout')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('btn_confirm_finish')));
      await _settle(tester);
      expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
      expect(find.text(AppStrings.workoutFinished), findsOneWidget);
      expect(_restFromShell(tester).sessionId, isNull);
      expect(_endedAt(await store.read()), isNotNull);

      await _popRoute(tester);
      expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
      expect((await store.read()).workouts, hasLength(1));
    },
  );

  testWidgets('delete drops rest and the bubble', (WidgetTester tester) async {
    final PrefsLocalStore store = await _seed();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('set_complete_0')));
    await _settle(tester);
    expect(find.byKey(const Key('rest_timer_bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_delete_workout')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('btn_confirm_delete')));
    await _settle(tester);

    expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    expect((await store.read()).workouts, isEmpty);
    expect(_restFromShell(tester).sessionId, isNull);
  });

  testWidgets('bubble shows on shell tabs and resumes the same session', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seed();
    final String sessionId = (await store.read()).workouts.single['id']!
        .toString();
    await _pump(tester, store);

    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);
    expect(find.textContaining(AppStrings.workoutBubbleLabel), findsOneWidget);
    final Rect bubble = tester.getRect(
      find.byKey(const Key('workout_float_bubble')),
    );
    final Rect todayNav = tester.getRect(find.byKey(const Key('nav_today')));
    expect(bubble.overlaps(todayNav), isFalse);

    final Container chip = tester.widget<Container>(
      find.byKey(const Key('workout_float_bubble')),
    );
    expect(
      (chip.decoration! as BoxDecoration).color,
      CurvePalette.light.elevated,
    );

    await tester.tap(find.byKey(const Key('nav_nutrition')));
    await _settle(tester);
    expect(find.byKey(const Key('nutri_title')), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_me')));
    await _settle(tester);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('btn_export_backup')));
    await tester.tap(find.byKey(const Key('btn_export_backup')));
    await _settle(tester);
    expect(find.byKey(const Key('dialog_export_backup')), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    await tester.tap(find.text(AppStrings.cancel));
    await _settle(tester);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme_dark')));
    await _settle(tester);
    final Container darkChip = tester.widget<Container>(
      find.byKey(const Key('workout_float_bubble')),
    );
    expect(
      (darkChip.decoration! as BoxDecoration).color,
      CurvePalette.dark.elevated,
    );

    await tester.tap(find.byKey(const Key('nav_training')));
    await _settle(tester);
    expect(find.byKey(const Key('btn_start_workout')), findsOneWidget);
    final Rect fab = tester.getRect(find.byKey(const Key('btn_start_workout')));
    final Rect trainingBubble = tester.getRect(
      find.byKey(const Key('workout_float_bubble')),
    );
    expect(trainingBubble.overlaps(fab), isFalse);
    expect(
      trainingBubble.overlaps(
        tester.getRect(find.byKey(const Key('nav_training'))),
      ),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('nav_today')));
    await _settle(tester);
    expect(find.byKey(const Key('home_today_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    expect(find.text(_exerciseName), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
    final LocalStoreSnapshot snapshot = await store.read();
    expect(snapshot.workouts, hasLength(1));
    expect(snapshot.workouts.single[TrainingJsonKeys.id], sessionId);
  });

  testWidgets('bubble on the plan page resumes without a second session', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seed();
    await _pump(tester, store);
    final double shellBottom = tester
        .getRect(find.byKey(const Key('workout_float_bubble')))
        .bottom;

    await tester.tap(find.byKey(const Key('nav_training')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('btn_open_plan')));
    await _settle(tester);
    expect(find.text(AppStrings.trainingPlanTitle), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('workout_float_bubble'))).bottom,
      greaterThan(shellBottom),
    );

    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    expect((await store.read()).workouts, hasLength(1));
  });

  testWidgets('bubble on the exercise picker returns to the open session', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seed();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('btn_add_exercise')));
    await _settle(tester);
    expect(find.text(AppStrings.pickExercise), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);

    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(AppStrings.pickExercise), findsNothing);
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);

    await _popRoute(tester);
    expect(find.byKey(const Key('btn_finish_workout')), findsNothing);
    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);
    expect((await store.read()).workouts, hasLength(1));
  });

  testWidgets('no bubble when every session is finished', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seed(
      endedAt: DateTime.utc(2026, 10, 17, 9),
    );
    await _pump(tester, store);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    expect(find.text(AppStrings.navToday), findsWidgets);
  });
}

final class _PinnedClock {
  _PinnedClock(this.moment);

  DateTime moment;

  DateTime read() => moment;
}

Future<void> _popRoute(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pump(WidgetTester tester, PrefsLocalStore store) async {
  await tester.pumpWidget(
    CurveFreeApp(localStore: store, skipOnboarding: true),
  );
  await _settle(tester);
}

RestTimerState _rest(WidgetTester tester) {
  return ProviderScope.containerOf(tester.element(find.byType(SessionPage)))
      .read(restTimerProvider);
}

RestTimerState _restFromShell(WidgetTester tester) {
  final Finder session = find.byType(SessionPage);
  final BuildContext context = session.evaluate().isEmpty
      ? tester.element(find.byType(AppShell))
      : tester.element(session);
  return ProviderScope.containerOf(context).read(restTimerProvider);
}

RestTimerController _controller(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byKey(const Key('rest_timer_bar'))),
  ).read(restTimerProvider.notifier);
}

_PinnedClock _pinClock(WidgetTester tester) {
  final RestTimerState rest = _rest(tester);
  final DateTime origin = rest.endsAt!.subtract(
    Duration(seconds: rest.preferredSeconds),
  );
  final _PinnedClock clock = _PinnedClock(origin);
  _controller(tester).clock = clock.read;
  return clock;
}

Object? _endedAt(LocalStoreSnapshot snapshot) {
  return snapshot.workouts.single[TrainingJsonKeys.endedAt];
}

Future<PrefsLocalStore> _seed({DateTime? endedAt}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final PrefsLocalStore store = PrefsLocalStore(preferences: prefs);
  await store.write(
    LocalStoreSnapshot.empty().copyWith(
      workouts: <Map<String, Object?>>[
        _session(id: 'w-rest', endedAt: endedAt).toJson(),
      ],
    ),
  );
  return store;
}

WorkoutSession _session({required String id, DateTime? endedAt}) {
  return WorkoutSession(
    id: id,
    startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    endedAt: endedAt,
    notes: '',
    exercises: const <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-rest',
        name: _exerciseName,
        sets: <WorkoutSet>[
          WorkoutSet(id: 's-1', weightKg: 80, reps: 5, completed: false),
          WorkoutSet(id: 's-2', weightKg: 80, reps: 5, completed: false),
        ],
      ),
    ],
  );
}
