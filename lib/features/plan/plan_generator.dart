import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/onboarding/models/onboarding_choices.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_adjustments.dart';
import 'package:curvefree/features/plan/plan_constants.dart';

/// Transparent rule engine: split by frequency, swaps by equipment, sets by goal.
///
/// Experience, body size, activity, and muscle preference change the saved
/// sets. Period recovery is date-based: pass [cycle] to preview a day, or call
/// [adjustForPeriod] when the plan is read so the window is not frozen.
abstract final class PlanGenerator {
  static TrainingPlan generate({
    required TrainingGoal goal,
    required int daysPerWeek,
    required EquipmentProfile equipment,
    BiologicalSex? sex,
    int? heightCm,
    double? weightKg,
    TrainingExperience? experience,
    List<TrainingPreference> preferences = const <TrainingPreference>[],
    DailyActivity? activity,
    CycleProfile? cycle,
    DateTime? onDate,
  }) {
    final int days = daysPerWeek
        .clamp(PlanLimits.minDaysPerWeek, PlanLimits.maxDaysPerWeek)
        .toInt();
    final List<int> weekdays = _weekdaysFor(days);
    final List<String> slots = _slotTitles(days);
    final List<PlannedSession> built = <PlannedSession>[];
    for (int i = 0; i < days; i++) {
      built.add(
        PlannedSession(
          weekday: weekdays[i],
          title: slots[i],
          items: _itemsForSlot(slots[i], goal, equipment),
        ),
      );
    }
    final VolumeAdjustment volume = VolumeAdjustment.resolve(
      heightCm: heightCm,
      weightKg: weightKg,
      experience: experience,
      activity: activity,
    );
    final Set<TrainingPreference> bias = preferenceBias(preferences);
    final List<PlannedSession> covered = _coverPreferences(
      sessions: built,
      bias: bias,
      equipment: equipment,
      goal: goal,
    );
    final List<PlannedSession> sessions = _applyVolume(
      sessions: covered,
      volume: volume,
      bias: bias,
    );
    final TrainingPlan base = TrainingPlan(
      goal: goal,
      daysPerWeek: days,
      equipment: equipment,
      sessions: sessions,
    );
    if (cycle == null) {
      return base;
    }
    return adjustForPeriod(
      base,
      sex: sex,
      cycle: cycle,
      onDate: onDate ?? DateTime.now(),
    );
  }

  /// Drops one set per movement while [onDate] falls in a period window.
  /// No-op when sex is not female or the stored dates cannot place the day.
  static TrainingPlan adjustForPeriod(
    TrainingPlan plan, {
    required BiologicalSex? sex,
    required CycleProfile? cycle,
    required DateTime onDate,
  }) {
    if (plan.periodAdjusted) {
      return plan;
    }
    if (!isInPeriodWindow(sex: sex, cycle: cycle, onDate: onDate)) {
      return plan;
    }
    var changed = false;
    final List<PlannedSession> sessions = <PlannedSession>[];
    for (final PlannedSession session in plan.sessions) {
      final List<PlannedItem> items = <PlannedItem>[];
      for (final PlannedItem item in session.items) {
        final int sets = clampPlanSets(
          item.sets + PlanVolumeLimits.periodSetDelta,
        );
        if (sets != item.sets) {
          changed = true;
        }
        items.add(item.copyWith(sets: sets));
      }
      sessions.add(
        PlannedSession(
          weekday: session.weekday,
          title: session.title,
          items: items,
        ),
      );
    }
    if (!changed) {
      return plan;
    }
    return TrainingPlan(
      goal: plan.goal,
      daysPerWeek: plan.daysPerWeek,
      equipment: plan.equipment,
      sessions: sessions,
      periodAdjusted: true,
    );
  }

  static List<int> _weekdaysFor(int days) {
    switch (days) {
      case 2:
        return const <int>[2, 5];
      case 3:
        return const <int>[1, 3, 5];
      case 4:
        return const <int>[1, 2, 4, 5];
      case 5:
        return const <int>[1, 2, 3, 4, 5];
      case 6:
        return const <int>[1, 2, 3, 4, 5, 6];
      default:
        return const <int>[1, 3, 5];
    }
  }

  static List<String> _slotTitles(int days) {
    switch (days) {
      case 2:
        return const <String>['全身 A', '全身 B'];
      case 3:
        return const <String>['推', '拉', '腿'];
      case 4:
        return const <String>['上肢 A', '下肢 A', '上肢 B', '下肢 B'];
      case 5:
        return const <String>['推', '拉', '腿', '推', '拉'];
      case 6:
        return const <String>['推', '拉', '腿', '推', '拉', '腿'];
      default:
        return const <String>['推', '拉', '腿'];
    }
  }

  static List<PlannedItem> _itemsForSlot(
    String slot,
    TrainingGoal goal,
    EquipmentProfile equipment,
  ) {
    final ids = _catalogIds(slot, equipment);
    return [
      for (int i = 0; i < ids.length; i++) _item(ids[i], goal, isMain: i == 0),
    ];
  }

