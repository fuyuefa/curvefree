import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrefsLocalStore> testStore() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return PrefsLocalStore(preferences: prefs);
  }

  testWidgets('today tab shows progress, muscles, and bottom nav', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CurveFreeApp(localStore: await testStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
    expect(find.text(AppStrings.navToday), findsWidgets);
    expect(find.byKey(const Key('home_week_progress')), findsOneWidget);
    expect(find.byKey(const Key('home_muscle_groups')), findsOneWidget);
    expect(find.byKey(const Key('nav_today')), findsOneWidget);
    expect(find.byKey(const Key('nav_training')), findsOneWidget);
    expect(find.byKey(const Key('nav_nutrition')), findsOneWidget);
    expect(find.byKey(const Key('nav_me')), findsOneWidget);
    expect(find.byKey(const Key('btn_start_workout')), findsNothing);

    final Icon todayIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('nav_today')),
        matching: find.byType(Icon),
      ),
    );
    expect(todayIcon.color, CurvePalette.light.primary);

    await tester.tap(find.byKey(const Key('nav_me')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('home_brand')), findsOneWidget);
    expect(find.byKey(const Key('storage_status_card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_nutrition')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.nutritionLogTitle), findsOneWidget);
  });

  testWidgets('training tab opens log and can start a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CurveFreeApp(localStore: await testStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('nav_training')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppStrings.trainingLogTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_start_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('btn_add_exercise')), findsOneWidget);
    expect(find.byKey(const Key('session_summary')), findsOneWidget);
    expect(find.byKey(const Key('btn_finish_workout')), findsOneWidget);
    expect(find.text(AppStrings.finishThisSession), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_add_exercise')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('杠铃卧推'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('杠铃卧推'), findsWidgets);
    expect(find.text(AppStrings.addSet), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final Container row = tester.widget<Container>(
      find.byKey(const Key('set_row_0')),
    );
    final BoxDecoration decoration = row.decoration! as BoxDecoration;
    expect(decoration.color, CurvePalette.light.successSoft);
  });

  testWidgets('today and session fit a phone width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final PrefsLocalStore store = await testStore();
    final int today = DateTime.now().weekday;
    final TrainingPlan plan = TrainingPlan(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
      sessions: <PlannedSession>[
        PlannedSession(
          weekday: today,
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
    final WorkoutSession openWorkout = WorkoutSession.create().copyWith(
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e-open',
          name: '杠铃卧推',
          catalogId: 'ex_barbell_bench',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's-open', weightKg: 40, reps: 8, completed: true),
            WorkoutSet(id: 's-next', weightKg: 40, reps: 8, completed: false),
          ],
        ),
      ],
    );
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        settings: <String, Object?>{PlanJsonKeys.settingsKey: plan.toJson()},
        workouts: <Map<String, Object?>>[openWorkout.toJson()],
      ),
    );

    await tester.pumpWidget(CurveFreeApp(localStore: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('home_resume_workout')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('home_resume_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('session_summary')), findsOneWidget);
    expect(find.text(AppStrings.addSet), findsOneWidget);
    expect(find.text(AppStrings.finishThisSession), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
