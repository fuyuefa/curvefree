abstract final class ElapsedFormat {
  static const int secondsPerMinute = 60;
  static const int minutesPerHour = 60;
  static const int padWidth = 2;

  static String format(Duration duration) {
    final Duration safe = duration.isNegative ? Duration.zero : duration;
    final int hours = safe.inHours;
    final int minutes = safe.inMinutes.remainder(minutesPerHour);
    final int seconds = safe.inSeconds.remainder(secondsPerMinute);
    final String mm = minutes.toString().padLeft(padWidth, '0');
    final String ss = seconds.toString().padLeft(padWidth, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Rest left on the float. Minutes are not zero-padded: `0:45`.
  static String countdown(Duration duration) {
    final Duration safe = duration.isNegative ? Duration.zero : duration;
    final int totalSeconds = safe.inSeconds;
    final int minutes = totalSeconds ~/ secondsPerMinute;
    final int seconds = totalSeconds.remainder(secondsPerMinute);
    final String ss = seconds.toString().padLeft(padWidth, '0');
    return '$minutes:$ss';
  }
}
