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

/// Placeholder focus areas. Icons stand in until exercise art exists.
enum TrainingPreference {
  push,
  pull,
  legs,
  core;

  String get wireName => name;

  static TrainingPreference? fromWire(String? raw) {
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
