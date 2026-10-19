import 'dart:async';

import 'package:curvefree/app/shell/shell_navigation.dart';
import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/haptics/app_haptics.dart';
import 'package:curvefree/features/training/rest_end_flash.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/unfinished_session.dart';
import 'package:curvefree/features/training/workout_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutFloatBubble extends ConsumerStatefulWidget {
  const WorkoutFloatBubble({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<WorkoutFloatBubble> createState() => _WorkoutFloatBubbleState();
}

class _WorkoutFloatBubbleState extends ConsumerState<WorkoutFloatBubble> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(RestTimerLimits.tick, (Timer timer) {
      if (!mounted) {
        return;
      }
      final DateTime now = ref.read(restTimerProvider.notifier).clock();
      ref.read(restTimerProvider.notifier).noteNaturalEnd(now);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onRestCue(RestTimerState? previous, RestTimerState next) {
    final DateTime? until = next.endFlashUntil;
    if (until == null || previous?.endFlashUntil == until) {
      return;
    }
    unawaited(AppHaptics.restEnded());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RestTimerState>(restTimerProvider, _onRestCue);
    final ShellNavigation navigation = ref.watch(shellNavigationProvider);
    final List<WorkoutSession> sessions =
        ref.watch(workoutSessionsProvider).valueOrNull ??
        const <WorkoutSession>[];
    final WorkoutSession? unfinished = newestUnfinishedSession(sessions);
    final bool visible = workoutBubbleVisible(
      unfinished: unfinished,
      topPageRouteName: navigation.topPageRouteName,
      coveredByPopup: navigation.coveredByPopup,
    );
    if (!visible || unfinished == null) {
      return const Positioned(
        left: 0,
        bottom: 0,
        width: 0,
        height: 0,
        child: SizedBox.shrink(),
      );
    }

    final CurveColors colors = CurveColors.of(context);
    final double bottom = workoutBubbleBottomInset(
      topPageRouteName: navigation.topPageRouteName,
      safeBottom: MediaQuery.paddingOf(context).bottom,
    );
    final DateTime origin = unfinished.timerOrigin ?? unfinished.startedAt;
    final RestTimerState rest = ref.watch(restTimerProvider);
    final DateTime now = ref.read(restTimerProvider.notifier).clock();
    final WorkoutBubbleLines lines = workoutBubbleLines(
      elapsed: DateTime.now().difference(origin),
      resting: rest.isRunningFor(unfinished.id, now),
      restRemaining: rest.remainingAt(now),
    );
    final TextStyle? primaryStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: colors.primary);
    final TextStyle? elapsedStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: colors.textSecondary);
    final bool flashing = rest.endFlashActiveFor(unfinished.id, now);
    final Color fill = flashing
        ? restEndPeakFill(
            idle: colors.elevated,
            primarySoft: colors.primarySoft,
            primary: colors.primary,
          )
        : colors.elevated;
    return Positioned(
      left: AppSpacing.md,
      bottom: bottom,
      child: AnimatedContainer(
        key: const Key('workout_float_bubble'),
        duration: AppMotion.restEndFlash,
        curve: Curves.easeOut,
        decoration: curveSurfaceDecoration(
          colors,
          color: fill,
          radius: AppRadii.chip,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              unawaited(_resume(unfinished.id));
            },
            borderRadius: BorderRadius.circular(AppRadii.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.fitness_center,
                    size: AppLayout.iconSize,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        lines.primary,
                        key: const Key('workout_float_primary'),
                        style: primaryStyle,
                      ),
                      if (lines.secondary != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          lines.secondary!,
                          key: const Key('workout_float_elapsed'),
                          style: elapsedStyle,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resume(String sessionId) async {
    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (!mounted || navigator == null) {
      return;
    }
    final ShellNavigation navigation = ref.read(shellNavigationProvider);
    final FloatResume plan = planFloatResume(
      sessionId: sessionId,
      topPageRouteName: navigation.topPageRouteName,
      pageRouteNames: navigation.pageRouteNames,
    );
    switch (plan.kind) {
      case FloatResumeKind.stay:
        return;
      case FloatResumeKind.popToSession:
        navigator.popUntil((Route<dynamic> route) {
          return route.settings.name == plan.routeName || route.isFirst;
        });
        return;
      case FloatResumeKind.pushSession:
        unawaited(navigator.push(sessionPageRoute(sessionId)));
    }
  }
}
