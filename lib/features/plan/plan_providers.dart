import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';
import 'package:curvefree/features/plan/plan_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trainingPlanProvider =
    NotifierProvider<TrainingPlanController, TrainingPlan?>(
      TrainingPlanController.new,
    );

final class TrainingPlanController extends Notifier<TrainingPlan?> {
  @override
  TrainingPlan? build() {
    ref.watch(localStoreSnapshotProvider);
    final snapshot = ref.read(localStoreSnapshotProvider).valueOrNull;
    final raw = snapshot?.settings[PlanJsonKeys.settingsKey];
    if (raw is Map) {
      return TrainingPlan.fromJson(
        raw.map(
          (Object? key, Object? value) => MapEntry(key.toString(), value),
        ),
      );
    }
    return null;
  }

  Future<void> generate({
    required TrainingGoal goal,
    required int daysPerWeek,
    required EquipmentProfile equipment,
  }) async {
    final plan = PlanGenerator.generate(
      goal: goal,
      daysPerWeek: daysPerWeek,
      equipment: equipment,
    );
    await ref
        .read(localStoreSnapshotProvider.notifier)
        .putSetting(PlanJsonKeys.settingsKey, plan.toJson());
    state = plan;
  }
}