  static PlannedItem _item(
    String catalogId,
    TrainingGoal goal, {
    required bool isMain,
  }) {
    final catalog = ExerciseCatalog.byId(catalogId);
    final name = catalog?.nameZh ?? catalogId;
    switch (goal) {
      case TrainingGoal.strength:
        return PlannedItem(
          catalogId: catalogId,
          nameZh: name,
          sets: isMain
              ? SetPrescriptions.strengthMainSets
              : SetPrescriptions.strengthAccSets,
          reps: isMain
              ? SetPrescriptions.strengthMainReps
              : SetPrescriptions.strengthAccReps,
        );
      case TrainingGoal.fatLoss:
        return PlannedItem(
          catalogId: catalogId,
          nameZh: name,
          sets: SetPrescriptions.fatLossSets,
          reps: SetPrescriptions.fatLossReps,
        );
      case TrainingGoal.hypertrophy:
        return PlannedItem(
          catalogId: catalogId,
          nameZh: name,
          sets: SetPrescriptions.hypertrophySets,
          reps: SetPrescriptions.hypertrophyReps,
        );
    }
  }

  static List<String> _catalogIds(String slot, EquipmentProfile equipment) {
    switch (equipment) {
      case EquipmentProfile.dumbbells:
        return _dumbbellIds(slot);
      case EquipmentProfile.bodyweight:
        return _bodyweightIds(slot);
      case EquipmentProfile.fullGym:
        return _gymIds(slot);
    }
  }

  static List<String> _gymIds(String slot) {
    if (slot.startsWith('推') || slot == '上肢 A') {
      return const <String>['ex_barbell_bench', 'ex_overhead_press', 'ex_dip'];
    }
    if (slot.startsWith('拉') || slot == '上肢 B') {
      return const <String>[
        'ex_barbell_row',
        'ex_lat_pulldown',
        'ex_face_pull',
      ];
    }
    if (slot == '全身 A') {
      return const <String>[
        'ex_barbell_bench',
        'ex_barbell_row',
        'ex_back_squat',
      ];
    }
    if (slot == '全身 B') {
      return const <String>['ex_overhead_press', 'ex_pullup', 'ex_deadlift'];
    }
    if (slot == '下肢 B') {
      return const <String>['ex_deadlift', 'ex_front_squat', 'ex_plank'];
    }
    return const <String>['ex_back_squat', 'ex_rdl', 'ex_plank'];
  }

  static List<String> _dumbbellIds(String slot) {
    if (slot.startsWith('推') || slot == '上肢 A') {
      return const <String>['ex_db_press', 'ex_overhead_press', 'ex_dip'];
    }
    if (slot.startsWith('拉') || slot == '上肢 B') {
      return const <String>['ex_db_row', 'ex_pullup', 'ex_face_pull'];
    }
    if (slot == '全身 A') {
      return const <String>['ex_db_press', 'ex_db_row', 'ex_lunge'];
    }
    if (slot == '全身 B') {
      return const <String>['ex_overhead_press', 'ex_pullup', 'ex_rdl'];
    }
    return const <String>['ex_lunge', 'ex_rdl', 'ex_plank'];
  }

  static List<String> _bodyweightIds(String slot) {
    if (slot.startsWith('推') || slot == '上肢 A' || slot == '全身 A') {
      return const <String>['ex_dip', 'ex_plank'];
    }
    if (slot.startsWith('拉') || slot == '上肢 B' || slot == '全身 B') {
      return const <String>['ex_pullup', 'ex_plank'];
    }
    return const <String>['ex_lunge', 'ex_hip_thrust', 'ex_plank'];
  }

  static List<PlannedSession> _applyVolume({
    required List<PlannedSession> sessions,
    required VolumeAdjustment volume,
    required Set<TrainingPreference> bias,
  }) {
    if (volume.sharedDelta == 0 && bias.isEmpty) {
      return sessions;
    }
    return <PlannedSession>[
      for (final PlannedSession session in sessions)
        PlannedSession(
          weekday: session.weekday,
          title: session.title,
          items: <PlannedItem>[
            for (final PlannedItem item in session.items)
              item.copyWith(
                sets: volume.setsFor(
                  item.sets,
                  preferred: _itemPreferred(item.catalogId, bias),
                ),
              ),
          ],
        ),
    ];
  }

  static bool _itemPreferred(String catalogId, Set<TrainingPreference> bias) {
    if (bias.isEmpty) {
      return false;
    }
    final TrainingPreference? preference = preferenceForCatalog(catalogId);
    return preference != null && bias.contains(preference);
  }

  static List<PlannedSession> _coverPreferences({
    required List<PlannedSession> sessions,
    required Set<TrainingPreference> bias,
    required EquipmentProfile equipment,
    required TrainingGoal goal,
  }) {
    if (bias.isEmpty || sessions.isEmpty) {
      return sessions;
    }
    final List<String> extraIds = missingPreferenceCatalogIds(
      presentCatalogIds: <String>[
        for (final PlannedSession session in sessions)
          for (final PlannedItem item in session.items) item.catalogId,
      ],
      preferences: bias.toList(growable: false),
      equipment: equipment,
    );
    final List<PlannedItem> extras = <PlannedItem>[
      for (final String catalogId in extraIds)
        _item(catalogId, goal, isMain: false),
    ];
    if (extras.isEmpty) {
      return sessions;
    }
    final PlannedSession first = sessions.first;
    return <PlannedSession>[
      PlannedSession(
        weekday: first.weekday,
        title: first.title,
        items: <PlannedItem>[...first.items, ...extras],
      ),
      ...sessions.skip(1),
    ];
  }
}
