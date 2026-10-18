import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/material.dart';

enum StartConflictChoice { resumeCurrent, finishAndStartNew, cancel }

/// Shared three-choice sheet for starting while a session is still open.
Future<StartConflictChoice> showStartConflictSheet(BuildContext context) async {
  final StartConflictChoice? choice =
      await showModalBottomSheet<StartConflictChoice>(
        context: context,
        backgroundColor: CurveColors.of(context).elevated,
        isScrollControlled: true,
        builder: (BuildContext sheetContext) {
          return const StartConflictSheet();
        },
      );
  return choice ?? StartConflictChoice.cancel;
}

class StartConflictSheet extends StatefulWidget {
  const StartConflictSheet({super.key});

  @override
  State<StartConflictSheet> createState() => _StartConflictSheetState();
}

class _StartConflictSheetState extends State<StartConflictSheet> {
  bool _chosen = false;

  void _choose(StartConflictChoice choice) {
    if (_chosen) {
      return;
    }
    _chosen = true;
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      key: const Key('today_conflict_sheet'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            AppStrings.startConflictTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.startConflictBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('today_conflict_resume'),
            onPressed: () => _choose(StartConflictChoice.resumeCurrent),
            child: const Text(AppStrings.conflictResumeCurrent),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            key: const Key('today_conflict_finish_new'),
            onPressed: () => _choose(StartConflictChoice.finishAndStartNew),
            child: const Text(AppStrings.conflictFinishAndStart),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: const Key('today_conflict_cancel'),
            onPressed: () => _choose(StartConflictChoice.cancel),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }
}
