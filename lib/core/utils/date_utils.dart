import 'package:intl/intl.dart';

class AppDateUtils {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }

  static String formatCountdown(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now);

    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    if (diff.inDays < 7) return '${diff.inDays}d left';
    return DateFormat('dd MMM').format(due);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    return date.difference(now).inDays < 7 && date.isAfter(now);
  }
}
