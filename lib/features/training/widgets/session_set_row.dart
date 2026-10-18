import 'dart:async';

import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/previous_sets.dart';
import 'package:curvefree/features/training/widgets/numeric_keypad_sheet.dart';
import 'package:flutter/material.dart';

class SessionSetHeader extends StatelessWidget {
  const SessionSetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: <Widget>[
        SizedBox(
          width: AppLayout.setIndexSize,
          child: Text(AppStrings.setColumn, style: style),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: AppLayout.previousColumnFlex,
          child: Text(AppStrings.lastHintPrefix, style: style),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: AppLayout.loadColumnFlex,
          child: Text(AppStrings.weightColumn, style: style),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: AppLayout.repsColumnFlex,
          child: Text(AppStrings.repsColumn, style: style),
        ),
        SizedBox(
          width: AppLayout.setCheckSlot,
          child: Text(
            AppStrings.checkColumn,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ],
    );
  }
}

class SessionSetRow extends StatefulWidget {
  const SessionSetRow({
    super.key,
    required this.index,
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleCompleted,
    this.previous,
    this.focused = false,
    this.interactive = true,
    this.onApplyPrevious,
  });

  final int index;
  final WorkoutSet set;
  final WorkoutSet? previous;
  final bool focused;

  /// Finished sessions keep the numbers visible and ignore taps.
  final bool interactive;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggleCompleted;
  final VoidCallback? onApplyPrevious;

  @override
  State<SessionSetRow> createState() => _SessionSetRowState();
}

class _SessionSetRowState extends State<SessionSetRow> {
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    if (widget.focused) {
      _revealFocusedRow();
    }
  }

  @override
  void didUpdateWidget(SessionSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused && !oldWidget.focused) {
      _revealFocusedRow();
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  /// Waits for the rest bar to finish opening, then scrolls.
  ///
  /// The bar grows over [AppMotion.restCollapse]. Scrolling before that
  /// measures the taller list and leaves the next set under the bar.
  void _revealFocusedRow() {
    _revealTimer?.cancel();
    _revealTimer = Timer(AppMotion.restCollapse, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.focused) {
          return;
        }
        final ScrollableState? scrollable = Scrollable.maybeOf(context);
        if (scrollable == null || !scrollable.position.hasContentDimensions) {
          return;
        }
        unawaited(
          Scrollable.ensureVisible(
            context,
            alignment: AppLayout.focusRowAlignment,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final WorkoutSet set = widget.set;
    final bool done = set.completed;
    final bool highlight = widget.focused && !done;
    final int index = widget.index;
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
          border: Border.all(
            color: done
                ? colors.success
                : highlight
                ? colors.primary
                : colors.border,
            width: highlight
                ? AppLayout.focusBorderWidth
                : AppLayout.borderWidth,
          ),
        ),
        child: Row(
          children: <Widget>[
            _IndexBadge(index: index + 1, completed: done),
            const SizedBox(width: AppSpacing.xs),
            _PreviousLoad(
              index: index,
              label: formatPreviousLoad(widget.previous),
              onTap: widget.interactive && widget.previous != null
                  ? widget.onApplyPrevious
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: AppLayout.loadColumnFlex,
              child: _ValueChip(
                label: formatWeightKg(set.weightKg),
                onTap: widget.interactive
                    ? () async {
                        final double? value = await NumericKeypadSheet.show(
                          context: context,
                          kind: NumericFieldKind.weightKg,
                          initial: set.weightKg,
                          title: AppStrings.weightColumn,
                        );
                        if (value != null) {
                          widget.onWeightChanged(value);
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: AppLayout.repsColumnFlex,
              child: _ValueChip(
                label: '${set.reps}',
                onTap: widget.interactive
                    ? () async {
                        final double? value = await NumericKeypadSheet.show(
                          context: context,
                          kind: NumericFieldKind.reps,
                          initial: set.reps.toDouble(),
                          title: AppStrings.repsColumn,
                        );
                        if (value != null) {
                          widget.onRepsChanged(value.round());
                        }
                      }
                    : null,
              ),
            ),
            SizedBox(
              width: AppLayout.setCheckSlot,
              child: widget.interactive
                  ? IconButton(
                      key: Key('set_complete_$index'),
                      tooltip: done
                          ? AppStrings.workoutFinished
                          : AppStrings.setColumn,
                      onPressed: widget.onToggleCompleted,
                      icon: Icon(
                        done ? Icons.check_circle : Icons.circle_outlined,
                        color: done ? colors.success : colors.textTertiary,
                      ),
                    )
                  : Center(
                      child: Icon(
                        key: Key('set_complete_$index'),
                        done ? Icons.check_circle : Icons.circle_outlined,
                        color: done ? colors.success : colors.textTertiary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousLoad extends StatelessWidget {
  const _PreviousLoad({
    required this.index,
    required this.label,
    required this.onTap,
  });

  final int index;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final Text text = Text(
      label,
      key: onTap == null ? Key('previous_set_$index') : null,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: onTap == null ? colors.textTertiary : colors.textSecondary,
      ),
    );
    return Expanded(
      flex: AppLayout.previousColumnFlex,
      child: onTap == null
          ? Align(alignment: Alignment.centerLeft, child: text)
          : InkWell(
              key: Key('previous_set_$index'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Align(alignment: Alignment.centerLeft, child: text),
            ),
    );
  }
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final Widget labelText = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: onTap == null
          ? labelText
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: labelText,
            ),
    );
  }
}
