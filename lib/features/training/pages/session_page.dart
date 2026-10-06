import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:curvefree/features/exercises/pages/exercise_library_page.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/widgets/numeric_keypad_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class SessionPage extends ConsumerWidget {
  const SessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSessions = ref.watch(workoutSessionsProvider);
    return asyncSessions.when(
      loading: () => const Scaffold(body: Center(child: Text('正在读取训练课…'))),
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
            body: const Center(child: Text('训练课不存在')),
          );
        }
        return _SessionScaffold(session: session);
      },
    );
  }
}

class _SessionScaffold extends ConsumerWidget {
  const _SessionScaffold({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = session.volumeKg.toStringAsFixed(0);
    return Scaffold(
      appBar: AppBar(
        title: Text(session.isFinished ? '训练课' : '进行中'),
        actions: [
          TextButton(
            key: const Key('btn_finish_workout'),
            onPressed: session.isFinished
                ? null
                : () {
                    ref.read(workoutSessionsProvider.notifier).finish(session);
                  },
            child: const Text(AppStrings.finishWorkout),
          ),
          IconButton(
            tooltip: AppStrings.deleteWorkout,
            onPressed: () async {
              await ref
                  .read(workoutSessionsProvider.notifier)
                  .delete(session.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Text(
            '${AppStrings.volumeLabel} $volume kg · ${session.completedSetCount} 组',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final WorkoutExercise exercise in session.exercises) ...[
            _ExerciseCard(session: session, exercise: exercise),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            key: const Key('btn_add_exercise'),
            onPressed: () => _addExercise(context, ref),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addExercise),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final picked = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute<CatalogExercise>(
        builder: (_) => const ExerciseLibraryPage(pickMode: true),
      ),
    );
    if (picked == null || picked.nameZh.isEmpty) {
      return;
    }
    final catalogId = picked.id.isEmpty ? null : picked.id;
    final nextExercises = <WorkoutExercise>[
      ...session.exercises,
      WorkoutExercise.create(picked.nameZh, catalogId: catalogId),
    ];
    await ref
        .read(workoutSessionsProvider.notifier)
        .save(session.copyWith(exercises: nextExercises));
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.session, required this.exercise});

  final WorkoutSession session;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ExerciseCatalog.byId(exercise.catalogId) != null)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Lottie.asset(
                    ExerciseCatalog.byId(exercise.catalogId)!.lottieAsset,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FutureBuilder<WorkoutSet?>(
            future: ref
                .read(workoutRepositoryProvider)
                .lastCompletedSet(
                  exerciseName: exercise.name,
                  exceptSessionId: session.id,
                ),
            builder: (BuildContext context, AsyncSnapshot<WorkoutSet?> snap) {
              final hint = snap.data;
              if (hint == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '${AppStrings.lastHintPrefix} ${hint.weightKg} kg × ${hint.reps}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          ),
          const Row(
            children: [
              SizedBox(width: 36, child: Text(AppStrings.setColumn)),
              Expanded(child: Text(AppStrings.weightColumn)),
              Expanded(child: Text(AppStrings.repsColumn)),
              SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (int i = 0; i < exercise.sets.length; i++)
            _SetRow(
              index: i,
              session: session,
              exercise: exercise,
              set: exercise.sets[i],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                final last = exercise.sets.isEmpty ? null : exercise.sets.last;
                final nextSet = WorkoutSet.create(
                  weightKg: last?.weightKg ?? TrainingDefaults.defaultWeightKg,
                  reps: last?.reps ?? TrainingDefaults.defaultReps,
                );
                _replaceExercise(
                  ref,
                  exercise.copyWith(
                    sets: <WorkoutSet>[...exercise.sets, nextSet],
                  ),
                );
              },
              child: const Text(AppStrings.addSet),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _replaceExercise(WidgetRef ref, WorkoutExercise nextExercise) {
    final next = session.exercises
        .map(
          (WorkoutExercise item) =>
              item.id == nextExercise.id ? nextExercise : item,
        )
        .toList(growable: false);
    return ref
        .read(workoutSessionsProvider.notifier)
        .save(session.copyWith(exercises: next));
  }
}

class _SetRow extends ConsumerWidget {
  const _SetRow({
    required this.index,
    required this.session,
    required this.exercise,
    required this.set,
  });

  final int index;
  final WorkoutSession session;
  final WorkoutExercise exercise;
  final WorkoutSet set;

  Future<void> _patch(WidgetRef ref, WorkoutSet nextSet) {
    final nextSets = exercise.sets
        .map((WorkoutSet item) => item.id == nextSet.id ? nextSet : item)
        .toList(growable: false);
    final nextExercise = exercise.copyWith(sets: nextSets);
    final next = session.exercises
        .map(
          (WorkoutExercise item) =>
              item.id == nextExercise.id ? nextExercise : item,
        )
        .toList(growable: false);
    return ref
        .read(workoutSessionsProvider.notifier)
        .save(session.copyWith(exercises: next));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('${index + 1}')),
          Expanded(
            child: _ValueChip(
              label: set.weightKg.toStringAsFixed(
                set.weightKg == set.weightKg.roundToDouble()
                    ? 0
                    : TrainingDefaults.weightFractionDigits,
              ),
              onTap: () async {
                final value = await NumericKeypadSheet.show(
                  context: context,
                  kind: NumericFieldKind.weightKg,
                  initial: set.weightKg,
                  title: AppStrings.weightColumn,
                );
                if (value != null) {
                  await _patch(ref, set.copyWith(weightKg: value));
                }
              },
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _ValueChip(
              label: '${set.reps}',
              onTap: () async {
                final value = await NumericKeypadSheet.show(
                  context: context,
                  kind: NumericFieldKind.reps,
                  initial: set.reps.toDouble(),
                  title: AppStrings.repsColumn,
                );
                if (value != null) {
                  await _patch(ref, set.copyWith(reps: value.round()));
                }
              },
            ),
          ),
          SizedBox(
            width: 48,
            child: Checkbox(
              value: set.completed,
              onChanged: (bool? checked) {
                _patch(ref, set.copyWith(completed: checked ?? false));
              },
            ),
          ),
        ],
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
    return Material(
      color: const Color(AppColors.surfaceHigh),
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
