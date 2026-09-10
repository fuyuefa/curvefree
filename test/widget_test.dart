import 'package:curvefree/app/app.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('home shows brand and module tiles', (WidgetTester tester) async {
    await tester.pumpWidget(const CurveFreeApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appNameZh), findsOneWidget);
    expect(find.byKey(const Key('home_brand')), findsOneWidget);
    expect(find.byKey(const Key('tile_training')), findsOneWidget);
    expect(find.byKey(const Key('tile_nutrition')), findsOneWidget);
    expect(find.byKey(const Key('storage_status_card')), findsOneWidget);
  });
}
