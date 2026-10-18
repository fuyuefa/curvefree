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
  static const double setCheckSlot = 48;
  static const double borderWidth = 1;
  static const double focusBorderWidth = 1.5;

  /// Fraction of the session list viewport where a focused set sits.
  static const double focusRowAlignment = 0.3;
  static const int previousColumnFlex = 5;
  static const int loadColumnFlex = 4;
  static const int repsColumnFlex = 3;
  static const double restCountdownSize = 36;

  /// Numerals on the finish summary.
  static const double summaryValueSize = 32;
  static const double lottieThumb = 48;
  static const double navIndicatorWidth = 16;
  static const double navIndicatorHeight = 3;
  static const double iconSize = 20;
}

/// Short motions on the session screen.
abstract final class AppMotion {
  /// Rest bar collapse, and how long a set-row waits before scrolling so the
  /// bar has finished opening.
  static const Duration restCollapse = Duration(milliseconds: 220);
}

abstract final class AppFonts {
  /// Bundled face. Web must not wait on a Google Fonts download for CJK.
  static const String ui = 'Noto Sans SC';

  static const List<String> cjkFallback = <String>[
    ui,
    'PingFang SC',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'Microsoft YaHei',
  ];
}

abstract final class AppStrings {
  static const String appNameZh = '曲线自由';
  static const String appNameEn = 'CurveFree';
  static const String tagline = '本机训练与饮食记录 · 完全开源';

