import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:curvefree/features/onboarding/onboarding_draft.dart';
import 'package:curvefree/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:flutter/material.dart';

class OnboardingStepBody extends StatelessWidget {
  const OnboardingStepBody({
    super.key,
    required this.step,
    required this.draft,
    required this.onChanged,
  });

  final OnboardingStep step;
  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      OnboardingStep.welcome => const _WelcomeBody(),
      OnboardingStep.sex => _SexBody(draft: draft, onChanged: onChanged),
      OnboardingStep.body => _BodyStep(draft: draft, onChanged: onChanged),
      OnboardingStep.goal => _GoalStep(draft: draft, onChanged: onChanged),
      OnboardingStep.freq => _FreqStep(draft: draft, onChanged: onChanged),
      OnboardingStep.equip => _EquipStep(draft: draft, onChanged: onChanged),
      OnboardingStep.experience => _ExperienceStep(
        draft: draft,
        onChanged: onChanged,
      ),
      OnboardingStep.prefer => _PreferStep(draft: draft, onChanged: onChanged),
      OnboardingStep.activity => _ActivityStep(
        draft: draft,
        onChanged: onChanged,
      ),
      OnboardingStep.done => const _DoneBody(),
    };
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('onb_welcome'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.appNameZh,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          OnboardingCopy.welcomeBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          OnboardingCopy.welcomePlan,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _SexBody extends StatelessWidget {
  const _SexBody({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.sexTitle,
          body: OnboardingCopy.sexBody,
        ),
        for (final BiologicalSex sex in BiologicalSex.values)
          OnboardingSelectCard(
            cardKey: Key('onb_sex_${sex.wireName}'),
            title: sex.labelZh,
            selected: draft.sex == sex,
            leading: Icon(
              sex == BiologicalSex.female ? Icons.female : Icons.male,
              color: CurveColors.of(context).primary,
            ),
            onTap: () => onChanged(draft.copyWith(sex: sex)),
          ),
      ],
    );
  }
}

class _BodyStep extends StatelessWidget {
  const _BodyStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.bodyTitle,
          body: OnboardingCopy.bodyBody,
        ),
        _QuantityStepper(
          label: OnboardingCopy.height,
          value: '${draft.heightCm}',
          unit: OnboardingCopy.centimeter,
          minusKey: const Key('onb_height_minus'),
          plusKey: const Key('onb_height_plus'),
          onMinus: () => onChanged(
            draft.copyWith(
              heightCm: (draft.heightCm - 1).clamp(
                BodyDefaults.minHeightCm,
                BodyDefaults.maxHeightCm,
              ),
            ),
          ),
          onPlus: () => onChanged(
            draft.copyWith(
              heightCm: (draft.heightCm + 1).clamp(
                BodyDefaults.minHeightCm,
                BodyDefaults.maxHeightCm,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuantityStepper(
          label: OnboardingCopy.weight,
          value: _formatKg(draft.weightKg),
          unit: OnboardingCopy.kilogram,
          minusKey: const Key('onb_weight_minus'),
          plusKey: const Key('onb_weight_plus'),
          onMinus: () => onChanged(
            draft.copyWith(
              weightKg: _clampWeight(
                draft.weightKg - BodyDefaults.weightStepKg,
              ),
            ),
          ),
          onPlus: () => onChanged(
            draft.copyWith(
              weightKg: _clampWeight(
                draft.weightKg + BodyDefaults.weightStepKg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.goalTitle,
          body: OnboardingCopy.goalBody,
        ),
        for (final TrainingGoal goal in TrainingGoal.values)
          OnboardingSelectCard(
            cardKey: Key('onb_goal_${goal.wireName}'),
            title: goal.labelZh,
            selected: draft.goal == goal,
            onTap: () => onChanged(draft.copyWith(goal: goal)),
          ),
      ],
    );
  }
}

class _FreqStep extends StatelessWidget {
  const _FreqStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.freqTitle,
          body: OnboardingCopy.freqBody,
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (
              int day = PlanLimits.minDaysPerWeek;
              day <= PlanLimits.maxDaysPerWeek;
              day++
            )
              ChoiceChip(
                key: Key('onb_freq_$day'),
                label: Text('$day 天'),
                selected: draft.daysPerWeek == day,
                onSelected: (bool _) =>
                    onChanged(draft.copyWith(daysPerWeek: day)),
                showCheckmark: false,
                backgroundColor: colors.muted,
                selectedColor: colors.primarySoft,
                labelStyle: TextStyle(
                  color: draft.daysPerWeek == day
                      ? colors.primary
                      : colors.textSecondary,
                  fontWeight: draft.daysPerWeek == day
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontFamilyFallback: AppFonts.cjkFallback,
                ),
                side: BorderSide(
                  color: draft.daysPerWeek == day
                      ? colors.primary
                      : colors.border,
                ),
                shape: const StadiumBorder(),
              ),
          ],
        ),
      ],
    );
  }
}

