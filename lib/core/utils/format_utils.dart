class FormatUtils {
  const FormatUtils._();

  static String durationMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours hrs' : '$hours hrs $remaining mins';
  }

  static String percent(double value) {
    return '${(value * 100).toInt()}%';
  }
}
