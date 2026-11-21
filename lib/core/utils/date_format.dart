// Dart date helper

const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

const List<String> kWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  'Sunday',
];

// "Mon, 5 January 2026"
String formatLongDate(DateTime d) =>
    '${kWeekdays[d.weekday - 1]}, ${d.day} ${kMonths[d.month - 1]} ${d.year}';

// "5/1/2026"
String formatShortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

// "5/1/2026 09:03:07". 
String formatTimestamp(DateTime? value) {
  if (value == null) return 'Recorded just now';  // Returns 'Recorded just now' when [value] is null

  return '${value.day}/${value.month}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
}
