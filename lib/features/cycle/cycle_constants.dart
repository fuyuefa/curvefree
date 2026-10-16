abstract final class CycleLimits {
  static const List<int> periodDayOptions = <int>[3, 4, 5, 6, 7];
  static const List<int> cycleDayOptions = <int>[25, 28, 30];
  static const int lookbackDays = 400;
}

abstract final class CycleJsonKeys {
  static const String periodDays = 'periodDays';
  static const String cycleDays = 'cycleDays';
  static const String cycleUnknown = 'cycleUnknown';
  static const String lastStart = 'lastStart';
}

abstract final class CycleCopy {
  static const String title = '经期';
  static const String meSubtitle = '月经天数 · 周期天数';
  static const String localNote = '只存在这台手机上，用来在计划里把训练强度降一点。';
  static const String periodDays = '月经天数';
  static const String cycleDays = '周期天数';
  static const String unknown = '不太清楚';
  static const String lastStart = '最近一次来潮';
  static const String optional = '可选';
  static const String notYet = '还没记';
  static const String save = '保存';
  static const String clearDate = '清除日期';
  static const String dayUnit = '天';
}
