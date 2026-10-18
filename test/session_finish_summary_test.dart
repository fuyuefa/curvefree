import 'package:curvefree/app/app.dart';
import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/pages/session_finish_summary_page.dart';
import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:curvefree/features/training/previous_sets.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String exerciseName = '深蹲';
  const double completedWeightKg = 100;
  const int completedReps = 5;

  Future<PrefsLocalStore> seededStore() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PrefsLocalStore store = PrefsLocalStore(preferences: prefs);
    final WorkoutSession session = WorkoutSession.create().copyWith(
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e-summary',
          name: exerciseName,
          sets: <WorkoutSet>[
            WorkoutSet(
              id: 's-done',
              weightKg: completedWeightKg,
              reps: completedReps,
              completed: true,
            ),
            WorkoutSet(id: 's-open', weightKg: 80, reps: 5, completed: false),
          ],
        ),
      ],
    );
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        workouts: <Map<String, Object?>>[session.toJson()],
      ),
    );
    return store;
  }

  Future<void> openFromTraining(
    WidgetTester tester,
    PrefsLocalStore store,
  ) async {
    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('nav_training')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.textContaining(AppStrings.workoutInProgress));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> confirmFinish(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('btn_finish_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('btn_confirm_finish')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  void expectCopyHasNoFullStop(String copy) {
    expect(copy.contains('。'), isFalse);
  }

  testWidgets('finish opens a summary, then 回到今日 selects today', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await seededStore();
    final String sessionId = (await store.read()).workouts.single['id']!
        .toString();
    await openFromTraining(tester, store);
    await confirmFinish(tester);

    expect(find.byKey(const Key('session_finish_summary')), findsOneWidget);
    expect(find.text(AppStrings.sessionDoneTitle), findsOneWidget);
    expect(find.text(AppStrings.backToToday), findsOneWidget);
    expect(find.text(AppStrings.reviewThisSession), findsOneWidget);
    expectCopyHasNoFullStop(AppStrings.sessionDoneTitle);
    expectCopyHasNoFullStop(AppStrings.backToToday);
    expectCopyHasNoFullStop(AppStrings.reviewThisSession);
    expectCopyHasNoFullStop(AppStrings.finishSessionConfirmBody);

    final BuildContext summaryContext = tester.element(
      find.byKey(const Key('session_finish_summary')),
    );
    expect(
      ModalRoute.of(summaryContext)?.settings.name,
      SessionRoutes.doneNameFor(sessionId),
    );
    expect(
      Theme.of(summaryContext).colorScheme.primary,
      CurvePalette.light.primary,
    );
    expect(CurveColors.of(summaryContext).screen, CurvePalette.light.screen);
    expect(
      tester.widget<Text>(find.byKey(const Key('summary_sets_value'))).data,
      '1',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('summary_volume_value'))).data,
      '500',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('summary_wall_value'))).data,
      contains(':'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('summary_rest_value'))).data,
      '00:00',
    );
    expect(find.text(AppStrings.setsCountLabel), findsWidgets);
    expect(find.text(AppStrings.volumeLabel), findsWidgets);
    expect(find.text(AppStrings.wallClockLabel), findsOneWidget);
    expect(find.text(AppStrings.restTimerLabel), findsOneWidget);
    expect(find.text(AppStrings.workoutCompleted), findsNothing);
    expect(find.byKey(const Key('btn_finish_workout')), findsNothing);
    expect(
      (await store.read()).workouts.single[TrainingJsonKeys.endedAt],
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('btn_back_to_today')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator),
    );
    expect(navigator.canPop(), isFalse);
    expect(find.byType(SessionFinishSummaryPage), findsNothing);
    expect(find.byType(SessionPage), findsNothing);
    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
    expect(find.text(AppStrings.trainingLogTitle), findsNothing);
    expect(find.text(exerciseName), findsNothing);
    expect(find.byKey(const Key('workout_float_bubble')), findsNothing);
    expect((await store.read()).workouts, hasLength(1));
  });

  testWidgets('再看看这堂 returns to the finished session read-only', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await seededStore();
    await openFromTraining(tester, store);
    await confirmFinish(tester);

    await tester.tap(find.byKey(const Key('btn_review_session')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('session_finish_summary')), findsNothing);
    expect(find.text(exerciseName), findsOneWidget);
    expect(find.text(AppStrings.workoutFinished), findsOneWidget);
    expect(find.byKey(const Key('btn_finish_workout')), findsNothing);
    expect(find.byKey(const Key('btn_add_exercise')), findsNothing);
    expect(find.byKey(const Key('btn_add_set')), findsNothing);
    expect(find.text(AppStrings.trainingLogTitle), findsNothing);

    await tester.tap(find.text(formatWeightKg(completedWeightKg)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('keypad_buffer')), findsNothing);

    await tester.tap(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final WorkoutSession stored = WorkoutSession.fromJson(
      Map<String, Object?>.from((await store.read()).workouts.single),
    );
    expect(stored.isFinished, isTrue);
    expect(stored.exercises.single.sets.first.completed, isTrue);
    expect(stored.exercises.single.sets.first.weightKg, completedWeightKg);
    expect(stored.exercises.single.sets.length, 2);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.trainingLogTitle), findsOneWidget);
    expect(find.byKey(const Key('home_today_title')), findsNothing);
  });
}
