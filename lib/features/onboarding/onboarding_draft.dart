import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/plan/plan_constants.dart';

enum OnboardingStep {
  welcome,
  sex,
  body,
  goal,
  freq,
  equip,
  experience,
  prefer,
  activity,
  done;

  static const List<OnboardingStep> collectSteps = <OnboardingStep>[
    OnboardingStep.sex,
    OnboardingStep.body,
    OnboardingStep.goal,
    OnboardingStep.freq,
    OnboardingStep.equip,
    OnboardingStep.experience,
    OnboardingStep.prefer,
    OnboardingStep.activity,
  ];

  int? get collectIndex {
    final int index = collectSteps.indexOf(this);
    if (index < 0) {
      return null;
    }
    return index + 1;
  }

  OnboardingStep? get previous {
    final int index = this.index - 1;
    if (index < 0) {
      return null;
    }
    return OnboardingStep.values[index];
  }

  OnboardingStep? get forward {
    final int index = this.index + 1;
    if (index >= OnboardingStep.values.length) {
      return null;
    }
    return OnboardingStep.values[index];
  }
}

final class OnboardingDraft {
  const OnboardingDraft({
    this.sex,
    this.heightCm = BodyDefaults.heightCm,
    this.weightKg = BodyDefaults.weightKg,
    this.goal,
    this.daysPerWeek,
    this.equipment,
    this.experience,
    this.preferences = const <TrainingPreference>{},
    this.activity,
  });

  final BiologicalSex? sex;
  final double heightCm;
  final double weightKg;
  final TrainingGoal? goal;
  final int? daysPerWeek;
  final EquipmentProfile? equipment;
  final TrainingExperience? experience;
  final Set<TrainingPreference> preferences;
  final DailyActivity? activity;

  bool canAdvance(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome || OnboardingStep.done => true,
      OnboardingStep.sex => sex != null,
      OnboardingStep.body => _bodyInRange,
      OnboardingStep.goal => goal != null,
      OnboardingStep.freq => daysPerWeek != null,
      OnboardingStep.equip => equipment != null,
      OnboardingStep.experience => experience != null,
      OnboardingStep.prefer => true,
      OnboardingStep.activity => activity != null,
    };
  }

  bool get _bodyInRange {
    return heightCm >= BodyDefaults.minHeightCm &&
        heightCm <= BodyDefaults.maxHeightCm &&
        weightKg >= BodyDefaults.minWeightKg &&
        weightKg <= BodyDefaults.maxWeightKg;
  }

  UserProfile toCompletedProfile() {
    final BiologicalSex? sex = this.sex;
    final TrainingGoal? goal = this.goal;
    final int? daysPerWeek = this.daysPerWeek;
    final EquipmentProfile? equipment = this.equipment;
    final TrainingExperience? experience = this.experience;
    final DailyActivity? activity = this.activity;
    if (sex == null ||
        goal == null ||
        daysPerWeek == null ||
        equipment == null ||
        experience == null ||
        activity == null ||
        !_bodyInRange) {
      throw StateError('onboarding draft is incomplete');
    }
    final List<TrainingPreference> ordered = <TrainingPreference>[
      for (final TrainingPreference item in TrainingPreference.values)
        if (preferences.contains(item)) item,
    ];
    return UserProfile(
      onboardingDone: true,
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      daysPerWeek: daysPerWeek,
      equipment: equipment,
      experience: experience,
      preferences: ordered,
      activity: activity,
    );
  }

  OnboardingDraft copyWith({
    BiologicalSex? sex,
    double? heightCm,
    double? weightKg,
    TrainingGoal? goal,
    int? daysPerWeek,
    EquipmentProfile? equipment,
    TrainingExperience? experience,
    Set<TrainingPreference>? preferences,
    DailyActivity? activity,
  }) {
    return OnboardingDraft(
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      equipment: equipment ?? this.equipment,
      experience: experience ?? this.experience,
      preferences: preferences ?? this.preferences,
      activity: activity ?? this.activity,
    );
  }
}
