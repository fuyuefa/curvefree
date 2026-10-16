import 'dart:io';
import 'dart:ui' as ui;

import 'package:curvefree/app/app.dart';
import 'package:curvefree/features/home/week_progress.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opt-in screenshots for the visual PR. Skipped in normal `flutter test`.
void main() {
  final bool enabled = Platform.environment['CURVEFREE_CAPTURE'] == '1';

  testWidgets('capture today and session in light and dark', (
    WidgetTester tester,
  ) async {
    await _loadFallbackFont();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final PrefsLocalStore store = await _seededStore();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture_root'),
        child: CurveFreeApp(localStore: store),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await _shoot(tester, 'today_light');

    await tester.tap(find.byKey(const Key('home_resume_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await _shoot(tester, 'session_light');

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byKey(const Key('nav_me')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('theme_dark')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav_today')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await _shoot(tester, 'today_dark');

    await tester.tap(find.byKey(const Key('home_resume_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await _shoot(tester, 'session_dark');
  }, skip: !enabled);
}

Future<void> _loadFallbackFont() async {
  final File file = File(
    '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
  );
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader('Noto Sans SC');
  loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<PrefsLocalStore> _seededStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final PrefsLocalStore store = PrefsLocalStore(preferences: prefs);
  final DateTime now = DateTime.now();
  final int today = now.weekday;
  final DateTime wednesday = startOfLocalWeek(now).add(const Duration(days: 2));
  final TrainingPlan plan = TrainingPlan(
    goal: TrainingGoal.hypertrophy,
    daysPerWeek: 4,
    equipment: EquipmentProfile.fullGym,
    sessions: <PlannedSession>[
      const PlannedSession(
        weekday: DateTime.monday,
        title: '推',
        items: <PlannedItem>[
          PlannedItem(
            catalogId: 'ex_barbell_bench',
            nameZh: '杠铃卧推',
            sets: 4,
            reps: 8,
          ),
        ],
      ),
      const PlannedSession(
        weekday: DateTime.wednesday,
        title: '拉',
        items: <PlannedItem>[
          PlannedItem(
            catalogId: 'ex_barbell_row',
            nameZh: '杠铃划船',
            sets: 4,
            reps: 8,
          ),
        ],
      ),
      PlannedSession(
        weekday: today,
        title: '推',
        items: const <PlannedItem>[
          PlannedItem(
            catalogId: 'ex_barbell_bench',
            nameZh: '杠铃卧推',
            sets: 4,
            reps: 8,
          ),
          PlannedItem(
            catalogId: 'ex_overhead_press',
            nameZh: '杠铃推举',
            sets: 3,
            reps: 8,
          ),
        ],
      ),
      const PlannedSession(
        weekday: DateTime.saturday,
        title: '腿',
        items: <PlannedItem>[
          PlannedItem(
            catalogId: 'ex_back_squat',
            nameZh: '杠铃深蹲',
            sets: 3,
            reps: 8,
          ),
        ],
      ),
    ],
  );
  final WorkoutSession openWorkout = WorkoutSession(
    id: 'capture-session',
    startedAt: DateTime.now().subtract(const Duration(minutes: 12, seconds: 4)),
    endedAt: null,
    notes: '',
    exercises: const <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-bench',
        name: '杠铃卧推',
        catalogId: 'ex_barbell_bench',
        sets: <WorkoutSet>[
          WorkoutSet(id: 's1', weightKg: 40, reps: 8, completed: true),
          WorkoutSet(id: 's2', weightKg: 40, reps: 8, completed: false),
        ],
      ),
    ],
  );
  final WorkoutSession earlier = WorkoutSession(
    id: 'capture-earlier',
    startedAt: wednesday.add(const Duration(hours: 18)),
    endedAt: wednesday.add(const Duration(hours: 19)),
    notes: '',
    exercises: const <WorkoutExercise>[
      WorkoutExercise(
        id: 'e-row',
        name: '杠铃划船',
        catalogId: 'ex_barbell_row',
        sets: <WorkoutSet>[
          WorkoutSet(id: 's-row', weightKg: 50, reps: 8, completed: true),
        ],
      ),
    ],
  );
  await store.write(
    LocalStoreSnapshot.empty().copyWith(
      settings: <String, Object?>{PlanJsonKeys.settingsKey: plan.toJson()},
      workouts: <Map<String, Object?>>[openWorkout.toJson(), earlier.toJson()],
    ),
  );
  return store;
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await tester.pump();
  final RenderRepaintBoundary boundary = tester
      .renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture_root')),
      );
  final ui.Image? image = await tester.runAsync(
    () => boundary.toImage(pixelRatio: 2),
  );
  final ByteData? data = await tester.runAsync<ByteData?>(() {
    return image!.toByteData(format: ui.ImageByteFormat.png);
  });
  final Directory dir = Directory('/opt/cursor/artifacts/screenshots');
  dir.createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
}