class _EquipStep extends StatelessWidget {
  const _EquipStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('onb_equip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.equipTitle,
          body: OnboardingCopy.equipBody,
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_equip_fullGym'),
          title: EquipmentProfile.fullGym.labelZh,
          subtitle: OnboardingCopy.equipGymBody,
          selected: draft.equipment == EquipmentProfile.fullGym,
          leading: Icon(
            Icons.apartment_outlined,
            color: CurveColors.of(context).primary,
          ),
          onTap: () =>
              onChanged(draft.copyWith(equipment: EquipmentProfile.fullGym)),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_equip_dumbbells'),
          title: EquipmentProfile.dumbbells.labelZh,
          subtitle: OnboardingCopy.equipDumbbellBody,
          selected: draft.equipment == EquipmentProfile.dumbbells,
          leading: Icon(
            Icons.fitness_center,
            color: CurveColors.of(context).primary,
          ),
          onTap: () =>
              onChanged(draft.copyWith(equipment: EquipmentProfile.dumbbells)),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_equip_bodyweight'),
          title: EquipmentProfile.bodyweight.labelZh,
          subtitle: OnboardingCopy.equipBodyweightBody,
          selected: draft.equipment == EquipmentProfile.bodyweight,
          leading: Icon(
            Icons.accessibility_new,
            color: CurveColors.of(context).primary,
          ),
          onTap: () =>
              onChanged(draft.copyWith(equipment: EquipmentProfile.bodyweight)),
        ),
      ],
    );
  }
}

class _ExperienceStep extends StatelessWidget {
  const _ExperienceStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.expTitle,
          body: OnboardingCopy.expBody,
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_exp_beginner'),
          title: OnboardingCopy.expBeginner,
          selected: draft.experience == TrainingExperience.beginner,
          onTap: () => onChanged(
            draft.copyWith(experience: TrainingExperience.beginner),
          ),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_exp_intermediate'),
          title: OnboardingCopy.expMid,
          selected: draft.experience == TrainingExperience.intermediate,
          onTap: () => onChanged(
            draft.copyWith(experience: TrainingExperience.intermediate),
          ),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_exp_advanced'),
          title: OnboardingCopy.expAdvanced,
          selected: draft.experience == TrainingExperience.advanced,
          onTap: () => onChanged(
            draft.copyWith(experience: TrainingExperience.advanced),
          ),
        ),
      ],
    );
  }
}

class _PreferStep extends StatelessWidget {
  const _PreferStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('onb_prefer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.preferTitle,
          body: OnboardingCopy.preferBody,
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.35,
          children: <Widget>[
            for (final TrainingPreference preference
                in TrainingPreference.values)
              _PreferTile(
                preference: preference,
                selected: draft.preferences.contains(preference),
                onTap: () {
                  final Set<TrainingPreference> next =
                      Set<TrainingPreference>.from(draft.preferences);
                  if (!next.add(preference)) {
                    next.remove(preference);
                  }
                  onChanged(draft.copyWith(preferences: next));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _PreferTile extends StatelessWidget {
  const _PreferTile({
    required this.preference,
    required this.selected,
    required this.onTap,
  });

  final TrainingPreference preference;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: selected ? colors.primarySoft : colors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: Key('onb_prefer_${preference.wireName}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _preferenceIcon(preference),
                color: selected ? colors.primary : colors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _preferenceLabel(preference),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.draft, required this.onChanged});

  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const OnboardingStepHeader(
          title: OnboardingCopy.activityTitle,
          body: OnboardingCopy.activityBody,
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_activity_sedentary'),
          title: OnboardingCopy.activitySedentary,
          selected: draft.activity == DailyActivity.sedentary,
          onTap: () =>
              onChanged(draft.copyWith(activity: DailyActivity.sedentary)),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_activity_light'),
          title: OnboardingCopy.activityLight,
          selected: draft.activity == DailyActivity.light,
          onTap: () => onChanged(draft.copyWith(activity: DailyActivity.light)),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_activity_moderate'),
          title: OnboardingCopy.activityModerate,
          selected: draft.activity == DailyActivity.moderate,
          onTap: () =>
              onChanged(draft.copyWith(activity: DailyActivity.moderate)),
        ),
        OnboardingSelectCard(
          cardKey: const Key('onb_activity_active'),
          title: OnboardingCopy.activityActive,
          selected: draft.activity == DailyActivity.active,
          onTap: () =>
              onChanged(draft.copyWith(activity: DailyActivity.active)),
        ),
      ],
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody();

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Column(
      key: const Key('onb_done'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.check_circle, color: colors.success, size: 36),
        const SizedBox(height: AppSpacing.md),
        Text(
          OnboardingCopy.doneTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          OnboardingCopy.doneBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.minusKey,
    required this.plusKey,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final String unit;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '$value $unit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          IconButton(
            key: minusKey,
            onPressed: onMinus,
            icon: Icon(Icons.remove, color: colors.textPrimary),
          ),
          IconButton(
            key: plusKey,
            onPressed: onPlus,
            icon: Icon(Icons.add, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

IconData _preferenceIcon(TrainingPreference preference) {
  return switch (preference) {
    TrainingPreference.push => Icons.fitness_center,
    TrainingPreference.pull => Icons.rowing,
    TrainingPreference.legs => Icons.directions_walk,
    TrainingPreference.core => Icons.self_improvement,
  };
}

String _preferenceLabel(TrainingPreference preference) {
  return switch (preference) {
    TrainingPreference.push => OnboardingCopy.preferPush,
    TrainingPreference.pull => OnboardingCopy.preferPull,
    TrainingPreference.legs => OnboardingCopy.preferLegs,
    TrainingPreference.core => OnboardingCopy.preferCore,
  };
}

double _clampWeight(double value) {
  return value
      .clamp(BodyDefaults.minWeightKg, BodyDefaults.maxWeightKg)
      .toDouble();
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
