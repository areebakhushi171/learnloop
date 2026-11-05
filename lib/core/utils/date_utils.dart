import 'package:intl/intl.dart';

class AppDateUtils {
  const AppDateUtils._();

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
