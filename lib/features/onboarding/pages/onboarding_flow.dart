import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/onboarding/onboarding_draft.dart';
import 'package:curvefree/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:curvefree/features/onboarding/widgets/onboarding_steps.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/plan/plan_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  OnboardingStep _step = OnboardingStep.welcome;
  OnboardingDraft _draft = const OnboardingDraft();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final bool isWelcome = _step == OnboardingStep.welcome;
    final bool isDone = _step == OnboardingStep.done;
    return OnboardingScaffold(
      progressIndex: _step.collectIndex,
      onBack: _step.previous == null || _saving ? null : _back,
      primaryLabel: isWelcome
          ? OnboardingCopy.start
          : isDone
          ? OnboardingCopy.enterToday
          : OnboardingCopy.next,
      primaryEnabled: !_saving && _draft.canAdvance(_step),
      onPrimary: isDone ? _enterWithPlan : _forward,
      secondary: isWelcome
          ? TextButton(
              key: const Key('onb_skip'),
              onPressed: _saving ? null : _skip,
              child: const Text(OnboardingCopy.skipExisting),
            )
          : null,
      body: OnboardingStepBody(
        step: _step,
        draft: _draft,
        onChanged: (OnboardingDraft next) => setState(() => _draft = next),
      ),
    );
  }

  void _back() {
    final OnboardingStep? previous = _step.previous;
    if (previous == null) {
      return;
    }
    setState(() => _step = previous);
  }

  void _forward() {
    final OnboardingStep? next = _step.forward;
    if (next == null || !_draft.canAdvance(_step)) {
      return;
    }
    setState(() => _step = next);
  }

  Future<void> _skip() {
    return _persist(UserProfile.skipped(), includePlan: false);
  }

  Future<void> _enterWithPlan() {
    return _persist(_draft.toCompletedProfile(), includePlan: true);
  }

  Future<void> _persist(
    UserProfile profile, {
    required bool includePlan,
  }) async {
    setState(() => _saving = true);
    try {
      final LocalStore store = ref.read(localStoreProvider);
      await store.mutate((LocalStoreSnapshot current) {
        final Map<String, Object?> settings = Map<String, Object?>.from(
          current.settings,
        );
        settings[UserProfile.settingsKey] = profile.toJson();
        if (includePlan &&
            profile.goal != null &&
            profile.daysPerWeek != null &&
            profile.equipment != null) {
          settings[PlanJsonKeys.settingsKey] = PlanGenerator.generate(
            goal: profile.goal!,
            daysPerWeek: profile.daysPerWeek!,
            equipment: profile.equipment!,
            sex: profile.sex,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            experience: profile.experience,
            preferences: profile.preferences,
            activity: profile.activity,
          ).toJson();
        }
        return current.copyWith(settings: settings);
      });
      if (!mounted) {
        return;
      }
      await ref.read(localStoreSnapshotProvider.notifier).reload();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
