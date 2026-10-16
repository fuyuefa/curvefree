import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/onboarding/onboarding_draft.dart';
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
      expect(empty.canAdvance(OnboardingStep.prefer), isFalse);
      expect(empty.canAdvance(OnboardingStep.body), isTrue);

      final OnboardingDraft ready = empty.copyWith(
        sex: BiologicalSex.female,
        goal: TrainingGoal.hypertrophy,
        daysPerWeek: 3,
        equipment: EquipmentProfile.bodyweight,
        experience: TrainingExperience.beginner,
        preferences: const <TrainingPreference>{TrainingPreference.push},
        activity: DailyActivity.light,
      );
      final UserProfile profile = ready.toCompletedProfile();
      final UserProfile restored = UserProfile.fromJson(profile.toJson());
      expect(restored.onboardingDone, isTrue);
      expect(restored.sex, BiologicalSex.female);
      expect(restored.heightCm, BodyDefaults.heightCm);
      expect(restored.equipment, EquipmentProfile.bodyweight);
      expect(restored.preferences, <TrainingPreference>[
        TrainingPreference.push,
      ]);
      expect(restored.activity, DailyActivity.light);
    },
  );

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
