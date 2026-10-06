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
}

abstract final class AppColors {
  static const int bg = 0xFF0A0A0A;
  static const int surface = 0xFF161616;
  static const int surfaceHigh = 0xFF222222;
  static const int text = 0xFFF2F2F2;
  static const int textMuted = 0xFF8A8A8A;
  static const int accent = 0xFF3DDC97;
  static const int danger = 0xFFFF6B6B;
}

abstract final class AppStrings {
  static const String appNameZh = '曲线自由';
  static const String appNameEn = 'CurveFree';
  static const String tagline = '本机训练与饮食记录 · 完全开源';
  static const String training = '训练';
  static const String nutrition = '饮食';
  static const String trainingHint = '记录组数、重量与计划（后续模块）';
  static const String nutritionHint = '记录饮食与营养目标（后续模块）';
  static const String localData = '本机数据';
  static const String exportBackup = '导出备份';
  static const String importBackup = '从备份恢复';
  static const String storageReady = '本地库已就绪';
  static const String storageEmpty = '尚无用户数据';
  static const String gplNotice = '以 GNU GPLv3 发布';
}