  /// Single privacy line. Shown on 今日, not repeated on every screen.
  static const String localOnlyNotice = '数据只留在这台设备，不会上传';
  static const String training = '训练';
  static const String nutrition = '饮食';
  static const String trainingHint = '记录组数、重量；动作库可查 Lottie';
  static const String nutritionHint = '记饮食、热量蛋白与缺口建议';
  static const String nutritionLogTitle = '饮食记录';
  static const String addFood = '记一笔';
  static const String pickFood = '选择食物';
  static const String searchFoodHint = '搜索鸡胸、米饭…';
  static const String emptyFoodLogs = '今天还没有饮食记录';
  static const String gramsLabel = '克';
  static const String todayMacros = '今日营养';
  static const String dietAssistTitle = '饮食辅助';
  static const String dietAssistMet = '蛋白目标已覆盖';
  static const String trainingLogTitle = '训练记录';
  static const String startWorkout = '开始训练';
  static const String emptyWorkouts = '还没有训练记录，点下方开始，当场记组';
  static const String addExercise = '添加动作';
  static const String addSet = '加一组';
  static const String exerciseNameHint = '动作名，如卧推';
  static const String finishWorkout = '完成训练';
  static const String finishThisSession = '完成本次训练';
  static const String finishSessionConfirmTitle = '完成这次训练？';
  static const String finishSessionConfirmBody = '结束后看本堂小结';
  static const String finishSessionConfirmAction = '完成';
  static const String keepLoggingSets = '继续记组';
  static const String workoutCompleted = '训练已完成';
  static const String sessionDoneTitle = '本堂练完了';
  static const String backToToday = '回到今日';
  static const String reviewThisSession = '再看看这堂';
  static const String deleteSessionTitle = '删除这次训练？';
  static const String deleteSessionBody = '此操作无法撤销';
  static const String deleteSessionAction = '删除';
  static const String navToday = '今日';
  static const String navMe = '我的';
  static const String continueAction = '继续';
  static const String weekProgress = '本周进度';
  static const String statCompletion = '完成率';
  static const String muscleGroupsTitle = '肌群';
  static const String musclesPlannedToday = '今天会练到';
  static const String weekTrend = '近一周趋势';
  static const String wallClockLabel = '总时长';
  static const String activeTrainingLabel = '不含休息';
  static const String readingWorkout = '正在读取训练…';
  static const String missingWorkout = '这次训练不存在';
  static const String elapsedLabel = '用时';
  static const String restTimerLabel = '组间休息';
  static const String restEnoughNextSet = '够了，下一组';
  static const String restBubbleLabel = '休息';
  static const String minimizeSession = '收起来';
  static const String workoutBubbleLabel = '训练中';
  static const String workoutPreparing = '准备中';
  static const String setsCountLabel = '组数';
  static const String themeAppearance = '外观';
  static const String themeSystem = '跟随系统';
  static const String themeLight = '日间';
  static const String themeDark = '夜间';
  static const String workoutInProgress = '进行中';
  static const String workoutFinished = '已完成';
  static const String deleteWorkout = '删除这次训练';
  static const String setColumn = '组';
  static const String weightColumn = 'kg';
  static const String repsColumn = '次';
  static const String checkColumn = '✓';
  static const String volumeLabel = '容量';
  static const String lastHintPrefix = '上次';
  static const String previousEmpty = '—';
  static const String previousLoadTimes = '×';
  static const String confirm = '确定';
  static const String cancel = '取消';
  static const String exerciseLibrary = '动作库';
  static const String pickExercise = '选择动作';
  static const String searchExerciseHint = '搜索动作、部位、推拉蹲…';
  static const String customExercise = '自定义动作名';
  static const String trainingPlanTitle = '训练计划';
  static const String generatePlan = '生成计划';
  static const String emptyPlan = '还没有计划，选目标与天数后生成，规则公开可改';
  static const String daysPerWeek = '每周训练天数';
  static const String startFromPlan = '按此日开练';
  static const String localData = '本机数据';
  static const String exportBackup = '导出备份';
  static const String importBackup = '从备份恢复';
  static const String resumeContinue = '接着练';
  static const String switchToTodayPlan = '改用今日计划动作';
  static const String startConflictTitle = '已有进行中的训练';
  static const String startConflictBody = '先接着练这堂，还是结束它再按今日计划开新课？未完成的组会留在当前课里';
  static const String conflictResumeCurrent = '继续当前';
  static const String conflictFinishAndStart = '结束并开新';
  static const String freeWorkoutName = '自由训练';
  static const String elapsedUnderOneMinute = '已经不到 1 分钟';
  static const String todayPlan = '今日计划';
  static const String todayRest = '今日按计划休息';
  static const String backupExportConfirmTitle = '导出备份到文件';
  static const String backupExportConfirmBody =
      '备份含本机训练与饮食，下一步可能出现系统分享面板：选「存储/文件」可只留在设备；选网盘或聊天会把文件发出去，应用本身不会上传';
  static const String backupSaved = '备份已保存在本机，分享到聊天或网盘会让这份文件离开设备';
  static const String backupRestoreTitle = '恢复备份';
  static const String backupRestoreBody = '用这份备份覆盖本机的训练、饮食和计划？数据仍只留在这台设备，不会上传';
  static const String backupRestored = '已从备份恢复，数据仍只在本机';
  static const String backupExportFailed = '导出失败';
  static const String backupImportFailed = '恢复失败';
  static const String backupShareSubject = '曲线自由备份';
  static const String backupSaveDialog = '保存备份文件';
  static const String backupPickDialog = '选择备份文件';
  static const String storageReady = '本地库已就绪';
  static const String storageEmpty = '尚无用户数据';
  static const String gplNotice = '以 GNU GPLv3 发布';

  /// 「已完成 N 组 · 容量 X kg」. Volume uses the session total, rounded like the bar.
  static String completedVolumeLine({
    required int completedSets,
    required double volumeKg,
  }) {
    final String volume = volumeKg.toStringAsFixed(0);
    return '已完成 $completedSets 组 · $volumeLabel $volume $weightColumn';
  }

  static String weekFinishedLine(int count) => '本周完成 $count 次';

  static String recentVolumeLine({required int days, required String volume}) {
    return '近 $days 天容量 $volume $weightColumn';
  }

  static String trendNoVolumeLine(int days) => '这 $days 天还没有容量';

  static String elapsedMinutes(int minutes) => '已经 $minutes 分钟了';

  static String elapsedHours(int hours) => '已经 $hours 小时了';

  static String elapsedHoursMinutes({
    required int hours,
    required int minutes,
  }) {
    return '已经 $hours 小时 $minutes 分钟了';
  }

  static String resumeCardTitle({
    required String name,
    required String detail,
  }) {
    return '$name · $detail';
  }

  static String resumeLoggedLine({
    required int completedSets,
    required String volume,
  }) {
    return '已记 $completedSets $setColumn · $volumeLabel约 $volume $weightColumn';
  }
}
