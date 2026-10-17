import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user-facing const strings do not contain a full-width period', () {
    const List<String> files = <String>[
      'lib/core/constants/app_tokens.dart',
      'lib/features/onboarding/onboarding_constants.dart',
      'lib/features/cycle/cycle_constants.dart',
      'lib/features/plan/plan_constants.dart',
      'lib/features/nutrition/nutrition_constants.dart',
    ];
    final RegExp declared = RegExp(r'static const String\s+\w+');
    final RegExp literal = RegExp(
      r"static const String\s+(\w+)\s*=\s*'([^']*)'\s*;",
    );
    expect(files, isNotEmpty);
    for (final String path in files) {
      final String source = File(path).readAsStringSync();
      final int declarations = declared.allMatches(source).length;
      final Iterable<RegExpMatch> values = literal.allMatches(source);
      expect(values.length, declarations, reason: path);
      expect(declarations, greaterThan(0), reason: path);
      for (final RegExpMatch match in values) {
        final String name = match.group(1)!;
        final String value = match.group(2)!;
        expect(value.contains('。'), isFalse, reason: '$path $name');
      }
    }
  });
}
