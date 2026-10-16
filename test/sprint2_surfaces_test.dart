import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/cycle/cycle_constants.dart';
import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:curvefree/features/nutrition/nutrition_constants.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrefsLocalStore> emptyStore() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PrefsLocalStore(preferences: prefs);
  }

  Future<void> pumpApp(
    WidgetTester tester,
    PrefsLocalStore store, {
    Brightness? brightness,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (brightness != null) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    }
    await tester.pumpWidget(CurveFreeApp(localStore: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapPrimary(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('onb_primary')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('fresh install walks onboarding and stores a local plan', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await emptyStore();
    await pumpApp(tester, store);

    expect(find.byKey(const Key('onb_welcome')), findsOneWidget);
    expect(find.text(OnboardingCopy.welcomePlan), findsOneWidget);
    expect(find.text('先不选'), findsNothing);
    expect(find.text(CycleCopy.title), findsNothing);

    await tapPrimary(tester);
    expect(find.text(OnboardingCopy.progressLabel(1)), findsOneWidget);
    expect(find.byKey(const Key('onb_sex_female')), findsOneWidget);
    expect(find.byKey(const Key('onb_sex_male')), findsOneWidget);
    expect(find.text('先不选'), findsNothing);
    expect(find.text(CycleCopy.title), findsNothing);

    await tester.tap(find.byKey(const Key('onb_sex_female')));
    await tester.pump();
    await tapPrimary(tester);

    expect(find.text(OnboardingCopy.progressLabel(2)), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb_height_plus')));
    await tester.pump();
    await tapPrimary(tester);

    await tester.tap(find.byKey(const Key('onb_goal_hypertrophy')));
    await tester.pump();
    await tapPrimary(tester);

    await tester.tap(find.byKey(const Key('onb_freq_3')));
    await tester.pump();
    await tapPrimary(tester);

    expect(find.byKey(const Key('onb_equip')), findsOneWidget);
    expect(find.byKey(const Key('onb_equip_fullGym')), findsOneWidget);
    expect(find.byKey(const Key('onb_equip_dumbbells')), findsOneWidget);
    expect(find.byKey(const Key('onb_equip_bodyweight')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb_equip_fullGym')));
    await tester.pump();
    await tapPrimary(tester);

    await tester.tap(find.byKey(const Key('onb_exp_beginner')));
    await tester.pump();
    await tapPrimary(tester);

    expect(find.byKey(const Key('onb_prefer')), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.byIcon(Icons.rowing), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb_prefer_push')));
    await tester.pump();
    await tapPrimary(tester);

    expect(find.text(OnboardingCopy.progressLabel(8)), findsOneWidget);
    expect(find.text(CycleCopy.title), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('onb_activity_moderate')));
    await tester.tap(find.byKey(const Key('onb_activity_moderate')));
    await tester.pump();
    await tapPrimary(tester);

    expect(find.byKey(const Key('onb_done')), findsOneWidget);
    expect(find.text(OnboardingCopy.doneTitle), findsOneWidget);
    expect(find.byKey(const Key('onb_progress')), findsNothing);
    await tapPrimary(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
    expect(find.byKey(const Key('nav_me')), findsOneWidget);

    final LocalStoreSnapshot snapshot = await store.read();
    final UserProfile profile = UserProfile.fromSettings(snapshot.settings);
    expect(profile.onboardingDone, isTrue);
    expect(profile.sex, BiologicalSex.female);
    expect(profile.heightCm, BodyDefaults.heightCm + 1);
    final Object? rawPlan = snapshot.settings[PlanJsonKeys.settingsKey];
    expect(rawPlan, isA<Map<Object?, Object?>>());
    final TrainingPlan plan = TrainingPlan.fromJson(
      (rawPlan! as Map<Object?, Object?>).map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      ),
    );
    expect(plan.goal, TrainingGoal.hypertrophy);
    expect(plan.daysPerWeek, 3);
    expect(plan.equipment, EquipmentProfile.fullGym);
    expect(plan.sessions, isNotEmpty);
  });

  testWidgets('skip and existing workouts enter today without a new plan', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore fresh = await emptyStore();
    await pumpApp(tester, fresh);
    await tester.tap(find.byKey(const Key('onb_skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
    final LocalStoreSnapshot skipped = await fresh.read();
    expect(UserProfile.fromSettings(skipped.settings).onboardingDone, isTrue);
    expect(skipped.settings.containsKey(PlanJsonKeys.settingsKey), isFalse);

    final PrefsLocalStore returning = await emptyStore();
    await returning.write(
      LocalStoreSnapshot.empty().copyWith(
        workouts: <Map<String, Object?>>[WorkoutSession.create().toJson()],
      ),
    );
    await pumpApp(tester, returning);
    expect(find.byKey(const Key('onb_welcome')), findsNothing);
    expect(find.byKey(const Key('home_today_title')), findsOneWidget);
  });

  testWidgets('onboarding sex follows dark cream surfaces', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, await emptyStore(), brightness: Brightness.dark);
    await tapPrimary(tester);
    final BuildContext context = tester.element(
      find.byKey(const Key('onb_root')),
    );
    expect(Theme.of(context).scaffoldBackgroundColor, CurvePalette.dark.screen);
    expect(Theme.of(context).colorScheme.primary, CurvePalette.dark.primary);
  });

  testWidgets('nutrition home groups meals and edits grams locally', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await emptyStore();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('nav_nutrition')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('nutri_title')), findsOneWidget);
    expect(find.text(MealNames.labelZh(MealNames.breakfast)), findsOneWidget);
    expect(find.text(MealNames.labelZh(MealNames.lunch)), findsOneWidget);
    expect(find.text(MealNames.labelZh(MealNames.snack)), findsOneWidget);
    expect(find.text(MealNames.labelZh(MealNames.dinner)), findsOneWidget);
    final BuildContext lightContext = tester.element(
      find.byKey(const Key('nutri_home')),
    );
    expect(
      Theme.of(lightContext).scaffoldBackgroundColor,
      CurvePalette.light.screen,
    );

    await tester.tap(find.byKey(const Key('btn_add_meal_breakfast')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('鸡蛋'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.descendant(
        of: find.byKey(const Key('nutri_meal_${MealNames.breakfast}')),
        matching: find.text('鸡蛋'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('nutri_meal_${MealNames.snack}')),
        matching: find.text('鸡蛋'),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip(NutritionCopy.editGrams));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('⌫'));
    await tester.pump();
    await tester.tap(find.text('⌫'));
    await tester.pump();
    await tester.tap(find.text('⌫'));
    await tester.pump();
    await tester.tap(find.text('8').last);
    await tester.pump();
    await tester.tap(find.text('0').last);
    await tester.pump();
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('80'), findsWidgets);
    final LocalStoreSnapshot snapshot = await store.read();
    expect(snapshot.foodLogs.single['meal'], MealNames.breakfast);
    expect(snapshot.foodLogs.single['grams'], 80);

    await tester.tap(find.byKey(const Key('nav_me')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('theme_dark')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav_nutrition')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final BuildContext darkContext = tester.element(
      find.byKey(const Key('nutri_home')),
    );
    expect(
      Theme.of(darkContext).scaffoldBackgroundColor,
      CurvePalette.dark.screen,
    );
    expect(find.text('鸡蛋'), findsOneWidget);
  });

  testWidgets('cycle editor lives under me and persists on device', (
    WidgetTester tester,
  ) async {
    final PrefsLocalStore store = await emptyStore();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('nav_me')));
    await tester.pump();
    expect(find.text(CycleCopy.meSubtitle), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byKey(const Key('me_cycle_entry'))))
          .scaffoldBackgroundColor,
      CurvePalette.light.screen,
    );

    await tester.tap(find.byKey(const Key('me_cycle_entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('cycle_page')), findsOneWidget);
    expect(find.text(CycleCopy.localNote), findsOneWidget);
    for (final int days in CycleLimits.periodDayOptions) {
      expect(find.byKey(Key('cycle_period_$days')), findsOneWidget);
    }
    for (final int days in CycleLimits.cycleDayOptions) {
      expect(find.byKey(Key('cycle_length_$days')), findsOneWidget);
    }
    expect(find.byKey(const Key('cycle_length_unknown')), findsOneWidget);
    expect(find.text(CycleCopy.notYet), findsOneWidget);

    await tester.tap(find.byKey(const Key('cycle_last_start')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(CycleCopy.notYet), findsOneWidget);

    await tester.tap(find.byKey(const Key('cycle_period_5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cycle_length_28')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cycle_save')));
    await tester.pumpAndSettle();

    expect(find.text('5 天 · 28 天'), findsOneWidget);
    final LocalStoreSnapshot saved = await store.read();
    expect(saved.settings.containsKey(CycleProfile.settingsKey), isTrue);
    expect(saved.foodLogs, isEmpty);
    expect(saved.workouts, isEmpty);

    await tester.tap(find.byKey(const Key('theme_dark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('me_cycle_entry')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(const Key('cycle_page'))))
          .scaffoldBackgroundColor,
      CurvePalette.dark.screen,
    );
    final ChoiceChip period = tester.widget<ChoiceChip>(
      find.byKey(const Key('cycle_period_5')),
    );
    expect(period.selected, isTrue);
    expect(find.text(CycleCopy.notYet), findsOneWidget);
  });
}
