import 'package:intl/intl.dart';

enum UrgencyLevel {
  overdue,
  urgent, // < 24 jam
  warning, // < 48 jam
  normal, // >= 48 jam
}

class DateTimeUtils {
  static final List<String> indonesianDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  static final List<String> shortIndonesianDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min'
  ];

  static final List<String> indonesianMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  static String getDayName(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return indonesianDays[dayOfWeek - 1];
    }
    return 'Senin';
  }

  static String getShortDayName(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return shortIndonesianDays[dayOfWeek - 1];
    }
    return 'Sen';
  }

  static String formatFullDate(DateTime dateTime) {
    final dayName = getDayName(dateTime.weekday);
    try {
      final formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
      return '$dayName, $formattedDate';
    } catch (_) {
      final monthName = indonesianMonths[dateTime.month - 1];
      return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
    }
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
        return 'Terlewat ${difference.inMinutes.abs()} mnt lalu';
      } else if (hoursAgo < 24) {
        return 'Terlewat $hoursAgo jam lalu';
      } else {
        return 'Terlewat ${difference.inDays.abs()} hari lalu';
      }
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lagi';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lagi';
    } else if (difference.inDays == 1) {
      return 'Besok, ${DateFormat('HH:mm').format(deadline)}';
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
