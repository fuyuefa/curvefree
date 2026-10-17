import 'package:curvefree/features/exercises/models/catalog_exercise.dart';

/// Built-in strength catalog. Names are common gym terms, not scraped UI copy.
abstract final class ExerciseCatalog {
  static const List<CatalogExercise> baseline = <CatalogExercise>[
    CatalogExercise(
      id: 'ex_barbell_bench',
      nameZh: '杠铃卧推',
      pattern: MovementPattern.push,
      equipment: EquipmentKind.bench,
    ),
    CatalogExercise(
      id: 'ex_incline_bench',
      nameZh: '上斜卧推',
      pattern: MovementPattern.push,
      equipment: EquipmentKind.bench,
    ),
    CatalogExercise(
      id: 'ex_overhead_press',
      nameZh: '杠铃推举',
      pattern: MovementPattern.push,
      equipment: EquipmentKind.barbell,
    ),
    CatalogExercise(
      id: 'ex_dip',
      nameZh: '双杠臂屈伸',
      pattern: MovementPattern.push,
      equipment: EquipmentKind.bodyweight,
    ),
    CatalogExercise(
      id: 'ex_db_press',
      nameZh: '哑铃卧推',
      pattern: MovementPattern.push,
      equipment: EquipmentKind.dumbbell,
    ),
    CatalogExercise(
      id: 'ex_barbell_row',
      nameZh: '杠铃划船',
      pattern: MovementPattern.pull,
      equipment: EquipmentKind.barbell,
    ),
    CatalogExercise(
      id: 'ex_lat_pulldown',
      nameZh: '高位下拉',
      pattern: MovementPattern.pull,
      equipment: EquipmentKind.machine,
    ),
    CatalogExercise(
      id: 'ex_pullup',
      nameZh: '引体向上',
      pattern: MovementPattern.pull,
      equipment: EquipmentKind.bodyweight,
    ),
    CatalogExercise(
      id: 'ex_db_row',
      nameZh: '哑铃划船',
      pattern: MovementPattern.pull,
      equipment: EquipmentKind.dumbbell,
    ),
    CatalogExercise(
      id: 'ex_face_pull',
      nameZh: '面拉',
      pattern: MovementPattern.pull,
      equipment: EquipmentKind.machine,
    ),
    CatalogExercise(
      id: 'ex_back_squat',
      nameZh: '杠铃深蹲',
      pattern: MovementPattern.squat,
      equipment: EquipmentKind.barbell,
    ),
    CatalogExercise(
      id: 'ex_front_squat',
      nameZh: '前蹲',
      pattern: MovementPattern.squat,
      equipment: EquipmentKind.barbell,
    ),
    CatalogExercise(
      id: 'ex_leg_press',
      nameZh: '腿举',
      pattern: MovementPattern.squat,
      equipment: EquipmentKind.machine,
    ),
    CatalogExercise(
      id: 'ex_lunge',
      nameZh: '弓步蹲',
      pattern: MovementPattern.squat,
      equipment: EquipmentKind.dumbbell,
    ),
    CatalogExercise(
      id: 'ex_deadlift',
      nameZh: '硬拉',
      pattern: MovementPattern.hinge,
      equipment: EquipmentKind.barbell,
    ),
    CatalogExercise(
      id: 'ex_rdl',
      nameZh: '罗马尼亚硬拉',
      pattern: MovementPattern.hinge,
      equipment: EquipmentKind.barbell,
    ),
    CatalogExercise(
      id: 'ex_hip_thrust',
      nameZh: '臀桥',
      pattern: MovementPattern.hinge,
      equipment: EquipmentKind.bench,
    ),
    CatalogExercise(
      id: 'ex_plank',
      nameZh: '平板支撑',
      pattern: MovementPattern.core,
      equipment: EquipmentKind.bodyweight,
    ),
  ];

  static List<CatalogExercise> _overlayExercises = const <CatalogExercise>[];
  static Map<String, List<String>> _overlayBodyParts =
      const <String, List<String>>{};
  static List<CatalogExercise>? _mergedExercises;
  static Map<String, List<String>>? _mergedBodyParts;

  /// Baseline plus the active content pack. Same ids in the pack replace
  /// the baseline row; new ids are appended.
  static List<CatalogExercise> get all {
    if (_overlayExercises.isEmpty) {
      return baseline;
    }
    return _mergedExercises ??= _mergeExercises();
  }

