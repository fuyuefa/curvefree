import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/plan/plan_providers.dart';
import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  TrainingGoal _goal = TrainingGoal.hypertrophy;
  EquipmentProfile _equipment = EquipmentProfile.fullGym;
  int _days = PlanLimits.defaultDaysPerWeek;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(trainingPlanProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.trainingPlanTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('目标', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final TrainingGoal goal in TrainingGoal.values)
                ChoiceChip(
                  label: Text(goal.labelZh),
                  selected: _goal == goal,
                  onSelected: (_) => setState(() => _goal = goal),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('器械', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final EquipmentProfile profile in EquipmentProfile.values)
                ChoiceChip(
                  label: Text(profile.labelZh),
                  selected: _equipment == profile,
                  onSelected: (_) => setState(() => _equipment = profile),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${AppStrings.daysPerWeek} $_days',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            key: const Key('slider_plan_days'),
            min: PlanLimits.minDaysPerWeek.toDouble(),
            max: PlanLimits.maxDaysPerWeek.toDouble(),
            divisions: PlanLimits.maxDaysPerWeek - PlanLimits.minDaysPerWeek,
            value: _days.toDouble(),
            label: '$_days',
            onChanged: (double value) => setState(() => _days = value.round()),
          ),
          FilledButton(
            key: const Key('btn_generate_plan'),
            onPressed: () {
              ref
                  .read(trainingPlanProvider.notifier)
                  .generate(
                    goal: _goal,
                    daysPerWeek: _days,
                    equipment: _equipment,
                  );
            },
            child: const Text(AppStrings.generatePlan),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (plan == null)
            const Text(AppStrings.emptyPlan)
          else ...[
            Text(
              '${plan.goal.labelZh} · ${plan.equipment.labelZh} · 每周 ${plan.daysPerWeek} 练',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final PlannedSession session in plan.sessions)
              _SessionCard(session: session, onStart: () => _start(session)),
          ],
        ],
      ),
    );
  }

  Future<void> _start(PlannedSession planned) async {
    final workout = await ref
        .read(workoutSessionsProvider.notifier)
        .startFromPlan(planned);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPage(sessionId: workout.id),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onStart});

  final PlannedSession session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final day = PlanWeekdays.label(session.weekday);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(CurveColors.of(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day · ${session.title}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final PlannedItem item in session.items)
            Text(
              '${item.nameZh}  ${item.sets}×${item.reps}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onStart,
              child: const Text(AppStrings.startFromPlan),
            ),
          ),
        ],
      ),
    );
  }
}
