import 'dart:async';

import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
import 'package:curvefree/features/training/rest_end_flash.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key, required this.sessionId, this.exerciseName});

  final String sessionId;
  final String? exerciseName;

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(RestTimerLimits.tick, _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      return;
    }
    final DateTime now = ref.read(restTimerProvider.notifier).clock();
    ref.read(restTimerProvider.notifier).noteNaturalEnd(now);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final RestTimerState rest = ref.watch(restTimerProvider);
    final DateTime now = ref.read(restTimerProvider.notifier).clock();
    final String label = widget.exerciseName == null
        ? AppStrings.restTimerLabel
        : '${AppStrings.restTimerLabel} · ${widget.exerciseName}';
    final TextStyle? countdownStyle = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(
          color: colors.primary,
          fontSize: AppLayout.restCountdownSize,
          fontWeight: FontWeight.w600,
        );
    final bool flashing = rest.endFlashActiveFor(widget.sessionId, now);
    final Color fill = flashing
        ? restEndPeakFill(
            idle: colors.primarySoft,
            primarySoft: colors.primarySoft,
            primary: colors.primary,
          )
        : colors.primarySoft;
    return AnimatedContainer(
      key: const Key('rest_timer_bar'),
      duration: AppMotion.restEndFlash,
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: curveSurfaceDecoration(colors, color: fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ElapsedFormat.format(rest.remainingAt(now)),
            key: const Key('rest_timer_remaining'),
            style: countdownStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              TextButton(
                key: const Key('btn_rest_skip'),
                onPressed: () {
                  ref.read(restTimerProvider.notifier).skip();
                },
                child: const Text(AppStrings.restEnoughNextSet),
              ),
              const Spacer(),
              Tooltip(
                message: restShorterTooltip(),
                child: OutlinedButton(
                  key: const Key('btn_rest_minus'),
                  onPressed: () {
                    ref
                        .read(restTimerProvider.notifier)
                        .adjust(-RestTimerLimits.stepSeconds);
                  },
                  child: Text(restAdjustLabel(increase: false)),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: restLongerTooltip(),
                child: OutlinedButton(
                  key: const Key('btn_rest_plus'),
                  onPressed: () {
                    ref
                        .read(restTimerProvider.notifier)
                        .adjust(RestTimerLimits.stepSeconds);
                  },
                  child: Text(restAdjustLabel(increase: true)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
