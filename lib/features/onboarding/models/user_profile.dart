import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/plan/plan_constants.dart';

/// Local profile written at the end of onboarding. Never uploaded.
final class UserProfile {
  const UserProfile({
    required this.onboardingDone,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.daysPerWeek,
    this.equipment,
    this.experience,
    this.preferences = const <TrainingPreference>[],
    this.activity,
  });

  static const String settingsKey = 'userProfile';

  final bool onboardingDone;
  final BiologicalSex? sex;
  final int? heightCm;
  final double? weightKg;
  final TrainingGoal? goal;
  final int? daysPerWeek;
  final EquipmentProfile? equipment;
  final TrainingExperience? experience;
  final List<TrainingPreference> preferences;
  final DailyActivity? activity;

  static const UserProfile fresh = UserProfile(onboardingDone: false);

  factory UserProfile.skipped() {
    return const UserProfile(onboardingDone: true);
  }

  /// Returning installs that already logged training, food, or a plan skip
  /// the questionnaire so this release does not block them.
  static bool shouldEnterShell(LocalStoreSnapshot snapshot) {
    if (UserProfile.fromSettings(snapshot.settings).onboardingDone) {
      return true;
    }
    if (snapshot.workouts.isNotEmpty || snapshot.foodLogs.isNotEmpty) {
      return true;
    }
    return snapshot.settings.containsKey(PlanJsonKeys.settingsKey);
  }

  factory UserProfile.fromSettings(Map<String, Object?> settings) {
    final Object? raw = settings[settingsKey];
    if (raw is! Map) {
      return UserProfile.fresh;
    }
    return UserProfile.fromJson(
      raw.map((Object? key, Object? value) => MapEntry(key.toString(), value)),
    );
  }

  factory UserProfile.fromJson(Map<String, Object?> json) {
    final Object? rawPreferences = json[OnboardingJsonKeys.preferences];
    return UserProfile(
      onboardingDone: json[OnboardingJsonKeys.onboardingDone] == true,
      sex: BiologicalSex.fromWire(json[OnboardingJsonKeys.sex]?.toString()),
      heightCm: _asInt(json[OnboardingJsonKeys.heightCm]),
      weightKg: _asDouble(json[OnboardingJsonKeys.weightKg]),
      goal: _goalOrNull(json[OnboardingJsonKeys.goal]?.toString()),
      daysPerWeek: _asInt(json[OnboardingJsonKeys.daysPerWeek]),
      equipment: _equipmentOrNull(
        json[OnboardingJsonKeys.equipment]?.toString(),
      ),
      experience: TrainingExperience.fromWire(
        json[OnboardingJsonKeys.experience]?.toString(),
      ),
      preferences: rawPreferences is List
          ? rawPreferences
                .map(
                  (Object? item) =>
                      TrainingPreference.fromWire(item?.toString()),
                )
                .whereType<TrainingPreference>()
                .toList(growable: false)
          : const <TrainingPreference>[],
      activity: DailyActivity.fromWire(
        json[OnboardingJsonKeys.activity]?.toString(),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      OnboardingJsonKeys.onboardingDone: onboardingDone,
      OnboardingJsonKeys.sex: sex?.wireName,
      OnboardingJsonKeys.heightCm: heightCm,
      OnboardingJsonKeys.weightKg: weightKg,
      OnboardingJsonKeys.goal: goal?.wireName,
      OnboardingJsonKeys.daysPerWeek: daysPerWeek,
      OnboardingJsonKeys.equipment: equipment?.wireName,
      OnboardingJsonKeys.experience: experience?.wireName,
      OnboardingJsonKeys.preferences: preferences
          .map((TrainingPreference item) => item.wireName)
          .toList(growable: false),
      OnboardingJsonKeys.activity: activity?.wireName,
    };
  }
}

TrainingGoal? _goalOrNull(String? raw) {
  if (raw == null) {
    return null;
  }
  for (final TrainingGoal value in TrainingGoal.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return null;
}

EquipmentProfile? _equipmentOrNull(String? raw) {
  if (raw == null) {
    return null;
  }
  for (final EquipmentProfile value in EquipmentProfile.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return null;
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

double? _asDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
