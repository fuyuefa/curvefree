abstract final class PlanJsonKeys {
  static const String settingsKey = 'trainingPlan';
  static const String goal = 'goal';
  static const String daysPerWeek = 'daysPerWeek';
  static const String equipment = 'equipment';
  static const String sessions = 'sessions';
  static const String weekday = 'weekday';
  static const String title = 'title';
  static const String items = 'items';
  static const String catalogId = 'catalogId';
  static const String nameZh = 'nameZh';
  static const String sets = 'sets';
  static const String reps = 'reps';
  static const String periodAdjusted = 'periodAdjusted';
}

abstract final class PlanWeekdays {
  static const List<String> labels = <String>[
    '',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static String label(int weekday) {
    if (weekday < 1 || weekday >= labels.length) {
      return '';
    }
    return labels[weekday];
  }
}

abstract final class PlanLimits {
  static const int minDaysPerWeek = 2;
  static const int maxDaysPerWeek = 6;
  static const int defaultDaysPerWeek = 3;
}

enum TrainingGoal { hypertrophy, strength, fatLoss }

enum EquipmentProfile { fullGym, dumbbells, bodyweight }

extension TrainingGoalLabel on TrainingGoal {
  String get labelZh {
    switch (this) {
      case TrainingGoal.hypertrophy:
        return '增肌';
      case TrainingGoal.strength:
        return '力量';
      case TrainingGoal.fatLoss:
        return '减脂维持肌量';
    }
  }

  String get wireName => name;
}

extension EquipmentProfileLabel on EquipmentProfile {
  String get labelZh {
    switch (this) {
      case EquipmentProfile.fullGym:
        return '健身房';
      case EquipmentProfile.dumbbells:
        return '哑铃为主';
      case EquipmentProfile.bodyweight:
        return '自重为主';
    }
  }

  String get wireName => name;
}

TrainingGoal trainingGoalFromWire(String? raw) {
  for (final TrainingGoal value in TrainingGoal.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return TrainingGoal.hypertrophy;
}

EquipmentProfile equipmentProfileFromWire(String? raw) {
  for (final EquipmentProfile value in EquipmentProfile.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return EquipmentProfile.fullGym;
}

abstract final class SetPrescriptions {
  static const int hypertrophySets = 3;
  static const int hypertrophyReps = 8;
  static const int strengthMainSets = 5;
  static const int strengthMainReps = 5;
  static const int strengthAccSets = 3;
  static const int strengthAccReps = 8;
  static const int fatLossSets = 3;
  static const int fatLossReps = 12;
}

/// Volume deltas applied on top of [SetPrescriptions]. Each number is one set.
abstract final class PlanVolumeLimits {
  static const int minSets = 2;
  static const int maxSets = 6;
  static const int beginnerSetDelta = -1;
  static const int advancedSetDelta = 1;
  static const int underweightSetDelta = -1;
  static const int highBmiBeginnerSetDelta = -1;
  static const int activeSetDelta = -1;
  static const int preferenceSetDelta = 1;
  static const int periodSetDelta = -1;

  /// WHO underweight cut-point. Below this, drop one set.
  static const double underweightBmi = 18.5;

  /// Chinese adult obesity cut-point. Beginners above this drop one set.
  static const double highBmi = 28;
  static const int cmPerMeter = 100;
}

abstract final class PlanCopy {
  static const String periodVolumeNote = '经期这几天，组数已略减';
}
