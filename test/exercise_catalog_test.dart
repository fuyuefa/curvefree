import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog search filters by name and pattern', () {
    expect(ExerciseCatalog.all, isNotEmpty);
    expect(ExerciseCatalog.byId('ex_deadlift')?.nameZh, '硬拉');
    final rows = ExerciseCatalog.search('划船');
    expect(rows.every((item) => item.nameZh.contains('划船')), isTrue);
    expect(ExerciseCatalog.search('拉').isNotEmpty, isTrue);
  });
}
