import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/training/elapsed_format.dart';

/// Title and subtitle for the primary resume card.
abstract final class ResumeCopy {
  static String cardTitle({required String name, required Duration? elapsed}) {
    if (elapsed == null) {
      return AppStrings.resumeCardTitle(
        name: name,
        detail: AppStrings.workoutPreparing,
      );
    }
    return AppStrings.resumeCardTitle(
      name: name,
      detail: elapsedPhrase(elapsed),
    );
  }

  static String cardSubtitle({
    required int completedSets,
    required double volumeKg,
  }) {
    return AppStrings.resumeLoggedLine(
      completedSets: completedSets,
      volume: volumeKg.toStringAsFixed(0),
    );
  }

  /// Floors to whole minutes. Under one minute stays a single phrase.
  static String elapsedPhrase(Duration elapsed) {
    final Duration safe = elapsed.isNegative ? Duration.zero : elapsed;
    final int minutes = safe.inMinutes;
    if (minutes < 1) {
      return AppStrings.elapsedUnderOneMinute;
    }
    final int hours = safe.inHours;
    if (hours < 1) {
      return AppStrings.elapsedMinutes(minutes);
    }
    final int remain = minutes.remainder(ElapsedFormat.minutesPerHour);
    if (remain == 0) {
      return AppStrings.elapsedHours(hours);
    }
    return AppStrings.elapsedHoursMinutes(hours: hours, minutes: remain);
  }
}