  static void applyOverlay({
    required List<CatalogExercise> exercises,
    required Map<String, List<String>> bodyParts,
  }) {
    _overlayExercises = List<CatalogExercise>.unmodifiable(exercises);
    _overlayBodyParts = Map<String, List<String>>.unmodifiable(bodyParts);
    _mergedExercises = null;
    _mergedBodyParts = null;
  }

  static void clearOverlay() {
    applyOverlay(
      exercises: const <CatalogExercise>[],
      bodyParts: const <String, List<String>>{},
    );
  }

  /// Stable body-part ids shared with onboarding prefer chips.
  static const Map<String, List<String>> baselineBodyParts =
      <String, List<String>>{
        'ex_barbell_bench': <String>['chest'],
        'ex_incline_bench': <String>['chest'],
        'ex_overhead_press': <String>['shoulders'],
        'ex_dip': <String>['chest', 'arms'],
        'ex_db_press': <String>['chest'],
        'ex_barbell_row': <String>['back'],
        'ex_lat_pulldown': <String>['back'],
        'ex_pullup': <String>['back'],
        'ex_db_row': <String>['back'],
        'ex_face_pull': <String>['shoulders'],
        'ex_back_squat': <String>['legs', 'glutes'],
        'ex_front_squat': <String>['legs'],
        'ex_leg_press': <String>['legs'],
        'ex_lunge': <String>['legs', 'glutes'],
        'ex_deadlift': <String>['back', 'legs', 'glutes'],
        'ex_rdl': <String>['legs', 'glutes'],
        'ex_hip_thrust': <String>['glutes'],
        'ex_plank': <String>['core'],
      };

  static Map<String, List<String>> get bodyPartIds {
    if (_overlayExercises.isEmpty) {
      return baselineBodyParts;
    }
    return _mergedBodyParts ??= _mergeBodyParts();
  }

  static List<CatalogExercise> _mergeExercises() {
    final Map<String, CatalogExercise> byId = <String, CatalogExercise>{
      for (final CatalogExercise item in baseline) item.id: item,
    };
    final List<CatalogExercise> appended = <CatalogExercise>[];
    for (final CatalogExercise item in _overlayExercises) {
      if (byId.containsKey(item.id)) {
        byId[item.id] = item;
      } else {
        appended.add(item);
      }
    }
    return <CatalogExercise>[
      for (final CatalogExercise item in baseline) byId[item.id]!,
      ...appended,
    ];
  }

  static Map<String, List<String>> _mergeBodyParts() {
    final Map<String, List<String>> merged = <String, List<String>>{
      ...baselineBodyParts,
    };
    for (final CatalogExercise item in _overlayExercises) {
      final List<String>? parts = _overlayBodyParts[item.id];
      if (parts != null && parts.isNotEmpty) {
        merged[item.id] = parts;
      }
    }
    return merged;
  }

  static const Map<String, String> _bodyPartLabel = <String, String>{
    'chest': '胸',
    'back': '背',
    'shoulders': '肩',
    'legs': '腿',
    'glutes': '臀',
    'arms': '手臂',
    'core': '核心',
  };

  static CatalogExercise? byId(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final CatalogExercise item in all) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  /// Id match first, then an exact Chinese name. Unknown names stay custom.
  static CatalogExercise? resolve({String? catalogId, String? nameZh}) {
    final CatalogExercise? byCatalogId = byId(catalogId);
    if (byCatalogId != null) {
      return byCatalogId;
    }
    final String name = nameZh?.trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    for (final CatalogExercise item in all) {
      if (item.nameZh == name) {
        return item;
      }
    }
    return null;
  }

  static List<CatalogExercise> search(String query) {
    final needle = query.trim();
    if (needle.isEmpty) {
      return all;
    }
    return all
        .where(
          (CatalogExercise item) =>
              item.nameZh.contains(needle) ||
              item.nameEn.toLowerCase().contains(needle.toLowerCase()) ||
              item.pattern.labelZh.contains(needle) ||
              item.equipment.labelZh.contains(needle) ||
              _labelsFor(item.id).any((String label) => label.contains(needle)),
        )
        .toList(growable: false);
  }

  static Iterable<String> _labelsFor(String id) sync* {
    final List<String>? parts = bodyPartIds[id];
    if (parts == null) {
      return;
    }
    for (final String part in parts) {
      final String? label = _bodyPartLabel[part];
      if (label != null) {
        yield label;
      }
    }
  }
}
