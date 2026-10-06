abstract final class LottieAssets {
  static const String press = 'assets/lottie/press.json';
  static const String squat = 'assets/lottie/squat.json';
  static const String row = 'assets/lottie/row.json';
  static const String hinge = 'assets/lottie/hinge.json';
}

enum MovementPattern { push, pull, squat, hinge, core }

enum EquipmentKind { barbell, dumbbell, bodyweight, machine, bench }

extension MovementPatternLabel on MovementPattern {
  String get labelZh {
    switch (this) {
      case MovementPattern.push:
        return '推';
      case MovementPattern.pull:
        return '拉';
      case MovementPattern.squat:
        return '蹲';
      case MovementPattern.hinge:
        return '铰链';
      case MovementPattern.core:
        return '核心';
    }
  }

  String get lottieAsset {
    switch (this) {
      case MovementPattern.push:
      case MovementPattern.core:
        return LottieAssets.press;
      case MovementPattern.pull:
        return LottieAssets.row;
      case MovementPattern.squat:
        return LottieAssets.squat;
      case MovementPattern.hinge:
        return LottieAssets.hinge;
    }
  }
}

extension EquipmentKindLabel on EquipmentKind {
  String get labelZh {
    switch (this) {
      case EquipmentKind.barbell:
        return '杠铃';
      case EquipmentKind.dumbbell:
        return '哑铃';
      case EquipmentKind.bodyweight:
        return '自重';
      case EquipmentKind.machine:
        return '器械';
      case EquipmentKind.bench:
        return '卧推凳';
    }
  }
}

final class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.nameZh,
    required this.pattern,
    required this.equipment,
  });

  final String id;
  final String nameZh;
  final MovementPattern pattern;
  final EquipmentKind equipment;

  String get lottieAsset => pattern.lottieAsset;
}
