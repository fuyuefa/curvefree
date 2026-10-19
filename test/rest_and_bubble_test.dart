import 'package:curvefree/app/app.dart';
import 'package:curvefree/app/shell/app_shell.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:curvefree/features/training/rest_end_flash.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:curvefree/features/training/widgets/session_summary_bar.dart';
import 'package:curvefree/features/training/workout_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    test('closed rests accumulate and the open countdown stays separate', () {
      final RestTimerState first = const RestTimerState().restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-1',
        now: start,
      );
      final DateTime mid = start.add(const Duration(seconds: 20));
      final RestTimerState second = first.restarted(
        sessionId: 'w-1',
        exerciseId: 'e-1',
        setId: 's-2',
        now: mid,
      );
      expect(second.restTotalFor('w-1', mid), const Duration(seconds: 20));
      final DateTime later = mid.add(const Duration(seconds: 10));
      expect(second.restTotalFor('w-1', later), const Duration(seconds: 30));
      expect(second.restTotalFor('w-other', later), isNull);

      final RestTimerState paused = second.skipped(now: later);
      expect(paused.sessionId, isNull);
      expect(paused.restTotalFor('w-1', later), const Duration(seconds: 30));
      expect(paused.clearedIfSession('w-1').restTotalFor('w-1', later), isNull);
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

    test('rest countdown replaces the elapsed primary line', () {
      const Duration elapsed = Duration(minutes: 32, seconds: 10);
      final WorkoutBubbleLines training = workoutBubbleLines(
        elapsed: elapsed,
        resting: false,
        restRemaining: const Duration(seconds: 45),
      );
      expect(training.primary, '训练中 32:10');
      expect(training.secondary, isNull);

      final WorkoutBubbleLines rest = workoutBubbleLines(
        elapsed: elapsed,
        resting: true,
        restRemaining: const Duration(seconds: 45),
      );
      expect(rest.primary, '休息 0:45');
      expect(rest.secondary, '训练中 32:10');

      final WorkoutBubbleLines done = workoutBubbleLines(
        elapsed: elapsed,
        resting: true,
        restRemaining: Duration.zero,
      );
      expect(done.primary, '训练中 32:10');
      expect(done.secondary, isNull);
    });

    test('float resume targets the session route and does not start one', () {
      const String sessionId = 'w-open';
      final String routeName = SessionRoutes.nameFor(sessionId);
      expect(
        planFloatResume(
          sessionId: sessionId,
          topPageRouteName: routeName,
          pageRouteNames: <String?>[Navigator.defaultRouteName, routeName],
        ).kind,
        FloatResumeKind.stay,
      );
      final FloatResume buried = planFloatResume(
        sessionId: sessionId,
        topPageRouteName: '/exercises',
        pageRouteNames: <String?>[
          Navigator.defaultRouteName,
          routeName,
          '/exercises',
        ],
      );
      expect(buried.kind, FloatResumeKind.popToSession);
      expect(buried.routeName, routeName);
      final FloatResume missing = planFloatResume(
        sessionId: sessionId,
        topPageRouteName: Navigator.defaultRouteName,
        pageRouteNames: <String?>[Navigator.defaultRouteName],
      );
      expect(missing.kind, FloatResumeKind.pushSession);
      expect(missing.routeName, routeName);
      expect(missing.routeName, isNot(SessionRoutes.nameFor('w-other')));
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
    final AnimatedContainer bar = tester.widget<AnimatedContainer>(
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
      final List<MethodCall> haptic = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptic.add(call);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
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
      expect(
        haptic.where(
          (MethodCall call) =>
              call.arguments == 'HapticFeedbackType.mediumImpact',
        ),
        isEmpty,
      );
      expect(haptic.single.arguments, 'HapticFeedbackType.lightImpact');
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
      expect(find.byKey(const Key('session_finish_summary')), findsOneWidget);
      expect(find.byKey(const Key('btn_minimize_session')), findsNothing);
      expect(_restFromShell(tester).sessionId, isNull);
      expect(_endedAt(await store.read()), isNotNull);

      await tester.tap(find.byKey(const Key('btn_back_to_today')));
      await _settle(tester);
      expect(find.byKey(const Key('home_today_title')), findsOneWidget);
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

  testWidgets('minimize shows the rest countdown and resumes that session', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seed();
    final String sessionId = (await store.read()).workouts.single['id']!
        .toString();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    expect(find.byKey(const Key('btn_minimize_session')), findsOneWidget);
    expect(find.text(AppStrings.minimizeSession), findsOneWidget);

    await tester.tap(find.byKey(const Key('set_complete_0')));
    await _settle(tester);
    _pinClock(tester);
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('btn_rest_minus')));
      await _settle(tester);
    }
    expect(find.text('00:45'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_minimize_session')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
    expect(find.byKey(const Key('btn_finish_workout')), findsNothing);
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);
    final Text primary = tester.widget<Text>(
      find.byKey(const Key('workout_float_primary')),
    );
    expect(primary.data, '${AppStrings.restBubbleLabel} 0:45');
    expect(primary.style?.color, CurvePalette.light.primary);
    final Text elapsed = tester.widget<Text>(
      find.byKey(const Key('workout_float_elapsed')),
    );
    expect(elapsed.data, contains(AppStrings.workoutBubbleLabel));
    expect(elapsed.style?.color, CurvePalette.light.textSecondary);
    expect(find.byKey(const Key('today_conflict_sheet')), findsNothing);

    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    final SessionPage page = tester.widget<SessionPage>(
      find.byType(SessionPage),
    );
    expect(page.sessionId, sessionId);
    expect(
      ModalRoute.of(tester.element(find.byType(SessionPage)))?.settings.name,
      SessionRoutes.nameFor(sessionId),
    );
    expect(find.text('00:45'), findsOneWidget);
    expect(find.byKey(const Key('today_conflict_sheet')), findsNothing);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    expect((await store.read()).workouts, hasLength(1));
    expect(
      (await store.read()).workouts.single[TrainingJsonKeys.id],
      sessionId,
    );
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

    final AnimatedContainer chip = tester.widget<AnimatedContainer>(
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
    final AnimatedContainer darkChip = tester.widget<AnimatedContainer>(
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

  testWidgets('natural rest end flashes the bar and the float', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> haptic = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptic.add(call);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final PrefsLocalStore store = await _seed();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('set_complete_0')));
    await _settle(tester);

    final _PinnedClock clock = _pinClock(tester);
    final RestTimerState running = _rest(tester);
    clock.moment = running.endsAt!;
    expect(_controller(tester).noteNaturalEnd(clock.moment), isTrue);
    await tester.pump();

    final AnimatedContainer bar = tester.widget<AnimatedContainer>(
      find.byKey(const Key('rest_timer_bar')),
    );
    expect(
      (bar.decoration! as BoxDecoration).color,
      restEndPeakFill(
        idle: CurvePalette.light.primarySoft,
        primarySoft: CurvePalette.light.primarySoft,
        primary: CurvePalette.light.primary,
      ),
    );
    expect(haptic.last.arguments, 'HapticFeedbackType.mediumImpact');

    await tester.pump(AppMotion.restEndFlash);
    expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
    expect(_rest(tester).endFlashUntil, isNull);

    await tester.tap(find.byKey(const Key('set_complete_1')));
    await _settle(tester);
    final _PinnedClock again = _pinClock(tester);
    final DateTime floatEnd = _rest(tester).endsAt!;
    await tester.tap(find.byKey(const Key('btn_minimize_session')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('workout_float_bubble')), findsOneWidget);

    again.moment = floatEnd;
    final RestTimerController controller = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    ).read(restTimerProvider.notifier);
    expect(controller.noteNaturalEnd(floatEnd), isTrue);
    await tester.pump();
    final AnimatedContainer chip = tester.widget<AnimatedContainer>(
      find.byKey(const Key('workout_float_bubble')),
    );
    expect(
      (chip.decoration! as BoxDecoration).color,
      CurvePalette.light.primarySoft,
    );
    expect(
      haptic.where(
        (MethodCall call) =>
            call.arguments == 'HapticFeedbackType.mediumImpact',
      ),
      hasLength(2),
    );

    await tester.pump(AppMotion.restEndFlash);
    final AnimatedContainer settled = tester.widget<AnimatedContainer>(
      find.byKey(const Key('workout_float_bubble')),
    );
    expect(
      (settled.decoration! as BoxDecoration).color,
      CurvePalette.light.elevated,
    );
    expect(_restFromShell(tester).endFlashUntil, isNull);
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
