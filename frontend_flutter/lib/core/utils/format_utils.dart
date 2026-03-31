/// Formatting utilities for UI display — no Flutter dependencies.
class FormatUtils {
  FormatUtils._();

  /// Format a duration in seconds as "Xm Ys" or just "Xs".
  static String formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)} s';
    }
    final m = (seconds ~/ 60);
    final s = seconds - m * 60;
    return '${m}m ${s.toStringAsFixed(0)}s';
  }

  /// Format a sample count with thousands separator.
  static String formatSamples(int count) {
    final s = count.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Format a percentage to 1 decimal place.
  static String formatPct(double pct) => '${pct.toStringAsFixed(1)}%';

  /// Format a velocity in mm/s.
  static String formatVelocity(double mmS) => '${mmS.toStringAsFixed(0)} mm/s';

  /// Format a displacement in mm.
  static String formatMm(double mm) => '${mm.toStringAsFixed(1)} mm';

  /// Format an angle in degrees.
  static String formatDeg(double deg) => '${deg.toStringAsFixed(1)}°';

  /// Truncate a string to [maxLen] characters with an ellipsis.
  static String truncate(String s, int maxLen) =>
      s.length <= maxLen ? s : '${s.substring(0, maxLen - 1)}…';
}
