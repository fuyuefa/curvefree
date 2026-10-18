import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('previous column fills the row and check focuses the next set', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await _seedHistory();
    await _pump(tester, store);

    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);

    expect(find.text('40×8'), findsOneWidget);
    expect(find.text('42.5×6'), findsOneWidget);
    expect(find.text(AppStrings.previousEmpty), findsOneWidget);
    expect(find.text(AppStrings.lastHintPrefix), findsOneWidget);
    expect(find.text(AppStrings.checkColumn), findsOneWidget);
    expect(find.text('20'), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('previous_set_0')));
    await _settle(tester);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('20'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('set_complete_0')));
    await _settle(tester);

    final Container done = tester.widget<Container>(
      find.byKey(const Key('set_row_0')),
    );
    expect(
      (done.decoration! as BoxDecoration).color,
      CurvePalette.light.successSoft,
    );
    final Container focused = tester.widget<Container>(
      find.byKey(const Key('set_row_1')),
    );
    final Border border =
        (focused.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, CurvePalette.light.primary);
    expect(border.top.width, AppLayout.focusBorderWidth);
    expect(
      (focused.decoration! as BoxDecoration).color,
      CurvePalette.light.muted,
    );

    expect(find.text(AppStrings.restEnoughNextSet), findsOneWidget);
    expect(find.text('先不休息'), findsNothing);
    final Text countdown = tester.widget<Text>(
      find.byKey(const Key('rest_timer_remaining')),
    );
    expect(countdown.style?.fontSize, AppLayout.restCountdownSize);
    expect(countdown.style?.color, CurvePalette.light.primary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checking a set scrolls the next open set into view', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final PrefsLocalStore store = await _seedLongSession();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);

    final Finder list = find.descendant(
      of: find.byType(SessionPage),
      matching: find.byType(ListView),
    );
    final Rect before = tester.getRect(find.byKey(const Key('set_row_5')));
    expect(before.top, greaterThan(tester.getRect(list).bottom));

    await tester.ensureVisible(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    await tester.pump(AppMotion.restCollapse);
    await tester.pump();

    final Rect listRect = tester.getRect(list);
    final Rect after = tester.getRect(find.byKey(const Key('set_row_5')));
    expect(after.top, greaterThanOrEqualTo(listRect.top - 1));
    expect(after.bottom, lessThanOrEqualTo(listRect.bottom + 1));
    final Border border =
        (tester
                        .widget<Container>(find.byKey(const Key('set_row_5')))
                        .decoration!
                    as BoxDecoration)
                .border!
            as Border;
    expect(border.top.color, CurvePalette.light.primary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest countdown collapse plays a light haptic at zero', (
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

    final PrefsLocalStore store = await _seedHistory();
    await _pump(tester, store);
    await tester.tap(find.byKey(const Key('workout_float_bubble')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('set_complete_0')));
    await _settle(tester);

    final RestTimerState rest = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    ).read(restTimerProvider);
    final DateTime origin = rest.endsAt!.subtract(
      Duration(seconds: rest.preferredSeconds),
    );
    final RestTimerController controller = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('rest_timer_bar'))),
    ).read(restTimerProvider.notifier);
    DateTime moment = origin;
    controller.clock = () => moment;

    moment = origin.add(Duration(seconds: rest.preferredSeconds));
    await tester.pump(RestTimerLimits.tick);
    await tester.pump();
    expect(haptic, hasLength(1));
    expect(haptic.single.arguments, 'HapticFeedbackType.lightImpact');

    await tester.pump(AppMotion.restCollapse);
    expect(find.byKey(const Key('rest_timer_bar')), findsNothing);
    expect(
      tester
          .widget<AnimatedSize>(
            find.descendant(
              of: find.byType(SessionPage),
              matching: find.byType(AnimatedSize),
            ),
          )
          .duration,
      AppMotion.restCollapse,
    );
    expect(tester.takeException(), isNull);
  });
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

Future<PrefsLocalStore> _seedHistory() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final PrefsLocalStore store = PrefsLocalStore(preferences: prefs);
  final DateTime now = DateTime.utc(2026, 10, 18, 8);
  final WorkoutSession previous = WorkoutSession(
    id: 'w-prev',
    startedAt: now.subtract(const Duration(days: 3)),
    endedAt: now.subtract(const Duration(days: 3)),
    notes: '',
    exercises: const <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-prev',
        name: '深蹲',
        sets: <WorkoutSet>[
          WorkoutSet(id: 'p0', weightKg: 40, reps: 8, completed: true),
          WorkoutSet(id: 'p1', weightKg: 42.5, reps: 6, completed: true),
        ],
      ),
    ],
  );
  final WorkoutSession current = WorkoutSession(
    id: 'w-now',
    startedAt: now,
    endedAt: null,
    notes: '',
    exercises: const <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-now',
        name: '深蹲',
        sets: <WorkoutSet>[
          WorkoutSet(id: 'c0', weightKg: 20, reps: 5, completed: false),
          WorkoutSet(id: 'c1', weightKg: 20, reps: 5, completed: false),
          WorkoutSet(id: 'c2', weightKg: 20, reps: 5, completed: false),
        ],
      ),
    ],
  );
  await store.write(
    LocalStoreSnapshot.empty().copyWith(
      workouts: <Map<String, Object?>>[current.toJson(), previous.toJson()],
    ),
  );
  return store;
}

Future<PrefsLocalStore> _seedLongSession() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final PrefsLocalStore store = PrefsLocalStore(preferences: prefs);
  final WorkoutSession current = WorkoutSession(
    id: 'w-long',
    startedAt: DateTime.utc(2026, 10, 18, 8),
    endedAt: null,
    notes: '',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-long',
        name: '硬拉',
        sets: <WorkoutSet>[
          for (int i = 0; i < 6; i++)
            WorkoutSet(
              id: 's$i',
              weightKg: 60,
              reps: 5,
              completed: i > 0 && i < 5,
            ),
        ],
      ),
    ],
  );
  await store.write(
    LocalStoreSnapshot.empty().copyWith(
      workouts: <Map<String, Object?>>[current.toJson()],
    ),
  );
  return store;
}
