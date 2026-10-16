import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:curvefree/features/training/widgets/numeric_keypad_sheet.dart';
import 'package:flutter/material.dart';

class SessionSetRow extends StatelessWidget {
  const SessionSetRow({
    super.key,
    required this.index,
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleCompleted,
  });

  final int index;
  final WorkoutSet set;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final bool done = set.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        key: Key('set_row_$index'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: done ? colors.successSoft : colors.muted,
          borderRadius: BorderRadius.circular(AppRadii.cta),
          border: Border.all(color: done ? colors.success : colors.border),
        ),
        child: Row(
          children: <Widget>[
            _IndexBadge(index: index + 1, completed: done),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ValueChip(
                label: _weightLabel(set.weightKg),
                onTap: () async {
                  final double? value = await NumericKeypadSheet.show(
                    context: context,
                    kind: NumericFieldKind.weightKg,
                    initial: set.weightKg,
                    title: AppStrings.weightColumn,
                  );
                  if (value != null) {
                    onWeightChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ValueChip(
                label: '${set.reps}',
                onTap: () async {
                  final double? value = await NumericKeypadSheet.show(
                    context: context,
                    kind: NumericFieldKind.reps,
                    initial: set.reps.toDouble(),
                    title: AppStrings.repsColumn,
                  );
                  if (value != null) {
                    onRepsChanged(value.round());
                  }
                },
              ),
            ),
            IconButton(
              key: Key('set_complete_$index'),
              tooltip: done ? AppStrings.workoutFinished : AppStrings.setColumn,
              onPressed: onToggleCompleted,
              icon: Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? colors.success : colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _weightLabel(double weightKg) {
  final int digits = weightKg == weightKg.roundToDouble()
      ? 0
      : TrainingDefaults.weightFractionDigits;
  return weightKg.toStringAsFixed(digits);
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.completed});

  final int index;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Container(
      width: AppLayout.setIndexSize,
      height: AppLayout.setIndexSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? colors.success : colors.card,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: completed ? colors.onPrimary : colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}
