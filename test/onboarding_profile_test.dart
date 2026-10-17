import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/onboarding/onboarding_draft.dart';
import 'package:curvefree/features/onboarding/onboarding_entry.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collect flow is 8 screens and sex has two options', () {
    expect(
      OnboardingStep.collectSteps,
      hasLength(OnboardingLimits.collectCount),
    );
    expect(OnboardingStep.values, <OnboardingStep>[
      OnboardingStep.welcome,
      ...OnboardingStep.collectSteps,
      OnboardingStep.done,
    ]);
    expect(OnboardingStep.sex.collectIndex, 1);
    expect(OnboardingStep.activity.collectIndex, OnboardingLimits.collectCount);
    expect(OnboardingStep.welcome.collectIndex, isNull);
    expect(OnboardingStep.done.collectIndex, isNull);
    expect(OnboardingCopy.progressLabel(1), '1 / 8');
    expect(BiologicalSex.values, <BiologicalSex>[
      BiologicalSex.female,
      BiologicalSex.male,
    ]);
    expect(EquipmentProfile.values, hasLength(3));
  });

  test(
    'incomplete draft cannot leave a step and completed profile round-trips',
    () {
      const OnboardingDraft empty = OnboardingDraft();
      expect(empty.canAdvance(OnboardingStep.sex), isFalse);
      expect(empty.canAdvance(OnboardingStep.prefer), isTrue);
      expect(empty.canAdvance(OnboardingStep.body), isTrue);

      final OnboardingDraft ready = empty.copyWith(
        sex: BiologicalSex.female,
        goal: TrainingGoal.hypertrophy,
        daysPerWeek: 3,
        equipment: EquipmentProfile.bodyweight,
        experience: TrainingExperience.beginner,
        preferences: const <TrainingPreference>{TrainingPreference.chest},
        activity: DailyActivity.light,
      );
      final UserProfile profile = ready.toCompletedProfile();
      final UserProfile restored = UserProfile.fromJson(profile.toJson());
      expect(restored.onboardingDone, isTrue);
      expect(restored.sex, BiologicalSex.female);
      expect(restored.heightCm, BodyDefaults.heightCm);
      expect(restored.equipment, EquipmentProfile.bodyweight);
      expect(restored.preferences, <TrainingPreference>[
        TrainingPreference.chest,
      ]);
      expect(restored.activity, DailyActivity.light);
    },
  );

  test('prefer chips are the seven body parts and old pattern ids map', () {
    expect(
      TrainingPreference.values.map((TrainingPreference item) => item.labelZh),
      <String>['胸', '背', '肩', '腿', '臀', '手臂', '核心'],
    );
    expect(
      TrainingPreference.values.map((TrainingPreference item) => item.wireName),
      <String>['chest', 'back', 'shoulders', 'legs', 'glutes', 'arms', 'core'],
    );
    expect(TrainingPreference.fromWire('push'), TrainingPreference.chest);
    expect(TrainingPreference.fromWire('pull'), TrainingPreference.back);
    expect(TrainingPreference.fromWire('legs'), TrainingPreference.legs);
    expect(TrainingPreference.fromWire('core'), TrainingPreference.core);
    expect(TrainingPreference.fromWire('quads'), isNull);
    expect(TrainingPreference.fromWire('thighs'), isNull);

    final UserProfile restored = UserProfile.fromJson(<String, Object?>{
      OnboardingJsonKeys.onboardingDone: true,
      OnboardingJsonKeys.preferences: <String>['push', 'pull', 'quads'],
      OnboardingJsonKeys.heightCm: 170.4,
    });
    expect(restored.preferences, <TrainingPreference>[
      TrainingPreference.chest,
      TrainingPreference.back,
    ]);
    expect(restored.heightCm, 170.4);

    const OnboardingDraft skippedPrefer = OnboardingDraft(
      sex: BiologicalSex.male,
      goal: TrainingGoal.strength,
      daysPerWeek: 3,
      equipment: EquipmentProfile.fullGym,
      experience: TrainingExperience.intermediate,
      activity: DailyActivity.moderate,
    );
    expect(skippedPrefer.canAdvance(OnboardingStep.prefer), isTrue);
    expect(skippedPrefer.toCompletedProfile().preferences, isEmpty);
  });

  test('body metrics step by one tenth of the unit', () {
    expect(
      BodyDefaults.step(
        value: BodyDefaults.heightCm,
        delta: BodyDefaults.heightStepCm,
        min: BodyDefaults.minHeightCm,
        max: BodyDefaults.maxHeightCm,
      ),
      165.1,
    );
    expect(
      BodyDefaults.step(
        value: BodyDefaults.weightKg,
        delta: -BodyDefaults.weightStepKg,
        min: BodyDefaults.minWeightKg,
        max: BodyDefaults.maxWeightKg,
      ),
      54.9,
    );
    expect(
      BodyDefaults.step(
        value: BodyDefaults.maxHeightCm,
        delta: BodyDefaults.heightStepCm,
        min: BodyDefaults.minHeightCm,
        max: BodyDefaults.maxHeightCm,
      ),
      BodyDefaults.maxHeightCm,
    );
    expect(BodyDefaults.format(165), '165');
    expect(BodyDefaults.format(165.1), '165.1');
  });

  test('release skips onboarding when records exist; debug still opens it', () {
    final LocalStoreSnapshot withWorkout = LocalStoreSnapshot.empty().copyWith(
      workouts: const <Map<String, Object?>>[
        <String, Object?>{'id': 'w'},
      ],
    );
    expect(
      shouldPresentOnboarding(
        withWorkout,
        debugMode: false,
        profileMode: false,
        forceOnboarding: false,
      ),
      isFalse,
    );
    expect(
      shouldPresentOnboarding(
        LocalStoreSnapshot.empty(),
        debugMode: false,
        profileMode: false,
        forceOnboarding: false,
      ),
      isTrue,
    );
    expect(
      shouldPresentOnboarding(
        withWorkout,
        debugMode: true,
        profileMode: false,
        forceOnboarding: false,
      ),
      isTrue,
    );
    expect(
      shouldPresentOnboarding(
        withWorkout,
        debugMode: false,
        profileMode: true,
        forceOnboarding: false,
      ),
      isTrue,
    );
    expect(
      shouldPresentOnboarding(
        withWorkout,
        debugMode: false,
        profileMode: false,
        forceOnboarding: true,
      ),
      isTrue,
    );
  });

  test('existing local training skips onboarding', () {
    expect(UserProfile.shouldEnterShell(LocalStoreSnapshot.empty()), isFalse);
    expect(
      UserProfile.shouldEnterShell(
        LocalStoreSnapshot.empty().copyWith(
          settings: <String, Object?>{
            UserProfile.settingsKey: UserProfile.skipped().toJson(),
          },
        ),
      ),
      isTrue,
    );
    expect(
      UserProfile.shouldEnterShell(
        LocalStoreSnapshot.empty().copyWith(
          workouts: const <Map<String, Object?>>[
            <String, Object?>{'id': 'w'},
          ],
        ),
      ),
      isTrue,
    );
    expect(
      UserProfile.shouldEnterShell(
        LocalStoreSnapshot.empty().copyWith(
          settings: const <String, Object?>{
            PlanJsonKeys.settingsKey: <String, Object?>{'goal': 'hypertrophy'},
          },
        ),
      ),
      isTrue,
    );
  });
}
