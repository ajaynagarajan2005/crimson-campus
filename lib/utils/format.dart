import 'package:flutter/material.dart';

const List<String> weekdayNames = [
  '',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> weekdayShort = [
  '',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// 9:00 AM style.
String formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Indian rupee formatting with lakh grouping, e.g. ₹1,29,500.
String formatInr(int amount) {
  final digits = amount.toString();
  if (digits.length <= 3) return '₹$digits';
  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '₹${groups.join(',')},$lastThree';
}

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Parses a server timestamp ("YYYY-MM-DD HH:MM:SS", UTC) into local time.
DateTime? parseUtcTimestamp(String value) {
  final parsed = DateTime.tryParse('${value.trim().replaceFirst(' ', 'T')}Z');
  return parsed?.toLocal();
}

const List<String> _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Tue, 21 Oct 2026 · 3:40 PM" in the device's time zone.
String formatLocalDateTime(DateTime t) =>
    '${weekdayShort[t.weekday]}, ${t.day} ${_monthsShort[t.month - 1]} ${t.year} · '
    '${formatTime(TimeOfDay(hour: t.hour, minute: t.minute))}';

/// "Wed, 28 Oct 2026".
String formatDate(DateTime d) => '${weekdayShort[d.weekday]}, ${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

/// "28 Oct" — short form for chips and ranges.
String formatDayMonth(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

/// Parses a "YYYY-MM-DD" date.
DateTime? parseIsoDate(String? value) => value == null ? null : DateTime.tryParse(value);

/// "just now", "5 min ago", "3 h ago", "2 days ago" or a date.
String formatTimeAgo(DateTime t, [DateTime? now]) {
  final diff = (now ?? DateTime.now()).difference(t);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return diff.inDays == 1 ? 'yesterday' : '${diff.inDays} days ago';
  return '${t.day} ${_monthsShort[t.month - 1]} ${t.year}';
}
