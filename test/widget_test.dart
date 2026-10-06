import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
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

  testWidgets('home shows brand and module tiles', (WidgetTester tester) async {
    await tester.pumpWidget(CurveFreeApp(localStore: await testStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppStrings.appNameZh), findsOneWidget);
    expect(find.byKey(const Key('home_brand')), findsOneWidget);
    expect(find.byKey(const Key('tile_training')), findsOneWidget);
    expect(find.byKey(const Key('tile_nutrition')), findsOneWidget);
    expect(find.byKey(const Key('storage_status_card')), findsOneWidget);
  });

  testWidgets('training tile opens log and can start a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CurveFreeApp(localStore: await testStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('tile_training')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppStrings.trainingLogTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_start_workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('btn_add_exercise')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_add_exercise')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('杠铃卧推'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('杠铃卧推'), findsWidgets);
    expect(find.text(AppStrings.addSet), findsOneWidget);
  });
}
