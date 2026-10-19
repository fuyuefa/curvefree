import 'dart:async';

import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:curvefree/features/exercises/pages/exercise_library_page.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/pages/session_finish_summary_page.dart';
import 'package:curvefree/features/training/rest_timer.dart';
import 'package:curvefree/features/training/session_done_summary.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/set_focus.dart';
import 'package:curvefree/features/training/set_template.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/widgets/rest_timer_bar.dart';
import 'package:curvefree/features/training/widgets/session_set_row.dart';
import 'package:curvefree/features/training/widgets/session_summary_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class SessionPage extends ConsumerWidget {
  const SessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutSession>> asyncSessions = ref.watch(
      workoutSessionsProvider,
    );
    return asyncSessions.when(
      loading: () =>
          const Scaffold(body: Center(child: Text(AppStrings.readingWorkout))),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('读取失败：$error')),
      ),
      data: (List<WorkoutSession> sessions) {
        WorkoutSession? session;
        for (final WorkoutSession item in sessions) {
          if (item.id == sessionId) {
            session = item;
            break;
          }
        }
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text(AppStrings.missingWorkout)),
          );
        }
        return _SessionScaffold(session: session);
      },
    );
  }
}

class _SessionScaffold extends ConsumerStatefulWidget {
  const _SessionScaffold({required this.session});

  final WorkoutSession session;

  @override
  ConsumerState<_SessionScaffold> createState() => _SessionScaffoldState();
}

class _SessionScaffoldState extends ConsumerState<_SessionScaffold> {
  bool _promptedForExercise = false;
  String? _focusedSetId;

  WorkoutSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    if (session.exercises.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptCatalogIfEmpty();
      });
    }
  }

  /// Empty start lands on the catalog. Dismissing it does not reopen.
  void _promptCatalogIfEmpty() {
    if (!mounted || _promptedForExercise || session.exercises.isNotEmpty) {
      return;
    }
    _promptedForExercise = true;
    unawaited(_addExercise(context, ref));
  }

  @override
  Widget build(BuildContext context) {
    final RestTimerState rest = ref.watch(restTimerProvider);
    final DateTime now = ref.read(restTimerProvider.notifier).clock();
    final bool showRest =
        rest.isRunningFor(session.id, now) ||
        rest.endFlashActiveFor(session.id, now);
    String? restExerciseName;
    if (showRest) {
      final String? exerciseId = rest.exerciseId ?? rest.endFlashExerciseId;
      for (final WorkoutExercise exercise in session.exercises) {
        if (exercise.id == exerciseId) {
          restExerciseName = exercise.name;
          break;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          session.isFinished
              ? AppStrings.workoutFinished
              : session.isTimerRunning
              ? AppStrings.workoutInProgress
              : AppStrings.workoutPreparing,
        ),
        actions: <Widget>[
          if (!session.isFinished)
            TextButton(
              key: const Key('btn_minimize_session'),
              onPressed: () {
                final NavigatorState navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text(AppStrings.minimizeSession),
            ),
          IconButton(
            key: const Key('btn_delete_workout'),
            tooltip: AppStrings.deleteWorkout,
            onPressed: () {
              unawaited(_deleteAfterConfirm(context, ref));
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SessionSummaryBar(session: session),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: <Widget>[
                for (final WorkoutExercise exercise
                    in session.exercises) ...<Widget>[
                  _ExerciseCard(
                    session: session,
                    exercise: exercise,
                    focusedSetId: _focusedSetId,
                    onSetChecked: (int index) {
                      setState(() {
                        _focusedSetId = nextIncompleteSetId(
                          sets: exercise.sets,
                          completedIndex: index,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (!session.isFinished)
                  OutlinedButton.icon(
                    key: const Key('btn_add_exercise'),
                    onPressed: () {
                      unawaited(_addExercise(context, ref));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addExercise),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: AppMotion.restCollapse,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: showRest && !session.isFinished
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: RestTimerBar(
                      sessionId: session.id,
                      exerciseName: restExerciseName,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (!session.isFinished)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('btn_finish_workout'),
                    onPressed: () {
                      unawaited(_finishAfterConfirm(context, ref));
                    },
                    child: const Text(AppStrings.finishThisSession),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _finishAfterConfirm(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const Key('dialog_finish_session'),
          title: const Text(AppStrings.finishSessionConfirmTitle),
          content: const Text(
            AppStrings.finishSessionConfirmBody,
            key: Key('finish_session_confirm_body'),
          ),
          actions: <Widget>[
            TextButton(
              key: const Key('btn_keep_logging_sets'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.keepLoggingSets),
            ),
            TextButton(
              key: const Key('btn_confirm_finish'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.finishSessionConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final DateTime now = ref.read(restTimerProvider.notifier).clock();
    final SessionDoneSummary summary = sessionDoneSummary(
      session: session,
      now: now,
      rest: ref.read(restTimerProvider).restTotalFor(session.id, now),
    );
    final String sessionId = session.id;
    final NavigatorState navigator = Navigator.of(context);
    await ref.read(workoutSessionsProvider.notifier).finish(sessionId);
    ref.read(restTimerProvider.notifier).clearSession(sessionId);
    if (!context.mounted) {
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: SessionRoutes.doneNameFor(sessionId)),
        builder: (BuildContext context) {
          return SessionFinishSummaryPage(summary: summary);
        },
      ),
    );
  }

  Future<void> _deleteAfterConfirm(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const Key('dialog_delete_session'),
          title: const Text(AppStrings.deleteSessionTitle),
          content: const Text(AppStrings.deleteSessionBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              key: const Key('btn_confirm_delete'),
              style: TextButton.styleFrom(
                foregroundColor: CurveColors.of(dialogContext).error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.deleteSessionAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    ref.read(restTimerProvider.notifier).clearSession(session.id);
    await ref.read(workoutSessionsProvider.notifier).delete(session.id);
    navigator.pop();
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final CatalogExercise? picked = await Navigator.of(context)
        .push<CatalogExercise>(
          MaterialPageRoute<CatalogExercise>(
            builder: (_) => const ExerciseLibraryPage(pickMode: true),
          ),
        );
    if (picked == null || picked.nameZh.isEmpty) {
      return;
    }
    final WorkoutSet? history = await ref
        .read(workoutRepositoryProvider)
        .lastCompletedSet(
          exerciseName: picked.nameZh,
          exceptSessionId: session.id,
        );
    final WorkoutExercise created = exerciseSeededFromHistory(
      name: picked.nameZh,
      catalogId: picked.id.isEmpty ? null : picked.id,
      lastCompleted: history,
    );
    await ref.read(workoutSessionsProvider.notifier).edit(session.id, (
      WorkoutSession current,
    ) {
      return current.copyWith(
        exercises: <WorkoutExercise>[...current.exercises, created],
      );
    });
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  const _ExerciseCard({
    required this.session,
    required this.exercise,
    required this.focusedSetId,
    required this.onSetChecked,
  });

  final WorkoutSession session;
  final WorkoutExercise exercise;
  final String? focusedSetId;
  final ValueChanged<int> onSetChecked;

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  late Future<List<WorkoutSet?>> _previousSets;

  WorkoutSession get session => widget.session;
  WorkoutExercise get exercise => widget.exercise;

  @override
  void initState() {
    super.initState();
    _previousSets = _loadPrevious();
  }

  @override
  void didUpdateWidget(_ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.name != exercise.name ||
        oldWidget.session.id != session.id) {
      _previousSets = _loadPrevious();
    }
  }

  Future<List<WorkoutSet?>> _loadPrevious() {
    return ref
        .read(workoutRepositoryProvider)
        .previousSetsByIndex(
          exerciseName: exercise.name,
          exceptSessionId: session.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final CatalogExercise? catalog = ExerciseCatalog.byId(exercise.catalogId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (catalog != null)
                SizedBox(
                  width: AppLayout.lottieThumb,
                  height: AppLayout.lottieThumb,
                  child: Lottie.asset(
                    catalog.lottieAsset,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              if (catalog != null) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (catalog != null)
                      Text(
                        catalog.pattern.labelZh,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const SessionSetHeader(),
          const SizedBox(height: AppSpacing.xs),
          FutureBuilder<List<WorkoutSet?>>(
            future: _previousSets,
            builder:
                (BuildContext context, AsyncSnapshot<List<WorkoutSet?>> snap) {
                  final List<WorkoutSet?> previousSets =
                      snap.data ?? const <WorkoutSet?>[];
                  return Column(
                    children: <Widget>[
                      for (int i = 0; i < exercise.sets.length; i++)
                        _setRow(
                          index: i,
                          previous: i < previousSets.length
                              ? previousSets[i]
                              : null,
                        ),
                    ],
                  );
                },
          ),
          if (!session.isFinished)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('btn_add_set'),
                onPressed: () {
                  unawaited(_addSet(ref));
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(AppStrings.addSet),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  SessionSetRow _setRow({required int index, required WorkoutSet? previous}) {
    final WorkoutSet set = exercise.sets[index];
    return SessionSetRow(
      key: ValueKey<String>(set.id),
      index: index,
      set: set,
      previous: previous,
      focused: widget.focusedSetId == set.id,
      interactive: !session.isFinished,
      onWeightChanged: (double value) {
        unawaited(
          _patchFields(
            set.id,
            (WorkoutSet current) => current.copyWith(weightKg: value),
          ),
        );
      },
      onRepsChanged: (int value) {
        unawaited(
          _patchFields(
            set.id,
            (WorkoutSet current) => current.copyWith(reps: value),
          ),
        );
      },
      onApplyPrevious: previous == null
          ? null
          : () {
              final double weightKg = previous.weightKg;
              final int reps = previous.reps;
              unawaited(
                _patchFields(
                  set.id,
                  (WorkoutSet current) =>
                      current.copyWith(weightKg: weightKg, reps: reps),
                ),
              );
            },
      onToggleCompleted: () {
        final bool markCompleted = !set.completed;
        unawaited(
          _patchFields(
            set.id,
            (WorkoutSet current) => current.copyWith(completed: markCompleted),
          ),
        );
        if (markCompleted && !session.isFinished) {
          ref
              .read(restTimerProvider.notifier)
              .restart(
                sessionId: session.id,
                exerciseId: exercise.id,
                setId: set.id,
              );
          widget.onSetChecked(index);
        }
      },
    );
  }

  Future<void> _addSet(WidgetRef ref) async {
    final WorkoutSet? history = await ref
        .read(workoutRepositoryProvider)
        .lastCompletedSet(
          exerciseName: exercise.name,
          exceptSessionId: session.id,
        );
    final String exerciseId = exercise.id;
    await ref.read(workoutSessionsProvider.notifier).edit(session.id, (
      WorkoutSession current,
    ) {
      return current.copyWith(
        exercises: current.exercises
            .map((WorkoutExercise item) {
              if (item.id != exerciseId) {
                return item;
              }
              final WorkoutSet next = nextSetTemplate(
                existingSets: item.sets,
                lastCompleted: history,
              );
              return item.copyWith(sets: <WorkoutSet>[...item.sets, next]);
            })
            .toList(growable: false),
      );
    });
  }

  /// Edits one set on the session currently stored, so a slower tap cannot
  /// overwrite a completion that already landed.
  Future<void> _patchFields(
    String setId,
    WorkoutSet Function(WorkoutSet current) update,
  ) {
    final String exerciseId = exercise.id;
    return ref.read(workoutSessionsProvider.notifier).edit(session.id, (
      WorkoutSession current,
    ) {
      return current.copyWith(
        exercises: current.exercises
            .map((WorkoutExercise item) {
              if (item.id != exerciseId) {
                return item;
              }
              return item.copyWith(
                sets: item.sets
                    .map(
                      (WorkoutSet set) => set.id == setId ? update(set) : set,
                    )
                    .toList(growable: false),
              );
            })
            .toList(growable: false),
      );
    });
  }
}
