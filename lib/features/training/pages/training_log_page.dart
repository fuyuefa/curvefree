import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/plan/pages/plan_page.dart';
import 'package:curvefree/features/exercises/pages/exercise_library_page.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/session_routes.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:curvefree/features/training/widgets/workout_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrainingLogPage extends ConsumerWidget {
  const TrainingLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSessions = ref.watch(workoutSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.trainingLogTitle),
        actions: [
          IconButton(
            key: const Key('btn_open_plan'),
            tooltip: AppStrings.trainingPlanTitle,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const PlanPage()));
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            key: const Key('btn_open_exercise_library'),
            tooltip: AppStrings.exerciseLibrary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExerciseLibraryPage(),
                ),
              );
            },
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('btn_start_workout'),
        onPressed: () => _start(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.startWorkout),
      ),
      body: asyncSessions.when(
        loading: () => const Center(child: Text(AppStrings.readingWorkout)),
        error: (Object error, StackTrace stack) =>
            Center(child: Text('读取失败：$error')),
        data: (List<WorkoutSession> sessions) {
          if (sessions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(AppStrings.emptyWorkouts),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              96,
            ),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final session = sessions[index];
              return WorkoutListTile(
                session: session,
                onTap: () {
                  Navigator.of(context).push(sessionPageRoute(session.id));
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final session = await ref
        .read(workoutSessionsProvider.notifier)
        .startSession();
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(sessionPageRoute(session.id));
  }
}
