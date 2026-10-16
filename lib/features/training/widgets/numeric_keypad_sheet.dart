import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:flutter/material.dart';

enum NumericFieldKind { weightKg, reps }

/// Large gym keypad: tool-app entry, not a tiny system keyboard.
class NumericKeypadSheet extends StatefulWidget {
  const NumericKeypadSheet({
    super.key,
    required this.kind,
    required this.initialValue,
    required this.title,
  });

  final NumericFieldKind kind;
  final String initialValue;
  final String title;

  static Future<double?> show({
    required BuildContext context,
    required NumericFieldKind kind,
    required double initial,
    required String title,
  }) {
    final String initialText = kind == NumericFieldKind.weightKg
        ? _formatWeight(initial)
        : initial.round().toString();
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: CurveColors.of(context).elevated,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return NumericKeypadSheet(
          kind: kind,
          initialValue: initialText,
          title: title,
        );
      },
    );
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(TrainingDefaults.weightFractionDigits);
  }

  @override
  State<NumericKeypadSheet> createState() => _NumericKeypadSheetState();
}

class _NumericKeypadSheetState extends State<NumericKeypadSheet> {
  late String _buffer;

  @override
  void initState() {
    super.initState();
    _buffer = widget.initialValue;
  }

  void _pushDigit(String digit) {
    setState(() {
      if (_buffer == '0' && digit != '.') {
        _buffer = digit;
        return;
      }
      if (digit == '.' && _buffer.contains('.')) {
        return;
      }
      if (widget.kind == NumericFieldKind.reps && digit == '.') {
        return;
      }
      if (widget.kind == NumericFieldKind.weightKg &&
          _buffer.contains('.') &&
          _buffer.split('.').last.length >=
              TrainingDefaults.weightFractionDigits) {
        return;
      }
      _buffer = '$_buffer$digit';
    });
  }

  void _backspace() {
    setState(() {
      if (_buffer.isEmpty) {
        return;
      }
      _buffer = _buffer.substring(0, _buffer.length - 1);
      if (_buffer.isEmpty) {
        _buffer = '0';
      }
    });
  }

  void _submit() {
    final parsed = double.tryParse(_buffer) ?? 0;
    Navigator.of(context).pop(_clamp(parsed));
  }

  double _clamp(double value) {
    if (widget.kind == NumericFieldKind.reps) {
      return value
          .round()
          .clamp(TrainingDefaults.minReps, TrainingDefaults.maxReps)
          .toDouble();
    }
    return value.clamp(
      TrainingDefaults.minWeightKg,
      TrainingDefaults.maxWeightKg,
    );
  }

  @override
  Widget build(BuildContext context) {
    const keys = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      '⌫',
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _buffer,
              key: const Key('keypad_buffer'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 1.6,
              children: [
                for (final String key in keys)
                  _KeypadButton(
                    label: key,
                    onTap: () {
                      if (key == '⌫') {
                        _backspace();
                      } else {
                        _pushDigit(key);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text(AppStrings.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(AppRadii.cta),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.cta),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
