import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:curvefree/features/training/resume_copy.dart';
import 'package:curvefree/features/training/session_label.dart';
import 'package:curvefree/features/training/training_json_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('elapsed phrase floors to minutes', () {
    expect(
      ResumeCopy.elapsedPhrase(Duration.zero),
      AppStrings.elapsedUnderOneMinute,
    );
    expect(
      ResumeCopy.elapsedPhrase(const Duration(seconds: 59)),
      AppStrings.elapsedUnderOneMinute,
    );
    expect(
      ResumeCopy.elapsedPhrase(const Duration(seconds: -5)),
      AppStrings.elapsedUnderOneMinute,
    );
    expect(
      ResumeCopy.elapsedPhrase(const Duration(minutes: 32, seconds: 10)),
      '已经 32 分钟了',
    );
    expect(ResumeCopy.elapsedPhrase(const Duration(hours: 1)), '已经 1 小时了');
    expect(
      ResumeCopy.elapsedPhrase(const Duration(hours: 1, minutes: 12)),
      '已经 1 小时 12 分钟了',
    );
  });

  test('resume card copy uses the session name and approximate volume', () {
    expect(
      ResumeCopy.cardTitle(
        name: '推肩日',
        elapsed: const Duration(minutes: 32, seconds: 10),
      ),
      '推肩日 · 已经 32 分钟了',
    );
    expect(
      ResumeCopy.cardTitle(name: '自由训练', elapsed: null),
      '自由训练 · ${AppStrings.workoutPreparing}',
    );
    expect(
      ResumeCopy.cardSubtitle(completedSets: 6, volumeKg: 320.4),
      '已记 6 组 · 容量约 320 kg',
    );
  });

  test('session name prefers the stored plan title', () {
    expect(
      sessionDisplayName(WorkoutSession.create()),
      AppStrings.freeWorkoutName,
    );
    expect(sessionDisplayName(WorkoutSession.create(title: ' 推肩日 ')), '推肩日');
    final WorkoutSession legacy = WorkoutSession.create().copyWith(
      exercises: const <WorkoutExercise>[
        WorkoutExercise(
          id: 'e1',
          name: '杠铃卧推',
          sets: <WorkoutSet>[
            WorkoutSet(id: 's1', weightKg: 40, reps: 8, completed: false),
          ],
        ),
      ],
    );
    expect(sessionDisplayName(legacy), '杠铃卧推');
  });

  test('session title round-trips and stays off empty documents', () {
    final WorkoutSession named = WorkoutSession.create(title: '推肩日');
    expect(WorkoutSession.fromJson(named.toJson()).title, '推肩日');

    final WorkoutSession blank = WorkoutSession.create();
    expect(blank.toJson().containsKey(TrainingJsonKeys.title), isFalse);
    expect(WorkoutSession.fromJson(blank.toJson()).title, isEmpty);
    expect(
      WorkoutSession.fromJson(<String, Object?>{
        TrainingJsonKeys.id: 'w-old',
        TrainingJsonKeys.startedAt: '2026-10-01T08:00:00.000',
        TrainingJsonKeys.notes: '',
        TrainingJsonKeys.exercises: <Object?>[],
      }).title,
      isEmpty,
    );
  });
}
