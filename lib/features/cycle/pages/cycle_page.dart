import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/cycle/cycle_constants.dart';
import 'package:curvefree/features/cycle/cycle_providers.dart';
import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CyclePage extends ConsumerStatefulWidget {
  const CyclePage({super.key});

  @override
  ConsumerState<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends ConsumerState<CyclePage> {
  late CycleProfile _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(cycleProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Scaffold(
      key: const Key('cycle_page'),
      appBar: AppBar(title: const Text(CycleCopy.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: <Widget>[
          Text(
            CycleCopy.localNote,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CycleCopy.periodDays,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final int days in CycleLimits.periodDayOptions)
                _CycleChip(
                  chipKey: Key('cycle_period_$days'),
                  label: '$days',
                  selected: _draft.periodDays == days,
                  onSelected: () => setState(
                    () => _draft = _draft.copyWith(periodDays: days),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CycleCopy.cycleDays,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final int days in CycleLimits.cycleDayOptions)
                _CycleChip(
                  chipKey: Key('cycle_length_$days'),
                  label: '$days',
                  selected: !_draft.cycleUnknown && _draft.cycleDays == days,
                  onSelected: () => setState(
                    () => _draft = _draft.copyWith(
                      cycleDays: days,
                      cycleUnknown: false,
                    ),
                  ),
                ),
              _CycleChip(
                chipKey: const Key('cycle_length_unknown'),
                label: CycleCopy.unknown,
                selected: _draft.cycleUnknown,
                onSelected: () => setState(
                  () => _draft = _draft.copyWith(
                    cycleUnknown: true,
                    clearCycleDays: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CycleCopy.lastStart,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            CycleCopy.optional,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: InkWell(
              key: const Key('cycle_last_start'),
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: curveSurfaceDecoration(colors),
                child: Text(
                  _draft.lastStart == null
                      ? CycleCopy.notYet
                      : formatCycleDate(_draft.lastStart!),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _draft.lastStart == null
                        ? colors.textTertiary
                        : colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (_draft.lastStart != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('cycle_clear_date'),
                onPressed: () => setState(
                  () => _draft = _draft.copyWith(clearLastStart: true),
                ),
                child: const Text(CycleCopy.clearDate),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('cycle_save'),
            onPressed: _draft.isComplete && !_saving ? _save : null,
            child: const Text(CycleCopy.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime first = today.subtract(
      const Duration(days: CycleLimits.lookbackDays),
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _draft.lastStart ?? today,
      firstDate: first,
      lastDate: today,
    );
    if (picked == null) {
      return;
    }
    setState(() => _draft = _draft.copyWith(lastStart: picked));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(cycleProfileProvider.notifier).save(_draft);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _CycleChip extends StatelessWidget {
  const _CycleChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return ChoiceChip(
      key: chipKey,
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: colors.muted,
      selectedColor: colors.primarySoft,
      labelStyle: TextStyle(
        color: selected ? colors.primary : colors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        fontFamily: AppFonts.ui,
        fontFamilyFallback: AppFonts.cjkFallback,
      ),
      side: BorderSide(color: selected ? colors.primary : colors.border),
      shape: const StadiumBorder(),
      onSelected: (bool _) => onSelected(),
    );
  }
}
