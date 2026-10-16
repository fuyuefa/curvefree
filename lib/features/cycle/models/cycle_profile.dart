import 'package:curvefree/features/cycle/cycle_constants.dart';

/// Menstrual fields kept on device. The plan may read them later.
final class CycleProfile {
  const CycleProfile({
    this.periodDays,
    this.cycleDays,
    this.cycleUnknown = false,
    this.lastStart,
  });

  static const String settingsKey = 'cycleProfile';
  static const CycleProfile empty = CycleProfile();

  final int? periodDays;
  final int? cycleDays;
  final bool cycleUnknown;
  final DateTime? lastStart;

  bool get isComplete {
    if (!CycleLimits.periodDayOptions.contains(periodDays)) {
      return false;
    }
    if (cycleUnknown) {
      return true;
    }
    return CycleLimits.cycleDayOptions.contains(cycleDays);
  }

  String get meSubtitle {
    if (!isComplete) {
      return CycleCopy.meSubtitle;
    }
    final String cycle = cycleUnknown
        ? CycleCopy.unknown
        : '$cycleDays ${CycleCopy.dayUnit}';
    return '$periodDays ${CycleCopy.dayUnit} · $cycle';
  }

  factory CycleProfile.fromSettings(Map<String, Object?> settings) {
    final Object? raw = settings[settingsKey];
    if (raw is! Map) {
      return CycleProfile.empty;
    }
    return CycleProfile.fromJson(
      raw.map((Object? key, Object? value) => MapEntry(key.toString(), value)),
    );
  }

  factory CycleProfile.fromJson(Map<String, Object?> json) {
    final bool unknown = json[CycleJsonKeys.cycleUnknown] == true;
    return CycleProfile(
      periodDays: _allowed(
        _asInt(json[CycleJsonKeys.periodDays]),
        CycleLimits.periodDayOptions,
      ),
      cycleDays: unknown
          ? null
          : _allowed(
              _asInt(json[CycleJsonKeys.cycleDays]),
              CycleLimits.cycleDayOptions,
            ),
      cycleUnknown: unknown,
      lastStart: _parseDate(json[CycleJsonKeys.lastStart]?.toString()),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      CycleJsonKeys.periodDays: periodDays,
      CycleJsonKeys.cycleDays: cycleUnknown ? null : cycleDays,
      CycleJsonKeys.cycleUnknown: cycleUnknown,
      CycleJsonKeys.lastStart: lastStart == null ? null : _dateKey(lastStart!),
    };
  }

  CycleProfile copyWith({
    int? periodDays,
    int? cycleDays,
    bool? cycleUnknown,
    DateTime? lastStart,
    bool clearLastStart = false,
    bool clearCycleDays = false,
  }) {
    return CycleProfile(
      periodDays: periodDays ?? this.periodDays,
      cycleDays: clearCycleDays ? null : (cycleDays ?? this.cycleDays),
      cycleUnknown: cycleUnknown ?? this.cycleUnknown,
      lastStart: clearLastStart ? null : (lastStart ?? this.lastStart),
    );
  }
}

int? _allowed(int? value, List<int> options) {
  if (value == null || !options.contains(value)) {
    return null;
  }
  return value;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '');
}

String _dateKey(DateTime date) {
  final DateTime local = date.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final List<String> parts = raw.split('-');
  if (parts.length != 3) {
    return null;
  }
  final int? year = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final DateTime parsed = DateTime(year, month, day);
  if (parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

String formatCycleDate(DateTime date) {
  final DateTime local = date.toLocal();
  return '${local.year}年${local.month}月${local.day}日';
}
