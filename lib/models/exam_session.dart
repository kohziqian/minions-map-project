import '../core/utils/date_format.dart';

// Collection: examSessions/{sessionId}
//   courseCode, courseName, venue, date (Timestamp),
//   startTime, endTime
//
// This ONE collection feeds the Exam Sessions list, the QR code,
// the student scanner and My Examinations.
// The Firestore document ID is the session ID.

class ExamSession {
  final String sessionId;
  final String courseCode;
  final String courseName;
  final String venue;
  final DateTime? date; // null when missing / invalid in Firestore
  final String startTime;
  final String endTime;
  final int? registeredStudents; // optional field in Firestore

  const ExamSession({
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.registeredStudents,
  });

  String get title {
    if (courseCode.isNotEmpty && courseName.isNotEmpty) {
      return '$courseCode - $courseName';
    }
    return courseName.isNotEmpty ? courseName : courseCode;
  }

  DateTime? get day {
    final d = date;
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  /// Minutes after midnight of [startTime] / [endTime]; null if unparseable.
  /// Accepts "09:00", "9:00 AM", "9am".
  static int? _parseMinutes(String t) {
    final m = RegExp(r'^\s*(\d{1,2})(?::(\d{2}))?\s*([AaPp][Mm])?')
        .firstMatch(t);
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final ap = m.group(3)?.toLowerCase();
    if (ap == 'pm' && h < 12) h += 12;
    if (ap == 'am' && h == 12) h = 0;
    return h * 60 + min;
  }

  int get startMinutes => _parseMinutes(startTime) ?? 0;

  /// Moment the session ends (falls back to end of day if no end time).
  DateTime? get endsAt {
    final d = day;
    if (d == null) return null;
    final m = _parseMinutes(endTime);
    return m == null
        ? d.add(const Duration(days: 1))
        : d.add(Duration(minutes: m));
  }

  bool get isCompleted {
    final e = endsAt;
    return e != null && DateTime.now().isAfter(e);
  }

  bool get isToday {
    final d = day;
    final n = DateTime.now();
    return d != null && d == DateTime(n.year, n.month, n.day);
  }

  String get longDate {
    final d = date;
    return d == null ? 'Date not set' : formatLongDate(d);
  }

  String get formattedDate {
    final d = date;
    return d == null ? 'Date not set' : formatShortDate(d);
  }

  String get formattedTime {
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$startTime – $endTime';
    }
    if (startTime.isNotEmpty) return startTime;
    if (endTime.isNotEmpty) return endTime;
    return 'Time not set';
  }
}
