/// First-run collection length. Welcome and done sit outside this count.
abstract final class OnboardingLimits {
  static const int collectCount = 8;
}

abstract final class BodyDefaults {
  static const int heightCm = 165;
  static const double weightKg = 55;
  static const int minHeightCm = 140;
  static const int maxHeightCm = 210;
  static const double minWeightKg = 35;
  static const double maxWeightKg = 180;
  static const double weightStepKg = 0.5;
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
  static const String welcomeBody = '训练和饮食，都记在这台手机上。';
  static const String welcomePlan = '先做一份计划，再开始记。';
  static const String start = '开始';
  static const String skipExisting = '已有记录，直接进入';
  static const String next = '下一步';
  static const String back = '返回';
  static const String enterToday = '进入今日';

  static const String sexTitle = '你的性别';
  static const String sexBody = '只用来调整计划里的训练与恢复建议。';

  static const String bodyTitle = '身高和体重';
  static const String bodyBody = '用来估算计划里的训练量，只存在这台手机上。';
  static const String height = '身高';
  static const String weight = '体重';
  static const String centimeter = '厘米';
  static const String kilogram = '公斤';

  static const String goalTitle = '这份计划想达成什么';
  static const String goalBody = '计划会按目标来排动作和组数。';

  static const String freqTitle = '每周练几天';
  static const String freqBody = '计划按这个天数排进一周。';

  static const String equipTitle = '你一般在哪练';
  static const String equipBody = '三个场景就够。计划会换成对应的动作，不用逐件选器械。';
  static const String equipGymBody = '杠铃和固定器械';
  static const String equipDumbbellBody = '一对哑铃就能练';
  static const String equipBodyweightBody = '不依赖器械';

  static const String expTitle = '训练经验';
  static const String expBody = '先记下来，之后计划可以按经验调整难度。';
  static const String expBeginner = '刚开始';
  static const String expMid = '练过一阵';
  static const String expAdvanced = '已经很熟';

  static const String preferTitle = '更想练哪里';
  static const String preferBody = '先用图标占位，可以多选。';
  static const String preferPush = '推';
  static const String preferPull = '拉';
  static const String preferLegs = '腿';
  static const String preferCore = '核心';

  static const String activityTitle = '平时活动多吗';
  static const String activityBody = '用来辅助饮食热量。训练计划仍以力量为主。';
  static const String activitySedentary = '很少动';
  static const String activityLight = '轻度活动';
  static const String activityModerate = '中等活动';
  static const String activityActive = '比较活跃';

  static const String doneTitle = '计划已在这台手机上';
  static const String doneBody = '可以之后再改计划，也可以直接开练。数据不会上传。';

  static String progressLabel(int index) =>
      '$index / ${OnboardingLimits.collectCount}';
}
