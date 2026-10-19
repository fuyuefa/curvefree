import 'package:curvefree/app/theme/app_theme.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/constants/curve_palette.dart';
import 'package:curvefree/core/haptics/app_haptics.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/rest_end_flash.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:curvefree/features/training/widgets/session_set_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppHaptics', () {
    late List<MethodCall> haptic;

    setUp(() {
      haptic = <MethodCall>[];
      AppHaptics.isEnabled = () => true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptic.add(call);
            }
            return null;
          });
    });

    tearDown(() {
      AppHaptics.isEnabled = () => true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('check is light and rest end is medium', () async {
      await AppHaptics.setChecked();
      await AppHaptics.restEnded();
      expect(haptic, hasLength(2));
      expect(haptic.first.arguments, 'HapticFeedbackType.lightImpact');
      expect(haptic.last.arguments, 'HapticFeedbackType.mediumImpact');
    });

    test('disabled gate swallows both impacts', () async {
      AppHaptics.isEnabled = () => false;
      await AppHaptics.setChecked();
      await AppHaptics.restEnded();
      expect(haptic, isEmpty);
    });
  });

  test('rest-end peak is primarySoft, or a taro lean on that fill', () {
    const CurvePalette palette = CurvePalette.light;
    expect(
      restEndPeakFill(
        idle: palette.elevated,
        primarySoft: palette.primarySoft,
        primary: palette.primary,
      ),
      palette.primarySoft,
    );
    expect(
      restEndPeakFill(
        idle: palette.primarySoft,
        primarySoft: palette.primarySoft,
        primary: palette.primary,
      ),
      Color.lerp(
        palette.primarySoft,
        palette.primary,
        AppMotion.restEndFlashLean,
      ),
    );
    expect(palette.primary, const Color(0xFF9B7EBD));
  });

  testWidgets('natural end flashes once, skip does not', (tester) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final RestTimerController controller = container.read(
      restTimerProvider.notifier,
    );
    final DateTime start = DateTime.utc(2026, 10, 17, 8);
    controller.clock = () => start;
    controller.restart(sessionId: 'w', exerciseId: 'e', setId: 's');
    controller.skip();
    expect(container.read(restTimerProvider).endFlashUntil, isNull);
    expect(controller.noteNaturalEnd(start), isFalse);

    controller.clock = () => start;
    controller.restart(sessionId: 'w', exerciseId: 'e', setId: 's');
    final DateTime end = start.add(
      const Duration(seconds: RestTimerLimits.defaultSeconds),
    );
    expect(controller.noteNaturalEnd(end), isTrue);
    expect(controller.noteNaturalEnd(end), isFalse);
    final RestTimerState flashed = container.read(restTimerProvider);
    expect(flashed.sessionId, isNull);
    expect(flashed.endFlashSessionId, 'w');
    expect(flashed.endFlashExerciseId, 'e');
    expect(flashed.endFlashActiveFor('w', end), isTrue);
    expect(flashed.endFlashActiveFor('other', end), isFalse);

    await tester.pump(AppMotion.restEndFlash);
    final RestTimerState cleared = container.read(restTimerProvider);
    expect(cleared.endFlashUntil, isNull);
    expect(cleared.endFlashSessionId, isNull);
    expect(cleared.preferredSeconds, RestTimerLimits.defaultSeconds);
    expect(cleared.accountedSessionId, 'w');
  });

  testWidgets('checking a set fades the row into successSoft', (tester) async {
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
      AppHaptics.isEnabled = () => true;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCurveFreeTheme(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SessionSetRow(
                index: 0,
                set: WorkoutSet(
                  id: 's',
                  weightKg: 20,
                  reps: 8,
                  completed: completed,
                ),
                onWeightChanged: (_) {},
                onRepsChanged: (_) {},
                onToggleCompleted: () {
                  setState(() => completed = !completed);
                },
              );
            },
          ),
        ),
      ),
    );

    BoxDecoration decoration() {
      return tester
              .widget<Container>(find.byKey(const Key('set_row_0')))
              .decoration!
          as BoxDecoration;
    }

    expect(decoration().color, CurvePalette.light.muted);

    await tester.tap(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    expect(haptic.single.arguments, 'HapticFeedbackType.lightImpact');
    expect(decoration().color, CurvePalette.light.muted);

    await tester.pump(const Duration(milliseconds: 75));
    final Color? mid = decoration().color;
    expect(mid, isNot(CurvePalette.light.muted));
    expect(mid, isNot(CurvePalette.light.successSoft));

    await tester.pump(const Duration(milliseconds: 80));
    expect(decoration().color, CurvePalette.light.successSoft);
    expect(
      (decoration().border! as Border).top.color,
      CurvePalette.light.success,
    );

    await tester.tap(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    await tester.pump(AppMotion.setCheckFade);
    expect(haptic, hasLength(1));
    expect(decoration().color, CurvePalette.light.muted);

    AppHaptics.isEnabled = () => false;
    await tester.tap(find.byKey(const Key('set_complete_0')));
    await tester.pump();
    expect(haptic, hasLength(1));
  });
}
