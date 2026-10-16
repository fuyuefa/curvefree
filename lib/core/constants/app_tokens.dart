/// Shared layout and visual tokens. Prefer these over raw literals in UI.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadii {
  static const double md = 12;
  static const double lg = 16;

  /// radius.card
  static const double card = 20;

  /// radius.cta
  static const double cta = 18;

  /// radius.chip (pill)
  static const double chip = 999;
}

/// v3.2 layout sizes from the visual token doc.
abstract final class AppLayout {
  static const double bottomNavHeight = 56;
  static const double screenTitleSize = 22;
  static const double accentStripWidth = 4;
  static const double accentStripHeight = 22;
  static const double progressBarHeight = 8;
  static const double progressEndpoint = 10;
  static const double muscleDot = 28;
  static const double setIndexSize = 28;
  static const double lottieThumb = 48;
  static const double navIndicatorWidth = 16;
  static const double navIndicatorHeight = 3;
  static const double iconSize = 20;
}

abstract final class AppFonts {
  static const List<String> cjkFallback = <String>[
    'PingFang SC',
    'Noto Sans SC',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'Microsoft YaHei',
  ];
}

abstract final class AppStrings {
  static const String appNameZh = '曲线自由';
  static const String appNameEn = 'CurveFree';
  static const String tagline = '本机训练与饮食记录 · 完全开源';
  static const String training = '训练';
  static const String nutrition = '饮食';
  static const String trainingHint = '记录组数、重量；动作库可查 Lottie';
  static const String nutritionHint = '记饮食、热量蛋白与缺口建议';
  static const String nutritionLogTitle = '饮食记录';
  static const String addFood = '记一笔';
  static const String pickFood = '选择食物';
  static const String searchFoodHint = '搜索鸡胸、米饭…';
  static const String emptyFoodLogs = '今天还没有饮食记录。';
  static const String gramsLabel = '克';
  static const String todayMacros = '今日营养';
  static const String dietAssistTitle = '饮食辅助';
  static const String dietAssistMet = '蛋白目标已覆盖。';
  static const String trainingLogTitle = '训练记录';
  static const String startWorkout = '开始训练';
  static const String emptyWorkouts = '还没有训练课。点下方开始，当场记组。';
  static const String addExercise = '添加动作';
  static const String addSet = '加一组';
  static const String exerciseNameHint = '动作名，如卧推';
  static const String finishWorkout = '完成训练';
  static const String finishThisSession = '完成本次训练';
  static const String navToday = '今日';
  static const String navMe = '我的';
  static const String continueAction = '继续';
  static const String weekProgress = '本周进度';
  static const String statCompletion = '完成率';
  static const String muscleGroupsTitle = '肌群';
  static const String elapsedLabel = '用时';
  static const String setsCountLabel = '组数';
  static const String themeAppearance = '外观';
  static const String themeSystem = '跟随系统';
  static const String themeLight = '日间';
  static const String themeDark = '夜间';
  static const String workoutInProgress = '进行中';
  static const String workoutFinished = '已完成';
  static const String deleteWorkout = '删除训练课';
  static const String setColumn = '组';
  static const String weightColumn = 'kg';
  static const String repsColumn = '次';
  static const String volumeLabel = '容量';
  static const String lastHintPrefix = '上次';
  static const String confirm = '确定';
  static const String cancel = '取消';
  static const String exerciseLibrary = '动作库';
  static const String pickExercise = '选择动作';
  static const String searchExerciseHint = '搜索动作、推拉蹲…';
  static const String customExercise = '自定义动作名';
  static const String trainingPlanTitle = '训练计划';
  static const String generatePlan = '生成计划';
  static const String emptyPlan = '还没有计划。选目标与天数后生成，规则公开可改。';
  static const String daysPerWeek = '每周训练天数';
  static const String startFromPlan = '按此日开练';
  static const String localData = '本机数据';
  static const String exportBackup = '导出备份';
  static const String importBackup = '从备份恢复';
  static const String resumeWorkout = '继续未完成训练';
  static const String todayPlan = '今日计划';
  static const String todayRest = '今日按计划休息';
  static const String backupSaved = '备份已写入本机文件。分享或另存由你决定，不会自动上传。';
  static const String backupRestoreTitle = '恢复备份';
  static const String backupRestoreBody = '用这份备份覆盖本机的训练、饮食和计划？数据仍只留在这台设备，不会上传。';
  static const String backupRestored = '已从备份恢复，数据仍只在本机';
  static const String backupExportFailed = '导出失败';
  static const String backupImportFailed = '恢复失败';
  static const String backupShareSubject = '曲线自由备份';
  static const String backupSaveDialog = '保存备份文件';
  static const String backupPickDialog = '选择备份文件';
  static const String storageReady = '本地库已就绪';
  static const String storageEmpty = '尚无用户数据';
  static const String gplNotice = '以 GNU GPLv3 发布';
}
