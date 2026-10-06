import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/plan/models/training_plan.dart';
import 'package:curvefree/features/plan/plan_constants.dart';

/// Transparent rule engine: split by frequency, swaps by equipment, sets by goal.
abstract final class PlanGenerator {
  static TrainingPlan generate({
    required TrainingGoal goal,
    required int daysPerWeek,
    required EquipmentProfile equipment,
  }) {
    final days = daysPerWeek.clamp(
      PlanLimits.minDaysPerWeek,
      PlanLimits.maxDaysPerWeek,
    );
    final weekdays = _weekdaysFor(days);
    final slots = _slotTitles(days);
    final sessions = <PlannedSession>[];
    for (int i = 0; i < days; i++) {
      sessions.add(
        PlannedSession(
          weekday: weekdays[i],
          title: slots[i],
          items: _itemsForSlot(slots[i], goal, equipment),
        ),
      );
    }
    return TrainingPlan(
      goal: goal,
      daysPerWeek: days,
      equipment: equipment,
      sessions: sessions,
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
}
