import 'package:flutter/services.dart';

/// Platform haptics behind one gate.
///
/// No settings preference exists yet. [isEnabled] stays on so a later toggle
/// can assign one callback and cover every call site.
abstract final class AppHaptics {
  static bool Function() isEnabled = () => true;

  /// Successful set check.
  static Future<void> setChecked() {
    return _impact(HapticFeedback.lightImpact);
  }

  /// Rest countdown reached zero on its own.
  static Future<void> restEnded() {
    return _impact(HapticFeedback.mediumImpact);
  }

  static Future<void> _impact(Future<void> Function() play) async {
    if (!isEnabled()) {
      return;
    }
    try {
      await play();
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
