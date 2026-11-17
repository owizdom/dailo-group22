const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Which heading a date belongs under in a transaction list.
enum DayBucket { today, yesterday, earlier }

/// `10500` becomes `10,500`.
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    // A comma goes before every group of three digits counted from the right.
    final digitsLeft = digits.length - i;
    if (i > 0 && digitsLeft % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `10500` becomes `10,500 Frw`.
String formatFrw(int value) => '${formatNumber(value)} Frw';

/// `27 Sep 2026, 14:32`.
String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatDate(value)}, $hour:$minute';
}

/// `27 Sep 2026`.
String formatDate(DateTime value) {
  return '${value.day} ${_monthNames[value.month - 1]} ${value.year}';
}

/// Compares calendar days, not 24-hour periods.
DayBucket dayBucket(DateTime value, {required DateTime now}) {
  final day = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  // Building yesterday from the calendar handles month and year changes.
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  if (day == today) return DayBucket.today;
  if (day == yesterday) return DayBucket.yesterday;
  return DayBucket.earlier;
}

/// Up to two capital letters for an avatar: `Uwase Diane` gives `UD`,
/// a phone number gives `#`.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  final firstLetter = words.first.isEmpty ? '' : words.first[0];
  if (!_isLetter(firstLetter)) return '#';

  final initials = words.take(2).map((word) => word[0].toUpperCase());
  return initials.join();
}

/// Upper and lower case differ only for letters, so digits and symbols fail.
bool _isLetter(String character) {
  return character.toUpperCase() != character.toLowerCase();
}
