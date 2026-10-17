/// Sex collected in onboarding. Wireframe v1.4: 女 / 男 only.
enum BiologicalSex {
  female('女'),
  male('男');

  const BiologicalSex(this.labelZh);

  final String labelZh;

  String get wireName => name;

  static BiologicalSex? fromWire(String? raw) {
    for (final BiologicalSex value in BiologicalSex.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

enum TrainingExperience {
  beginner,
  intermediate,
  advanced;

  String get wireName => name;

  static TrainingExperience? fromWire(String? raw) {
    for (final TrainingExperience value in TrainingExperience.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Body parts a person can prefer. Order is the chip order.
///
/// Stored as [wireName]. Older movement-pattern ids map here:
/// `push` → chest, `pull` → back, `legs` → legs, `core` → core.
/// Any other legacy id is ignored.
enum TrainingPreference {
  chest('胸'),
  back('背'),
  shoulders('肩'),
  legs('腿'),
  glutes('臀'),
  arms('手臂'),
  core('核心');

  const TrainingPreference(this.labelZh);

  final String labelZh;

  String get wireName => name;

  static TrainingPreference? fromWire(String? raw) {
    switch (raw) {
      case 'push':
        return TrainingPreference.chest;
      case 'pull':
        return TrainingPreference.back;
      case 'legs':
        return TrainingPreference.legs;
      case 'core':
        return TrainingPreference.core;
      default:
        break;
    }
    for (final TrainingPreference value in TrainingPreference.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

enum DailyActivity {
  sedentary,
  light,
  moderate,
  active;

  String get wireName => name;

  static DailyActivity? fromWire(String? raw) {
    for (final DailyActivity value in DailyActivity.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}
