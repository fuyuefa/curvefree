import 'dart:async';

import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/home/muscle_groups.dart';
import 'package:curvefree/features/home/week_progress.dart';
import 'package:curvefree/features/home/widgets/today_cards.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/pages/plan_page.dart';
import 'package:curvefree/features/plan/plan_providers.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/unfinished_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodayTrainingSection extends ConsumerWidget {
  const TodayTrainingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LocalStoreSnapshot> store = ref.watch(
      localStoreSnapshotProvider,
    );
    final AsyncValue<List<WorkoutSession>> sessions = ref.watch(
      workoutSessionsProvider,
    );
    if (store.isLoading || sessions.isLoading) {
      return const SizedBox.shrink();
    }
    final TrainingPlan? plan = ref.watch(trainingPlanProvider);
    final List<WorkoutSession> loaded =
        sessions.valueOrNull ?? const <WorkoutSession>[];
    final DateTime now = DateTime.now();
    final WorkoutSession? unfinished = newestUnfinishedSession(loaded);
    final PlannedSession? today = plan?.sessionForWeekday(now.weekday);
    final WeekProgress progress = summarizeWeek(
      now: now,
      sessions: loaded,
      plan: plan,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (unfinished != null) ...<Widget>[
          TodayResumeCard(
            detail: _resumeDetail(unfinished, now),
            onTap: () {
              Navigator.of(context).push(sessionPageRoute(unfinished.id));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        WeekProgressCard(progress: progress),
        const SizedBox(height: AppSpacing.sm),
        MuscleGroupDots(
          trained: trainedMuscleGroups(sessions: loaded, now: now),
          planned: plannedMuscleGroups(today),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (today != null)
          TodayPlanCard(
            session: today,
            onTap: () {
              unawaited(_startToday(context, ref, today));
            },
          )
        else if (plan != null)
          const TodayRestCard()
        else
          TodayPlanEmptyCard(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const PlanPage()));
            },
          ),
      ],
    );
  }

  Future<void> _startToday(
    BuildContext context,
    WidgetRef ref,
    PlannedSession planned,
  ) async {
    final WorkoutSession workout = await ref
        .read(workoutSessionsProvider.notifier)
        .startFromPlan(planned);
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(sessionPageRoute(workout.id));
  }
}

String _resumeDetail(WorkoutSession session, DateTime now) {
  final String elapsed = ElapsedFormat.format(
    now.difference(session.startedAt),
  );
  final String volume = session.volumeKg.toStringAsFixed(0);
  return '$elapsed · ${session.completedSetCount} ${AppStrings.setColumn} · ${AppStrings.volumeLabel} $volume ${AppStrings.weightColumn}';
}
