import 'dart:async';

import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/home/widgets/module_tile.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/plan/plan_providers.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodayTrainingSection extends ConsumerWidget {
  const TodayTrainingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(localStoreSnapshotProvider);
    final sessions = ref.watch(workoutSessionsProvider);
    if (store.isLoading || sessions.isLoading) {
      return const SizedBox.shrink();
    }
    final plan = ref.watch(trainingPlanProvider);
    final unfinished = _newestUnfinished(sessions.valueOrNull);
    final today = plan?.sessionForWeekday(DateTime.now().weekday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unfinished != null) ...[
          ModuleTile(
            key: const Key('home_resume_workout'),
            title: AppStrings.resumeWorkout,
            subtitle: _resumeSubtitle(unfinished),
            icon: Icons.play_arrow,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionPage(sessionId: unfinished.id),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (today != null)
          ModuleTile(
            key: const Key('home_today_plan'),
            title:
                '${AppStrings.todayPlan} · ${PlanWeekdays.label(today.weekday)} ${today.title}',
            subtitle: _planSubtitle(today),
            icon: Icons.event_available,
            onTap: () {
              unawaited(_startToday(context, ref, today));
            },
          )
        else if (plan != null)
          const Text(
            AppStrings.todayRest,
            key: Key('home_today_rest'),
            style: TextStyle(color: Color(AppColors.textMuted)),
          ),
        if (unfinished != null || today != null || plan != null)
          const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Future<void> _startToday(
    BuildContext context,
    WidgetRef ref,
    PlannedSession planned,
  ) async {
    final workout = await ref
        .read(workoutSessionsProvider.notifier)
        .startFromPlan(planned);
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPage(sessionId: workout.id),
      ),
    );
  }
}

WorkoutSession? _newestUnfinished(List<WorkoutSession>? sessions) {
  if (sessions == null) {
    return null;
  }
  for (final WorkoutSession session in sessions) {
    if (!session.isFinished) {
      return session;
    }
  }
  return null;
}

String _resumeSubtitle(WorkoutSession session) {
  final names = session.exercises
      .map((WorkoutExercise exercise) => exercise.name.trim())
      .where((String name) => name.isNotEmpty)
      .join('、');
  final volume = session.volumeKg.toStringAsFixed(0);
  final stats =
      '${AppStrings.workoutInProgress} · ${session.completedSetCount} 组 · ${AppStrings.volumeLabel} $volume kg';
  if (names.isEmpty) {
    return stats;
  }
  return '$stats · $names';
}

String _planSubtitle(PlannedSession session) {
  if (session.items.isEmpty) {
    return AppStrings.startFromPlan;
  }
  return session.items
      .map((PlannedItem item) => '${item.nameZh} ${item.sets}×${item.reps}')
      .join('、');
}
