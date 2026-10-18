import 'dart:async';

import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/home/muscle_groups.dart';
import 'package:curvefree/features/home/week_progress.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:curvefree/features/training/resume_copy.dart';
import 'package:flutter/material.dart';

class TodayResumeCard extends StatefulWidget {
  const TodayResumeCard({
    super.key,
    required this.name,
    required this.timerOrigin,
    required this.completedSets,
    required this.volumeKg,
    required this.onResume,
  });

  final String name;
  final DateTime? timerOrigin;
  final int completedSets;
  final double volumeKg;
  final VoidCallback onResume;

  @override
  State<TodayResumeCard> createState() => _TodayResumeCardState();
}

class _TodayResumeCardState extends State<TodayResumeCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(TodayResumeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.timerOrigin == null) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(RestTimerLimits.tick, (Timer timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final Duration? elapsed = widget.timerOrigin == null
        ? null
        : DateTime.now().difference(widget.timerOrigin!);
    return Container(
      key: const Key('home_resume_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(
        colors,
        borderColor: colors.primary,
        borderWidth: AppLayout.focusBorderWidth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ResumeCopy.cardTitle(name: widget.name, elapsed: elapsed),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ResumeCopy.cardSubtitle(
              completedSets: widget.completedSets,
              volumeKg: widget.volumeKg,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('home_resume_workout'),
              onPressed: widget.onResume,
              child: const Text(AppStrings.resumeContinue),
            ),
          ),
        ],
      ),
    );
  }
}

class TodaySwitchPlanLink extends StatelessWidget {
  const TodaySwitchPlanLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: const Key('home_switch_today_plan'),
        onPressed: onTap,
        child: const Text(AppStrings.switchToTodayPlan),
      ),
    );
  }
}

class WeekProgressCard extends StatelessWidget {
  const WeekProgressCard({super.key, required this.progress});

  final WeekProgress progress;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final String volume = progress.volumeKg.toStringAsFixed(0);
    return Container(
      key: const Key('home_week_progress'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.weekProgress,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressTrack(fraction: progress.dayFraction),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              _Stat(label: AppStrings.training, value: progress.sessionsLabel),
              _Stat(
                label: AppStrings.volumeLabel,
                value: '$volume ${AppStrings.weightColumn}',
              ),
              _Stat(
                label: AppStrings.statCompletion,
                value: progress.completionLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return SizedBox(
      height: AppLayout.progressEndpoint,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth * fraction;
          final double endpointLeft = (width - AppLayout.progressEndpoint / 2)
              .clamp(0, constraints.maxWidth - AppLayout.progressEndpoint)
              .toDouble();
          return Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Container(
                height: AppLayout.progressBarHeight,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
              ),
              Container(
                width: width,
                height: AppLayout.progressBarHeight,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
              ),
              if (fraction > 0)
                Positioned(
                  left: endpointLeft,
                  child: Container(
                    width: AppLayout.progressEndpoint,
                    height: AppLayout.progressEndpoint,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class MuscleGroupDots extends StatelessWidget {
  const MuscleGroupDots({
    super.key,
    required this.trained,
    required this.planned,
    required this.title,
  });

  final Set<MuscleGroup> trained;
  final Set<MuscleGroup> planned;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home_muscle_groups'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            for (final MuscleGroup group in MuscleGroup.values)
              Expanded(
                child: _Dot(
                  group: group,
                  state: muscleDotState(
                    group: group,
                    trained: trained,
                    planned: planned,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.group, required this.state});

  final MuscleGroup group;
  final MuscleDotState state;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final Color fill;
    final Color ring;
    final Color label;
    switch (state) {
      case MuscleDotState.trained:
        fill = colors.primary;
        ring = colors.primary;
        label = colors.primary;
      case MuscleDotState.planned:
        fill = colors.primarySoft;
        ring = colors.primary;
        label = colors.textPrimary;
      case MuscleDotState.idle:
        fill = colors.muted;
        ring = colors.borderStrong;
        label = colors.textTertiary;
    }
    return Column(
      children: <Widget>[
        Container(
          width: AppLayout.muscleDot,
          height: AppLayout.muscleDot,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: ring),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          group.labelZh,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: label),
        ),
      ],
    );
  }
}

class TodayTrendEntry extends StatelessWidget {
  const TodayTrendEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: const Key('home_open_trend'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: curveSurfaceDecoration(colors),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.weekTrend,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(Icons.show_chart, color: colors.primary),
              Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({super.key, required this.session, required this.onTap});

  final PlannedSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final String day = PlanWeekdays.label(session.weekday);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: const Key('home_today_plan'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: curveSurfaceDecoration(colors),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      AppStrings.todayPlan,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$day · ${session.title}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (session.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    AppStrings.startFromPlan,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              else
                for (final PlannedItem item in session.items)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      '${item.nameZh}  ${item.sets}×${item.reps}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayRestCard extends StatelessWidget {
  const TodayRestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Container(
      key: const Key('home_today_rest'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors, color: colors.muted),
      child: Text(
        AppStrings.todayRest,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class TodayPlanEmptyCard extends StatelessWidget {
  const TodayPlanEmptyCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: const Key('home_plan_empty'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: curveSurfaceDecoration(colors),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.todayPlan,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      AppStrings.emptyPlan,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
