import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
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
          id: 'e-confirm',
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

  Future<void> openSession(WidgetTester tester, PrefsLocalStore store) async {
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
    expect(find.text(exerciseName), findsOneWidget);
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
  }

  testWidgets('finish asks first; cancel keeps the session open', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await seededStore();
    await openSession(tester, store);

    await tester.tap(find.byKey(const Key('btn_finish_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dialog_finish_session')), findsOneWidget);
    expect(find.text(AppStrings.finishSessionConfirmTitle), findsOneWidget);
    expect(find.text(AppStrings.finishSessionConfirmBody), findsOneWidget);
    expect(find.byKey(const Key('session_finish_summary')), findsNothing);
    expect(
      (await store.read()).workouts.single[TrainingJsonKeys.endedAt],
      isNull,
    );

    await tester.tap(find.byKey(const Key('btn_keep_logging_sets')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dialog_finish_session')), findsNothing);
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
    expect(find.text(AppStrings.workoutCompleted), findsNothing);
    expect(find.text(exerciseName), findsOneWidget);
    expect(
      (await store.read()).workouts.single[TrainingJsonKeys.endedAt],
      isNull,
    );

    await tester.tap(find.byKey(const Key('btn_finish_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('btn_confirm_finish')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('session_finish_summary')), findsOneWidget);
    expect(find.text(AppStrings.sessionDoneTitle), findsOneWidget);
    expect(find.text(AppStrings.workoutCompleted), findsNothing);
    expect(find.byKey(const Key('btn_finish_workout')), findsNothing);
    expect(
      ModalRoute.of(
        tester.element(find.byKey(const Key('session_finish_summary'))),
      )?.isCurrent,
      isTrue,
    );
    expect(
      (await store.read()).workouts.single[TrainingJsonKeys.endedAt],
      isNotNull,
    );
  });

  testWidgets('delete asks first; cancel keeps the session', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await seededStore();
    await openSession(tester, store);
    final String sessionId = (await store.read()).workouts.single['id']!
        .toString();

    await tester.tap(find.byKey(const Key('btn_delete_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dialog_delete_session')), findsOneWidget);
    expect(find.text(AppStrings.deleteSessionTitle), findsOneWidget);
    expect(find.text(AppStrings.deleteSessionBody), findsOneWidget);
    final TextButton deleteAction = tester.widget<TextButton>(
      find.byKey(const Key('btn_confirm_delete')),
    );
    expect(
      deleteAction.style?.foregroundColor?.resolve(<WidgetState>{}),
      CurvePalette.light.error,
    );

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dialog_delete_session')), findsNothing);
    expect(find.text(exerciseName), findsOneWidget);
    expect((await store.read()).workouts.single['id'], sessionId);

    await tester.tap(find.byKey(const Key('btn_delete_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('btn_confirm_delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dialog_delete_session')), findsNothing);
    expect(find.text(exerciseName), findsNothing);
    expect(find.text(AppStrings.trainingLogTitle), findsOneWidget);
    expect((await store.read()).workouts, isEmpty);
  });
}
