import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/home/week_trend.dart';
import 'package:curvefree/features/home/widgets/volume_sparkline.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrainTrendPage extends ConsumerWidget {
  const TrainTrendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<WorkoutSession> sessions =
        ref.watch(workoutSessionsProvider).valueOrNull ??
        const <WorkoutSession>[];
    final WeekTrend trend = summarizeWeekTrend(
      now: DateTime.now(),
      sessions: sessions,
    );
    final CurveColors colors = CurveColors.of(context);
    final String volume = trend.volumeKg.toStringAsFixed(0);
    return Scaffold(
      key: const Key('train_trend_page'),
      appBar: AppBar(title: const Text(AppStrings.weekTrend)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: curveSurfaceDecoration(colors),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.weekFinishedLine(trend.finishedSessionCount),
                  key: const Key('train_trend_count'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppStrings.recentVolumeLine(
                    days: WeekTrendLimits.dayCount,
                    volume: volume,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                VolumeSparkline(
                  volumes: <double>[
                    for (final DayVolume day in trend.days) day.volumeKg,
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    for (final DayVolume day in trend.days)
                      Expanded(
                        child: Text(
                          PlanWeekdays.label(day.day.weekday),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
                if (!trend.hasVolume) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.trendNoVolumeLine(WeekTrendLimits.dayCount),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
