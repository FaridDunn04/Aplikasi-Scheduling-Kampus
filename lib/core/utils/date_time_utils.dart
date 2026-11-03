import 'package:intl/intl.dart';

enum UrgencyLevel {
  overdue,
  urgent, // < 24 jam
  warning, // < 48 jam
  normal, // >= 48 jam
}

class DateTimeUtils {
  static final List<String> englishDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  static final List<String> shortEnglishDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  static final List<String> englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static String getDayName(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return englishDays[dayOfWeek - 1];
    }
    return 'Monday';
  }

  static String getShortDayName(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return shortEnglishDays[dayOfWeek - 1];
    }
    return 'Mon';
  }

  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE, MMM d, yyyy').format(dateTime);
  }

  static String formatDateTimeDisplay(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  static String formatTimeDisplay(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static int timeStringToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }

  static UrgencyLevel getUrgencyLevel(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return UrgencyLevel.overdue;
    } else if (difference.inHours < 24) {
      return UrgencyLevel.urgent;
    } else if (difference.inHours < 48) {
      return UrgencyLevel.warning;
    } else {
      return UrgencyLevel.normal;
    }
  }

  static String formatRelativeDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final hoursAgo = difference.inHours.abs();
      if (hoursAgo == 0) {
        return 'Overdue by ${difference.inMinutes.abs()}m ago';
      } else if (hoursAgo < 24) {
        return 'Overdue by ${hoursAgo}h ago';
      } else {
        return 'Overdue by ${difference.inDays.abs()}d ago';
      }
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m left';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h left';
    } else if (difference.inDays == 1) {
      return 'Tomorrow, ${DateFormat('HH:mm').format(deadline)}';
    } else if (difference.inDays < 7) {
      return '${getDayName(deadline.weekday)}, ${DateFormat('HH:mm').format(deadline)}';
    } else {
      return DateFormat('d MMM yyyy, HH:mm').format(deadline);
    }
  }

  static String toIso8601String(DateTime dt) {
    // Format YYYY-MM-DDTHH:mm:00
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00';
  }

  static DateTime parseIso(String isoString) {
    return DateTime.tryParse(isoString) ?? DateTime.now();
  }
}
