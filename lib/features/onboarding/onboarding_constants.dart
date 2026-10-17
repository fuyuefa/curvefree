/// First-run collection length. Welcome and done sit outside this count.
abstract final class OnboardingLimits {
  static const int collectCount = 8;
}

abstract final class BodyDefaults {
  static const double heightCm = 165;
  static const double weightKg = 55;
  static const double minHeightCm = 140;
  static const double maxHeightCm = 210;
  static const double minWeightKg = 35;
  static const double maxWeightKg = 180;

  /// One tenth of the unit: 0.1 cm and 0.1 kg.
  static const double heightStepCm = 0.1;
  static const double weightStepKg = 0.1;
  static const int metricFractionDigits = 1;

  static double step({
    required double value,
    required double delta,
    required double min,
    required double max,
  }) {
    final int scale = _decimalScale(metricFractionDigits);
    final double next = ((value + delta) * scale).round() / scale;
    if (next < min) {
      return min;
    }
    if (next > max) {
      return max;
    }
    return next;
  }

  static String format(double value) {
    final int scale = _decimalScale(metricFractionDigits);
    final double rounded = (value * scale).round() / scale;
    if (rounded == rounded.roundToDouble()) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(metricFractionDigits);
  }
}

int _decimalScale(int digits) {
  int scale = 1;
  for (int i = 0; i < digits; i++) {
    scale *= 10;
  }
  return scale;
}

abstract final class OnboardingJsonKeys {
  static const String onboardingDone = 'onboardingDone';
  static const String sex = 'sex';
  static const String heightCm = 'heightCm';
  static const String weightKg = 'weightKg';
  static const String goal = 'goal';
  static const String daysPerWeek = 'daysPerWeek';
  static const String equipment = 'equipment';
  static const String experience = 'experience';
  static const String preferences = 'preferences';
  static const String activity = 'activity';
}

abstract final class OnboardingCopy {
  static const String welcomeBody = '训练和饮食，从这里开始记';
  static const String welcomePlan = '先做一份计划，再开始记';
  static const String start = '开始';
  static const String skipExisting = '已有记录，直接进入';
  static const String next = '下一步';
  static const String back = '返回';
  static const String enterToday = '进入今日';

  static const String sexTitle = '你的性别';
  static const String sexBody = '只用来调整计划里的训练与恢复建议';

  static const String bodyTitle = '身高和体重';
  static const String bodyBody = '用来估算计划里的训练量';
  static const String height = '身高';
  static const String weight = '体重';
  static const String centimeter = '厘米';
  static const String kilogram = '公斤';

  static const String goalTitle = '这份计划想达成什么';
  static const String goalBody = '计划会按目标来排动作和组数';

  static const String freqTitle = '每周练几天';
  static const String freqBody = '计划按这个天数排进一周';

  static const String equipTitle = '你一般在哪练';
  static const String equipBody = '三个场景就够，计划会换成对应的动作，不用逐件选器械';
  static const String equipGymBody = '杠铃和固定器械';
  static const String equipDumbbellBody = '一对哑铃就能练';
  static const String equipBodyweightBody = '不依赖器械';

  static const String expTitle = '训练经验';
  static const String expBody = '先记下来，之后计划可以按经验调整难度';
  static const String expBeginner = '刚开始';
  static const String expMid = '练过一阵';
  static const String expAdvanced = '已经很熟';

  static const String preferTitle = '有没有特别想练的部位？';
  static const String preferBody = '可跳过';
  static const String preferSkip = '跳过这题';

  static const String activityTitle = '平时活动多吗';
  static const String activityBody = '用来辅助饮食热量，训练计划仍以力量为主';
  static const String activitySedentary = '很少动';
  static const String activityLight = '轻度活动';
  static const String activityModerate = '中等活动';
  static const String activityActive = '比较活跃';

  static const String doneTitle = '计划已在这台手机上';
  static const String doneBody = '可以之后再改计划，也可以直接开练';

  static String progressLabel(int index) =>
      '$index / ${OnboardingLimits.collectCount}';
}
