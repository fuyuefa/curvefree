import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/plan/plan_constants.dart';

/// Stable volume shift from experience, body size, and daily activity.
/// Period recovery is applied separately so a saved plan does not freeze a date.
final class VolumeAdjustment {
  const VolumeAdjustment(this.sharedDelta);

  final int sharedDelta;

  static const VolumeAdjustment none = VolumeAdjustment(0);

  static VolumeAdjustment resolve({
    double? heightCm,
    double? weightKg,
    TrainingExperience? experience,
    DailyActivity? activity,
  }) {
    int delta = 0;
    switch (experience) {
      case TrainingExperience.beginner:
        delta += PlanVolumeLimits.beginnerSetDelta;
      case TrainingExperience.advanced:
        delta += PlanVolumeLimits.advancedSetDelta;
      case TrainingExperience.intermediate:
      case null:
        break;
    }
    final double? bmi = bodyMassIndex(heightCm: heightCm, weightKg: weightKg);
    if (bmi != null && bmi < PlanVolumeLimits.underweightBmi) {
      delta += PlanVolumeLimits.underweightSetDelta;
    }
    if (bmi != null &&
        bmi >= PlanVolumeLimits.highBmi &&
        experience == TrainingExperience.beginner) {
      delta += PlanVolumeLimits.highBmiBeginnerSetDelta;
    }
    if (activity == DailyActivity.active) {
      delta += PlanVolumeLimits.activeSetDelta;
    }
    return VolumeAdjustment(delta);
  }

  int setsFor(int baseSets, {required bool preferred}) {
    int sets = baseSets + sharedDelta;
    if (preferred) {
      sets += PlanVolumeLimits.preferenceSetDelta;
    }
    return clampPlanSets(sets);
  }
}

int clampPlanSets(int sets) {
  if (sets < PlanVolumeLimits.minSets) {
    return PlanVolumeLimits.minSets;
  }
  if (sets > PlanVolumeLimits.maxSets) {
    return PlanVolumeLimits.maxSets;
  }
  return sets;
}

double? bodyMassIndex({double? heightCm, double? weightKg}) {
  if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
    return null;
  }
  final double meters = heightCm / PlanVolumeLimits.cmPerMeter;
  return weightKg / (meters * meters);
}

/// Empty, or every body part selected, carries no extra volume signal.
Set<TrainingPreference> preferenceBias(List<TrainingPreference> preferences) {
  if (preferences.isEmpty) {
    return const <TrainingPreference>{};
  }
  final Set<TrainingPreference> unique = preferences.toSet();
  if (unique.length >= TrainingPreference.values.length) {
    return const <TrainingPreference>{};
  }
  return unique;
}

Set<TrainingPreference> preferencesForCatalog(String catalogId) {
  final List<String>? ids = ExerciseCatalog.bodyPartIds[catalogId];
  if (ids == null) {
    return const <TrainingPreference>{};
  }
  final Set<TrainingPreference> parts = <TrainingPreference>{};
  for (final String id in ids) {
    final TrainingPreference? part = TrainingPreference.fromWire(id);
    if (part != null) {
      parts.add(part);
    }
  }
  return parts;
}

/// Catalog ids to add when a biased pattern is missing from the whole week.
List<String> missingPreferenceCatalogIds({
  required Iterable<String> presentCatalogIds,
  required List<TrainingPreference> preferences,
  required EquipmentProfile equipment,
}) {
  final Set<TrainingPreference> bias = preferenceBias(preferences);
  if (bias.isEmpty) {
    return const <String>[];
  }
  final Set<TrainingPreference> present = <TrainingPreference>{};
  final Set<String> presentIds = presentCatalogIds.toSet();
  for (final String catalogId in presentIds) {
    present.addAll(preferencesForCatalog(catalogId));
  }
  final List<String> missing = <String>[];
  for (final TrainingPreference preference in TrainingPreference.values) {
    if (!bias.contains(preference) || present.contains(preference)) {
      continue;
    }
    final String? catalogId = catalogIdForPreference(preference, equipment);
    if (catalogId == null ||
        presentIds.contains(catalogId) ||
        missing.contains(catalogId)) {
      continue;
    }
    missing.add(catalogId);
  }
  return missing;
}

/// Representative catalog id for a preferred body part, when this equipment
/// profile has one. Bodyweight has no shoulder movement in the catalog.
String? catalogIdForPreference(
  TrainingPreference preference,
  EquipmentProfile equipment,
) {
  switch (preference) {
    case TrainingPreference.core:
      return 'ex_plank';
    case TrainingPreference.chest:
      switch (equipment) {
        case EquipmentProfile.fullGym:
          return 'ex_barbell_bench';
        case EquipmentProfile.dumbbells:
          return 'ex_db_press';
        case EquipmentProfile.bodyweight:
          return 'ex_dip';
      }
    case TrainingPreference.back:
      switch (equipment) {
        case EquipmentProfile.fullGym:
          return 'ex_barbell_row';
        case EquipmentProfile.dumbbells:
          return 'ex_db_row';
        case EquipmentProfile.bodyweight:
          return 'ex_pullup';
      }
    case TrainingPreference.shoulders:
      switch (equipment) {
        case EquipmentProfile.fullGym:
        case EquipmentProfile.dumbbells:
          return 'ex_overhead_press';
        case EquipmentProfile.bodyweight:
          return null;
      }
    case TrainingPreference.legs:
      switch (equipment) {
        case EquipmentProfile.fullGym:
          return 'ex_back_squat';
        case EquipmentProfile.dumbbells:
        case EquipmentProfile.bodyweight:
          return 'ex_lunge';
      }
    case TrainingPreference.glutes:
      return 'ex_hip_thrust';
    case TrainingPreference.arms:
      return 'ex_dip';
  }
}

/// True when [onDate] sits in a period window the stored lengths can place.
/// A missing cycle length does not project later cycles.
bool isInPeriodWindow({
  required BiologicalSex? sex,
  required CycleProfile? cycle,
  required DateTime onDate,
}) {
  if (sex != BiologicalSex.female || cycle == null) {
    return false;
  }
  final int? periodDays = cycle.periodDays;
  final DateTime? lastStart = cycle.lastStart;
  if (periodDays == null || lastStart == null || periodDays <= 0) {
    return false;
  }
  final int elapsed = _calendarDaysBetween(lastStart, onDate);
  if (elapsed < 0) {
    return false;
  }
  final int? cycleDays = cycle.cycleDays;
  if (cycleDays == null) {
    return elapsed < periodDays;
  }
  if (cycleDays <= 0) {
    return false;
  }
  return elapsed % cycleDays < periodDays;
}

int _calendarDaysBetween(DateTime start, DateTime end) {
  final DateTime first = DateTime(start.year, start.month, start.day);
  final DateTime last = DateTime(end.year, end.month, end.day);
  return last.difference(first).inDays;
}
