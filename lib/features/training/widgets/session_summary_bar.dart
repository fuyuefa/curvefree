import 'dart:async';

import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter/material.dart';

class SessionSummaryBar extends StatelessWidget {
  const SessionSummaryBar({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final String volume = session.volumeKg.toStringAsFixed(0);
    return Container(
      key: const Key('session_summary'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: curveSurfaceDecoration(colors, color: colors.muted),
      child: Row(
        children: <Widget>[
          _SummaryStat(
            label: AppStrings.volumeLabel,
            value: '$volume ${AppStrings.weightColumn}',
          ),
          _SummaryDivider(color: colors.borderStrong),
          _SummaryStat(
            label: AppStrings.setsCountLabel,
            value: '${session.completedSetCount}',
          ),
          _SummaryDivider(color: colors.borderStrong),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  AppStrings.elapsedLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                ElapsedClock(
                  startedAt: session.startedAt,
                  endedAt: session.endedAt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: color);
  }
}

class ElapsedClock extends StatefulWidget {
  const ElapsedClock({
    super.key,
    required this.startedAt,
    required this.endedAt,
  });

  final DateTime startedAt;
  final DateTime? endedAt;

  @override
  State<ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<ElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.endedAt == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void didUpdateWidget(ElapsedClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endedAt != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime end = widget.endedAt ?? DateTime.now();
    return Text(
      ElapsedFormat.format(end.difference(widget.startedAt)),
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
