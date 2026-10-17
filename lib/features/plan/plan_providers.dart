import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
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
    final LocalStoreSnapshot? snapshot = ref
        .read(localStoreSnapshotProvider)
        .valueOrNull;
    if (snapshot == null) {
      return null;
    }
    return _withPeriod(snapshot, _storedPlan(snapshot));
  }

  Future<void> generate({
    required TrainingGoal goal,
    required int daysPerWeek,
    required EquipmentProfile equipment,
  }) async {
    final LocalStoreSnapshot? snapshot = ref
        .read(localStoreSnapshotProvider)
        .valueOrNull;
    final Map<String, Object?> settings =
        snapshot?.settings ?? const <String, Object?>{};
    final UserProfile profile = UserProfile.fromSettings(settings);
    final TrainingPlan base = PlanGenerator.generate(
      goal: goal,
      daysPerWeek: daysPerWeek,
      equipment: equipment,
      sex: profile.sex,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      experience: profile.experience,
      preferences: profile.preferences,
      activity: profile.activity,
    );
    await ref
        .read(localStoreSnapshotProvider.notifier)
        .putSetting(PlanJsonKeys.settingsKey, base.toJson());
    final LocalStoreSnapshot? refreshed = ref
        .read(localStoreSnapshotProvider)
        .valueOrNull;
    state = _withPeriod(refreshed, base);
  }

  TrainingPlan? _storedPlan(LocalStoreSnapshot snapshot) {
    final Object? raw = snapshot.settings[PlanJsonKeys.settingsKey];
    if (raw is! Map) {
      return null;
    }
    return TrainingPlan.fromJson(
      raw.map((Object? key, Object? value) => MapEntry(key.toString(), value)),
    );
  }

  TrainingPlan? _withPeriod(LocalStoreSnapshot? snapshot, TrainingPlan? plan) {
    if (snapshot == null || plan == null) {
      return plan;
    }
    final UserProfile profile = UserProfile.fromSettings(snapshot.settings);
    final CycleProfile cycle = CycleProfile.fromSettings(snapshot.settings);
    return PlanGenerator.adjustForPeriod(
      plan,
      sex: profile.sex,
      cycle: cycle,
      onDate: DateTime.now(),
    );
  }
}
