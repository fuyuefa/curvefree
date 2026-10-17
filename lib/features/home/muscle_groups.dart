import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/home/week_progress.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/training/models/workout_models.dart';

/// Display buckets for the today-page dots. Not a stored anatomy model.
enum MuscleGroup { chest, back, legs, shoulders, arms, core }

enum MuscleDotState { idle, planned, trained }

extension MuscleGroupLabel on MuscleGroup {
  String get labelZh {
    switch (this) {
      case MuscleGroup.chest:
        return '胸';
      case MuscleGroup.back:
        return '背';
      case MuscleGroup.legs:
        return '腿';
      case MuscleGroup.shoulders:
        return '肩';
      case MuscleGroup.arms:
        return '臂';
      case MuscleGroup.core:
        return '核心';
    }
  }
}

const Map<String, Set<MuscleGroup>> catalogMuscleGroups =
    <String, Set<MuscleGroup>>{
      'ex_barbell_bench': <MuscleGroup>{MuscleGroup.chest},
      'ex_incline_bench': <MuscleGroup>{MuscleGroup.chest},
      'ex_overhead_press': <MuscleGroup>{MuscleGroup.shoulders},
      'ex_dip': <MuscleGroup>{MuscleGroup.chest, MuscleGroup.arms},
      'ex_db_press': <MuscleGroup>{MuscleGroup.chest},
      'ex_barbell_row': <MuscleGroup>{MuscleGroup.back},
      'ex_lat_pulldown': <MuscleGroup>{MuscleGroup.back},
      'ex_pullup': <MuscleGroup>{MuscleGroup.back},
      'ex_db_row': <MuscleGroup>{MuscleGroup.back},
      'ex_face_pull': <MuscleGroup>{MuscleGroup.shoulders, MuscleGroup.back},
      'ex_back_squat': <MuscleGroup>{MuscleGroup.legs},
      'ex_front_squat': <MuscleGroup>{MuscleGroup.legs},
      'ex_leg_press': <MuscleGroup>{MuscleGroup.legs},
      'ex_lunge': <MuscleGroup>{MuscleGroup.legs},
      'ex_deadlift': <MuscleGroup>{MuscleGroup.back, MuscleGroup.legs},
      'ex_rdl': <MuscleGroup>{MuscleGroup.legs, MuscleGroup.back},
      'ex_hip_thrust': <MuscleGroup>{MuscleGroup.legs},
      'ex_plank': <MuscleGroup>{MuscleGroup.core},
    };

Set<MuscleGroup> muscleGroupsFor({String? catalogId, required String name}) {
  final Set<MuscleGroup>? mapped = catalogId == null
      ? null
      : catalogMuscleGroups[catalogId];
  if (mapped != null && mapped.isNotEmpty) {
    return mapped;
  }
  return muscleGroupsFromName(name);
}

Set<MuscleGroup> muscleGroupsFromName(String name) {
  final Set<MuscleGroup> groups = <MuscleGroup>{};
  if (name.contains('卧推') || name.contains('胸')) {
    groups.add(MuscleGroup.chest);
  }
  if (name.contains('划船') ||
      name.contains('下拉') ||
      name.contains('引体') ||
      name.contains('背')) {
    groups.add(MuscleGroup.back);
  }
  if (name.contains('蹲') ||
      name.contains('腿') ||
      name.contains('硬拉') ||
      name.contains('臀')) {
    groups.add(MuscleGroup.legs);
  }
  if (name.contains('推举') || name.contains('肩')) {
    groups.add(MuscleGroup.shoulders);
  }
  if (name.contains('臂') || name.contains('弯举')) {
    groups.add(MuscleGroup.arms);
  }
  if (name.contains('核心') || name.contains('平板') || name.contains('卷腹')) {
    groups.add(MuscleGroup.core);
  }
  return groups;
}

Set<MuscleGroup> trainedMuscleGroups({
  required List<WorkoutSession> sessions,
  required DateTime now,
}) {
  final DateTime weekStart = startOfLocalWeek(now);
  final Set<MuscleGroup> groups = <MuscleGroup>{};
  for (final WorkoutSession session in sessions) {
    if (!isInLocalWeek(session.startedAt, weekStart)) {
      continue;
    }
    for (final WorkoutExercise exercise in session.exercises) {
      final bool done = exercise.sets.any((WorkoutSet set) => set.completed);
      if (!done) {
        continue;
      }
      groups.addAll(
        muscleGroupsFor(catalogId: exercise.catalogId, name: exercise.name),
      );
    }
  }
  return groups;
}

Set<MuscleGroup> plannedMuscleGroups(PlannedSession? session) {
  if (session == null) {
    return <MuscleGroup>{};
  }
  final Set<MuscleGroup> groups = <MuscleGroup>{};
  for (final PlannedItem item in session.items) {
    groups.addAll(
      muscleGroupsFor(catalogId: item.catalogId, name: item.nameZh),
    );
  }
  return groups;
}

String muscleSectionTitle({required bool plannedForToday}) {
  if (plannedForToday) {
    return AppStrings.musclesPlannedToday;
  }
  return AppStrings.muscleGroupsTitle;
}

MuscleDotState muscleDotState({
  required MuscleGroup group,
  required Set<MuscleGroup> trained,
  required Set<MuscleGroup> planned,
}) {
  if (trained.contains(group)) {
    return MuscleDotState.trained;
  }
  if (planned.contains(group)) {
    return MuscleDotState.planned;
  }
  return MuscleDotState.idle;
}
