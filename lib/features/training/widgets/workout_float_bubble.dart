import 'dart:async';

import 'package:curvefree/app/shell/shell_navigation.dart';
import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/elapsed_format.dart';
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
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final String elapsed = ElapsedFormat.format(
      DateTime.now().difference(origin),
    );
    final String label = '${AppStrings.workoutBubbleLabel} $elapsed';
    return Positioned(
      left: AppSpacing.md,
      bottom: bottom,
      child: Container(
        key: const Key('workout_float_bubble'),
        decoration: curveSurfaceDecoration(
          colors,
          color: colors.elevated,
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
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: colors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resume(String fallbackId) async {
    final WorkoutSession opened = await ref
        .read(workoutSessionsProvider.notifier)
        .startSession();
    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (!mounted || navigator == null) {
      return;
    }
    final String routeName = SessionRoutes.nameFor(opened.id);
    final ShellNavigation navigation = ref.read(shellNavigationProvider);
    if (navigation.topPageRouteName == routeName) {
      return;
    }
    if (navigation.containsPage(routeName) ||
        navigation.containsPage(SessionRoutes.nameFor(fallbackId))) {
      final String target = navigation.containsPage(routeName)
          ? routeName
          : SessionRoutes.nameFor(fallbackId);
      navigator.popUntil((Route<dynamic> route) {
        return route.settings.name == target || route.isFirst;
      });
      return;
    }
    await navigator.push(sessionPageRoute(opened.id));
  }
}
