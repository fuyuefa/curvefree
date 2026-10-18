import 'package:curvefree/app/shell/shell_tab.dart';
import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/session_done_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionFinishSummaryPage extends ConsumerWidget {
  const SessionFinishSummaryPage({super.key, required this.summary});

  final SessionDoneSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CurveColors colors = CurveColors.of(context);
    final SessionFinishFigures figures = sessionFinishFigures(summary);
    return Scaffold(
      key: const Key('session_finish_summary'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SummaryTitle(),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _FinishFigure(
                            figureKey: const Key('summary_sets_value'),
                            label: AppStrings.setsCountLabel,
                            value: figures.sets,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FinishFigure(
                            figureKey: const Key('summary_volume_value'),
                            label: AppStrings.volumeLabel,
                            value: figures.volumeKg,
                            unit: AppStrings.weightColumn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _FinishFigure(
                            figureKey: const Key('summary_wall_value'),
                            label: AppStrings.wallClockLabel,
                            value: figures.wallClock,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FinishFigure(
                            figureKey: const Key('summary_rest_value'),
                            label: AppStrings.restTimerLabel,
                            value: figures.rest,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton(
                key: const Key('btn_back_to_today'),
                onPressed: () {
                  popToTodayTab(ref, Navigator.of(context));
                },
                child: const Text(AppStrings.backToToday),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                key: const Key('btn_review_session'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                ),
                child: const Text(AppStrings.reviewThisSession),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTitle extends StatelessWidget {
  const _SummaryTitle();

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
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
          AppStrings.sessionDoneTitle,
          key: const Key('session_done_title'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class _FinishFigure extends StatelessWidget {
  const _FinishFigure({
    required this.figureKey,
    required this.label,
    required this.value,
    this.unit,
  });

  final Key figureKey;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final TextStyle? valueStyle = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(
          fontSize: AppLayout.summaryValueSize,
          height: 1.1,
          color: colors.textPrimary,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(value, key: figureKey, style: valueStyle),
          if (unit != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(unit!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
