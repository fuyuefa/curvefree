import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
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

  testWidgets('home resumes an unfinished workout', (
    WidgetTester tester,
  ) async {
    final store = await testStore();
    final today = DateTime.now().weekday;
    final plan = TrainingPlan(
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
    final openWorkout = WorkoutSession.create().copyWith(
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e-open',
          name: '深蹲',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's-open', weightKg: 90, reps: 5, completed: true),
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

    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home_resume_workout')), findsOneWidget);
    expect(find.text(AppStrings.resumeWorkout), findsOneWidget);
    expect(find.byKey(const Key('home_today_plan')), findsOneWidget);
    expect(find.textContaining('杠铃卧推'), findsWidgets);

    await tester.tap(find.byKey(const Key('home_resume_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('深蹲'), findsWidgets);
    expect(find.byKey(const Key('btn_add_exercise')), findsOneWidget);
  });

  testWidgets('home starts the plan session for today', (
    WidgetTester tester,
  ) async {
    final store = await testStore();
    final today = DateTime.now().weekday;
    final plan = TrainingPlan(
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
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        settings: <String, Object?>{PlanJsonKeys.settingsKey: plan.toJson()},
      ),
    );

    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('home_today_plan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('杠铃卧推'), findsWidgets);
    expect(find.byKey(const Key('btn_add_exercise')), findsOneWidget);
    expect(find.text('20'), findsWidgets);
  });

  testWidgets('rest day is shown when the plan skips today', (
    WidgetTester tester,
  ) async {
    final store = await testStore();
    final otherDay = DateTime.now().weekday == DateTime.monday
        ? DateTime.tuesday
        : DateTime.monday;
    final plan = TrainingPlan(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 2,
      equipment: EquipmentProfile.fullGym,
      sessions: <PlannedSession>[
        PlannedSession(
          weekday: otherDay,
          title: '拉',
          items: const <PlannedItem>[
            PlannedItem(catalogId: 'ex_row', nameZh: '杠铃划船', sets: 3, reps: 8),
          ],
        ),
      ],
    );
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        settings: <String, Object?>{PlanJsonKeys.settingsKey: plan.toJson()},
      ),
    );

    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home_today_rest')), findsOneWidget);
    expect(find.byKey(const Key('home_today_plan')), findsNothing);
    expect(find.byKey(const Key('home_resume_workout')), findsNothing);
  });

  testWidgets('export writes a file payload and restore replaces local data', (
    WidgetTester tester,
  ) async {
    final store = await testStore();
    final gateway = _FakeBackupGateway();
    final original = WorkoutSession.create().copyWith(
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e-export',
          name: '硬拉',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's-export', weightKg: 120, reps: 3, completed: true),
          ],
        ),
      ],
    );
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        workouts: <Map<String, Object?>>[original.toJson()],
      ),
    );

    await tester.pumpWidget(
      CurveFreeApp(
        localStore: store,
        backupGateway: gateway,
        skipOnboarding: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('nav_me')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('btn_export_backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dialog_export_backup')), findsOneWidget);
    expect(find.text(AppStrings.backupExportConfirmTitle), findsOneWidget);
    expect(find.text(AppStrings.backupExportConfirmBody), findsOneWidget);
    expect(gateway.exportCalls, 0);
    expect(gateway.lastFileName, isNull);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('dialog_export_backup')), findsNothing);
    expect(gateway.exportCalls, 0);
    expect(find.text(AppStrings.backupSaved), findsNothing);

    await tester.tap(find.byKey(const Key('btn_export_backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('btn_confirm_export')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(gateway.exportCalls, 1);
    expect(gateway.lastFileName, startsWith('curvefree-backup-'));
    expect(gateway.lastFileName, endsWith('.json'));
    expect(gateway.lastContents, contains('硬拉'));
    expect(find.text(AppStrings.backupSaved), findsOneWidget);

    final replacement = WorkoutSession.create();
    gateway.nextPick = LocalStoreSnapshot.empty()
        .copyWith(workouts: <Map<String, Object?>>[replacement.toJson()])
        .encodePretty();

    await tester.tap(find.byKey(const Key('btn_import_backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.backupRestoreBody), findsOneWidget);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect((await store.read()).workouts.single['id'], original.id);

    await tester.tap(find.byKey(const Key('btn_import_backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('btn_confirm_restore')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final restored = await store.read();
    expect(restored.workouts.single['id'], replacement.id);
    expect(find.text(AppStrings.backupRestored), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav_today')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('home_resume_workout')), findsOneWidget);
  });

  testWidgets('new exercise set defaults to the last completed load', (
    WidgetTester tester,
  ) async {
    final store = await testStore();
    final previous = WorkoutSession.create().copyWith(
      endedAt: DateTime.now(),
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e-old',
          name: '杠铃卧推',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's-old', weightKg: 80, reps: 6, completed: true),
          ],
        ),
      ],
    );
    await store.write(
      LocalStoreSnapshot.empty().copyWith(
        workouts: <Map<String, Object?>>[previous.toJson()],
      ),
    );

    await tester.pumpWidget(
      CurveFreeApp(localStore: store, skipOnboarding: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('nav_training')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('btn_start_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.pickExercise), findsOneWidget);
    await tester.tap(find.text('杠铃卧推'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('80'), findsOneWidget);
    expect(find.text('6'), findsWidgets);
    expect(find.textContaining(AppStrings.lastHintPrefix), findsOneWidget);
    expect(find.text('20'), findsNothing);

    await tester.tap(find.text(AppStrings.addSet));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('80'), findsNWidgets(2));
  });
}

final class _FakeBackupGateway implements BackupFileGateway {
  String? nextPick;
  String? lastFileName;
  String? lastContents;
  int exportCalls = 0;

  @override
  Future<BackupExportResult> exportFile({
    required String fileName,
    required String contents,
  }) async {
    exportCalls += 1;
    lastFileName = fileName;
    lastContents = contents;
    return BackupExportResult(savedPath: '/tmp/$fileName');
  }

  @override
  Future<String?> pickTextFile() async => nextPick;
}
