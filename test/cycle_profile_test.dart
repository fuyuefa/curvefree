import 'package:curvefree/features/cycle/cycle_constants.dart';
import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cycle chips only accept 3-7 days and 25/28/30 or unknown', () {
    expect(CycleLimits.periodDayOptions, <int>[3, 4, 5, 6, 7]);
    expect(CycleLimits.cycleDayOptions, <int>[25, 28, 30]);

    final CycleProfile invalid = CycleProfile.fromJson(const <String, Object?>{
      'periodDays': 2,
      'cycleDays': 27,
      'cycleUnknown': false,
    });
    expect(invalid.isComplete, isFalse);
    expect(invalid.meSubtitle, CycleCopy.meSubtitle);

    final CycleProfile known = const CycleProfile(periodDays: 5, cycleDays: 28);
    expect(known.isComplete, isTrue);
    expect(known.meSubtitle, '5 天 · 28 天');

    final CycleProfile unknown = known.copyWith(
      cycleUnknown: true,
      clearCycleDays: true,
    );
    final CycleProfile restored = CycleProfile.fromJson(unknown.toJson());
    expect(restored.cycleUnknown, isTrue);
    expect(restored.cycleDays, isNull);
    expect(restored.meSubtitle, '5 天 · 不太清楚');
    expect(restored.toJson()[CycleJsonKeys.lastStart], isNull);
  });

  test('last period date is optional and stays a local calendar day', () {
    final DateTime start = DateTime(2026, 10, 3);
    final CycleProfile profile = CycleProfile(
      periodDays: 4,
      cycleDays: 30,
      lastStart: start,
    );
    final CycleProfile restored = CycleProfile.fromJson(profile.toJson());
    expect(restored.lastStart, DateTime(2026, 10, 3));
    expect(formatCycleDate(restored.lastStart!), '2026年10月3日');

    final CycleProfile cleared = restored.copyWith(clearLastStart: true);
    expect(cleared.lastStart, isNull);
    expect(cleared.isComplete, isTrue);
  });
}
