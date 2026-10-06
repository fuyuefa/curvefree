abstract final class TrainingJsonKeys {
  static const String id = 'id';
  static const String startedAt = 'startedAt';
  static const String endedAt = 'endedAt';
  static const String notes = 'notes';
  static const String exercises = 'exercises';
  static const String name = 'name';
  static const String sets = 'sets';
  static const String weightKg = 'weightKg';
  static const String reps = 'reps';
  static const String completed = 'completed';
  static const String catalogId = 'catalogId';
}

abstract final class TrainingIdPrefix {
  static const String session = 'w';
  static const String exercise = 'e';
  static const String set = 's';
}

abstract final class TrainingDefaults {
  static const double defaultWeightKg = 20;
  static const int defaultReps = 8;
  static const int minReps = 0;
  static const int maxReps = 999;
  static const double minWeightKg = 0;
  static const double maxWeightKg = 999.5;
  static const int weightFractionDigits = 1;
}
