import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:flutter/material.dart';

String formatTodayDate(DateTime date) {
  final DateTime local = date.toLocal();
  final String weekday = PlanWeekdays.label(local.weekday);
  return '${local.month}月${local.day}日 $weekday';
}

class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final DateTime date = now ?? DateTime.now();
    return Row(
      children: <Widget>[
        Container(
          width: AppLayout.accentStripWidth,
          height: AppLayout.accentStripHeight,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          AppStrings.navToday,
          key: const Key('home_today_title'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Spacer(),
        Text(
          formatTodayDate(date),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
