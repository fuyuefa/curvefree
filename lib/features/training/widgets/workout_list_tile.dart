import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkoutListTile extends StatelessWidget {
  const WorkoutListTile({
    super.key,
    required this.session,
    required this.onTap,
  });

  final WorkoutSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy-MM-dd HH:mm').format(session.startedAt);
    final status = session.isFinished
        ? AppStrings.workoutFinished
        : session.isTimerRunning
        ? AppStrings.workoutInProgress
        : AppStrings.workoutPreparing;
    final volume = session.volumeKg.toStringAsFixed(0);

    final CurveColors colors = CurveColors.of(context);
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(color: colors.border),
    );
    return Material(
      color: colors.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$status · ${session.completedSetCount} 组 · ${AppStrings.volumeLabel} $volume kg',
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
