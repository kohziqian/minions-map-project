import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'shared.dart';

// =====================================================
// SHARED EXAM SESSION MODEL & FIRESTORE STREAM
// =====================================================
//
// Collection: examSessions/{sessionId}
//   courseCode, courseName, venue, date (Timestamp),
//   startTime, endTime
//
// This ONE collection feeds the Exam Sessions list,
// the QR code, the student scanner and My Examinations.
// The Firestore document ID is the session ID.
//

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

  factory ExamSession.fromData(String id, Map<String, dynamic> s) {
    final dateValue = s['date'];

    return ExamSession(
      sessionId: id,
      courseCode: (s['courseCode'] ?? '').toString(),
      courseName: (s['courseName'] ?? '').toString(),
      venue: (s['venue'] ?? '').toString(),
      date: dateValue is Timestamp ? dateValue.toDate() : null,
      startTime: (s['startTime'] ?? '').toString(),
      endTime: (s['endTime'] ?? '').toString(),
      registeredStudents: (s['registeredStudents'] as num?)?.toInt(),
    );
  }

  factory ExamSession.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ExamSession.fromData(doc.id, doc.data() ?? {});
  }

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
    if (d == null) return 'Date not set';
    return '${kWeekdays[d.weekday - 1]}, ${d.day} ${kMonths[d.month - 1]} ${d.year}';
  }

  String get formattedDate {
    final d = date;
    if (d == null) return 'Date not set';
    return '${d.day}/${d.month}/${d.year}';
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

class ExamSessionsStreamBuilder extends StatelessWidget {
  final String emptyMessage;
  final String errorPrefix;
  final Widget Function(BuildContext context, List<ExamSession> sessions)
      builder;

  const ExamSessionsStreamBuilder({
    super.key,
    this.emptyMessage = 'No exam sessions available.',
    this.errorPrefix = 'Could not load exam sessions.',
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // No orderBy here: orderBy('date') would silently hide
      // documents that have no date. Callers sort in Dart instead.
      stream:
          FirebaseFirestore.instance.collection('examSessions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '$errorPrefix\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyMessage, textAlign: TextAlign.center),
            ),
          );
        }

        final sessions = docs.map((doc) => ExamSession.fromDoc(doc)).toList();
        return builder(context, sessions);
      },
    );
  }
}

// =====================================================
// SHARED TEXT STYLES (one look for every exam list)
// =====================================================

const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

const List<String> kWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  'Sunday',
];

// Section header: "Today", "Upcoming", "Completed", "Mon, 5 Jan 2026"
const TextStyle kSectionStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: kInk,
);

// Sub header: time-slot label
const TextStyle kSubSectionStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: kSlate,
);

// Main line on a card: course code
const TextStyle kCardTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: kInk,
);

// Detail lines on a card: date, time, hall, students
const TextStyle kCardMetaStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: kSlate,
);

/// A small "icon + text" detail line used on exam cards.
class ExamMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const ExamMetaRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kSlate),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: kCardMetaStyle)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  final TextStyle style;

  const SectionHeader(this.text, {super.key, this.style = kSectionStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: style),
    );
  }
}

// =====================================================
// STUDENT: MY EXAMINATIONS (Today / Upcoming / Completed)
// =====================================================

class StudentExamsPage extends StatelessWidget {
  const StudentExamsPage({super.key});

  int _compare(ExamSession a, ExamSession b) {
    final ad = a.day;
    final bd = b.day;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    final c = ad.compareTo(bd);
    return c != 0 ? c : a.startMinutes.compareTo(b.startMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Examinations')),
      body: ExamSessionsStreamBuilder(
        emptyMessage: 'No examination sessions scheduled.',
        errorPrefix: 'Could not load examinations.',
        builder: (context, sessions) {
          final today = <ExamSession>[];
          final upcoming = <ExamSession>[];
          final completed = <ExamSession>[];

          for (final s in sessions) {
            if (s.date == null) continue; // cannot be placed in time
            if (s.isToday) {
              today.add(s);
            } else if (s.isCompleted) {
              completed.add(s);
            } else {
              upcoming.add(s);
            }
          }

          today.sort(_compare);
          upcoming.sort(_compare);
          // Most recently finished first.
          completed.sort((a, b) => _compare(b, a));

          final children = <Widget>[];

          void addSection(String label, List<ExamSession> list,
              {bool dimmed = false}) {
            if (list.isEmpty) return;
            children.add(SectionHeader(label));
            for (final s in list) {
              children.add(_examCard(s, dimmed: dimmed));
            }
          }

          addSection('Today', today);
          addSection('Upcoming', upcoming);
          addSection('Completed', completed, dimmed: true);

          if (children.isEmpty) {
            return const Center(child: Text('No examinations to show.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: children,
          );
        },
      ),
    );
  }

  Widget _examCard(ExamSession s, {bool dimmed = false}) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.courseCode.isEmpty ? s.courseName : s.courseCode,
                  style: kCardTitleStyle),
              if (s.courseCode.isNotEmpty && s.courseName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(s.courseName, style: kCardMetaStyle),
                ),
              ExamMetaRow(
                icon: Icons.calendar_today_outlined,
                text: s.formattedDate,
              ),
              ExamMetaRow(
                icon: Icons.access_time,
                text: s.formattedTime,
              ),
              ExamMetaRow(
                icon: Icons.location_on_outlined,
                text: s.venue.isEmpty ? 'Hall not set' : s.venue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// EXAM SESSIONS LIST (invigilator)
// =====================================================
//
// Grouped by date, then by time slot.
// Tapping an UPCOMING session shows its attendance QR code.
//

class ExamSessionsPage extends StatelessWidget {
  final String title;
  final IconData trailingIcon;

  const ExamSessionsPage({
    super.key,
    this.title = 'Exam Sessions',
    this.trailingIcon = Icons.qr_code,
  });

  int _compare(ExamSession a, ExamSession b) {
    final c = a.day!.compareTo(b.day!);
    return c != 0 ? c : a.startMinutes.compareTo(b.startMinutes);
  }

  String _dayLabel(DateTime d) =>
      '${kWeekdays[d.weekday - 1]}, ${d.day} ${kMonths[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ExamSessionsStreamBuilder(
        builder: (context, sessions) {
          final dated = sessions.where((s) => s.date != null).toList();
          final undated = sessions.where((s) => s.date == null).toList();

          final upcoming = dated.where((s) => !s.isCompleted).toList()
            ..sort(_compare);
          final past = dated.where((s) => s.isCompleted).toList()
            ..sort(_compare);

          final children = <Widget>[];

          void addGroup(List<ExamSession> list, {required bool isPast}) {
            DateTime? lastDay;
            String? lastSlot;

            for (final s in list) {
              if (s.day != lastDay) {
                children.add(SectionHeader(_dayLabel(s.day!)));
                lastDay = s.day;
                lastSlot = null;
              }

              if (s.formattedTime != lastSlot) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(s.formattedTime, style: kSubSectionStyle),
                  ),
                );
                lastSlot = s.formattedTime;
              }

              children.add(_sessionCard(context, s, isPast: isPast));
            }
          }

          addGroup(upcoming, isPast: false);

          if (past.isNotEmpty) {
            children.add(const SectionHeader('Completed sessions'));
            addGroup(past, isPast: true);
          }

          if (undated.isNotEmpty) {
            children.add(const SectionHeader('Date not set'));
            for (final s in undated) {
              children.add(_sessionCard(context, s, isPast: false));
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: children,
          );
        },
      ),
    );
  }

  Widget _sessionCard(BuildContext context, ExamSession s,
      {required bool isPast}) {
    // Only upcoming sessions open the QR.
    final enabled = !isPast;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: !enabled
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamQRPage(session: s),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: kCardTitleStyle),
                      ExamMetaRow(
                        icon: Icons.access_time,
                        text: s.formattedTime,
                      ),
                      ExamMetaRow(
                        icon: Icons.location_on_outlined,
                        text: s.venue.isEmpty ? 'Hall not set' : s.venue,
                      ),
                      _RegisteredStudents(session: s),
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 12),
                  Icon(trailingIcon),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Registered students: N" line.
/// Uses the session's `registeredStudents` number if it exists,
/// otherwise the number of users registered with role Student.
class _RegisteredStudents extends StatelessWidget {
  final ExamSession session;

  const _RegisteredStudents({required this.session});

  @override
  Widget build(BuildContext context) {
    final fixed = session.registeredStudents;

    if (fixed != null) {
      return ExamMetaRow(
        icon: Icons.people_outline,
        text: 'Registered students: $fixed',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .snapshots(),
      builder: (context, snapshot) {
        final text = snapshot.hasData
            ? 'Registered students: ${snapshot.data!.docs.length}'
            : 'Registered students: …';

        return ExamMetaRow(icon: Icons.people_outline, text: text);
      },
    );
  }
}

// =====================================================
// EXAM QR PAGE
// =====================================================
//
// The QR contains ONLY the session ID. Everything else
// is loaded from Firestore when scanned, so the QR cannot
// be forged with fake course/venue details.
//

class ExamQRPage extends StatelessWidget {
  final ExamSession session;

  const ExamQRPage({super.key, required this.session});

  String get qrData => 'sessionId=${session.sessionId}';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    final double qrSize = isWideScreen
        ? (screenWidth * 0.25).clamp(260.0, 340.0)
        : (screenWidth * 0.65).clamp(220.0, 280.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam QR Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Exam Session Active',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Students can scan this QR code to record attendance.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                if (isWideScreen)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildExamDetailsCard()),
                      const SizedBox(width: 40),
                      _buildQrSection(qrSize),
                    ],
                  )
                else ...[
                  _buildExamDetailsCard(),
                  const SizedBox(height: 30),
                  _buildQrSection(qrSize),
                ],
                const SizedBox(height: 30),

                // Live count of students who have checked in
                // (QR scans AND invigilator scans use the same collection).
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('attendance')
                      .where('sessionId', isEqualTo: session.sessionId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;

                    return Text(
                      'Students: $count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Attendance will appear here when students scan the QR.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.courseCode,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              session.courseName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Venue: ${session.venue}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Date: ${session.formattedDate}',
              textAlign: TextAlign.center,
            ),
            if (session.startTime.isNotEmpty ||
                session.endTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Time: ${session.formattedTime}',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Session ID: ${session.sessionId}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(double qrSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: qrSize,
      ),
    );
  }
}

// =====================================================
// SHARED FIRESTORE WRITERS
// =====================================================
//
// attendance/{sessionId}_{studentId}
// examSubmissions/{sessionId}_{studentId}
//
// studentId is ALWAYS the matric / staff number, whether the
// student scanned the exam QR or the invigilator scanned the
// student's matric QR. The deterministic document ID prevents
// duplicates.
//

class RecordResult {
  final bool created; // false = it already existed
  final dynamic time; // Timestamp of the existing record, if any

  const RecordResult({required this.created, this.time});
}

Future<RecordResult> recordAttendance({
  required String sessionId,
  required String studentId,
  required String studentName,
  required String method, // 'Student QR' | 'Matriculation QR'
  String? recordedBy,
}) async {
  final ref = FirebaseFirestore.instance
      .collection('attendance')
      .doc('${sessionId}_$studentId');

  final existing = await ref.get();

  if (existing.exists) {
    return RecordResult(
      created: false,
      time: existing.data()?['checkInTime'],
    );
  }

  await ref.set({
    'sessionId': sessionId,
    'studentId': studentId,
    'studentName': studentName,
    'method': method,
    'recordedBy': recordedBy,
    'checkInTime': FieldValue.serverTimestamp(),
  });

  return const RecordResult(created: true);
}

Future<RecordResult> recordSubmission({
  required String sessionId,
  required String studentId,
  required String studentQrData,
  String? recordedBy,
}) async {
  final ref = FirebaseFirestore.instance
      .collection('examSubmissions')
      .doc('${sessionId}_$studentId');

  final existing = await ref.get();

  if (existing.exists) {
    return RecordResult(
      created: false,
      time: existing.data()?['submissionTime'],
    );
  }

  await ref.set({
    'sessionId': sessionId,
    'studentId': studentId,
    'studentQrData': studentQrData,
    'invigilatorId': recordedBy,
    'submissionTime': FieldValue.serverTimestamp(),
    'status': 'Submitted',
  });

  return const RecordResult(created: true);
}

/// Camera view + square frame + instruction label.
class ScannerFrame extends StatelessWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final String message;
  final bool messageAtBottom;

  const ScannerFrame({
    super.key,
    required this.onDetect,
    required this.message,
    this.messageAtBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(onDetect: onDetect),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          top: messageAtBottom ? null : 30,
          bottom: messageAtBottom ? 50 : null,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

String formatTimestamp(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate();

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  return 'Recorded just now';
}

// =====================================================
// STUDENT QR SCANNER
// =====================================================
//
// Student scans the exam QR (sessionId only). The session is
// loaded from Firestore; the student's name and matric number
// come from their profile.
//

class StudentQRScannerPage extends StatefulWidget {
  const StudentQRScannerPage({super.key});

  @override
  State<StudentQRScannerPage> createState() => _StudentQRScannerPageState();
}

class _StudentQRScannerPageState extends State<StudentQRScannerPage> {
  bool busy = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> handleQRCode(BarcodeCapture capture) async {
    if (busy) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null || value.isEmpty) continue;

      final sessionId = getQRValue(value, 'sessionId');

      if (sessionId == 'Unknown' ||
          sessionId.isEmpty ||
          sessionId.contains('/')) {
        continue;
      }

      busy = true;

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        busy = false;
        return;
      }

      try {
        // 1. Load the session from the database.
        final sessionDoc = await FirebaseFirestore.instance
            .collection('examSessions')
            .doc(sessionId)
            .get();

        if (!sessionDoc.exists) {
          if (!mounted) return;
          showMessage('Invalid exam QR code.');
          await Future.delayed(const Duration(seconds: 2));
          busy = false;
          return;
        }

        final session = ExamSession.fromDoc(sessionDoc);

        // 2. Load the student's profile (name + matric number).
        final profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final profile = profileDoc.data() ?? {};
        final matricNo = (profile['matricNo'] ?? '').toString().trim();
        final fullName = (profile['fullName'] ?? '').toString().trim();

        if (matricNo.isEmpty) {
          if (!mounted) return;
          showMessage('Your profile has no Student ID. Contact the admin.');
          await Future.delayed(const Duration(seconds: 2));
          busy = false;
          return;
        }

        // 3. Record attendance (duplicate-safe).
        final result = await recordAttendance(
          sessionId: sessionId,
          studentId: matricNo,
          studentName: fullName.isEmpty ? (user.email ?? 'Student') : fullName,
          method: 'Student QR',
          recordedBy: user.uid,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceSuccessPage(
              session: session,
              checkInTime: result.time,
              alreadyRecorded: !result.created,
            ),
          ),
        );
      } on FirebaseException catch (e) {
        busy = false;

        if (!mounted) return;
        showMessage('Could not record attendance: ${e.message}');
      }

      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Exam QR')),
      body: ScannerFrame(
        onDetect: handleQRCode,
        message: 'Place the examination QR code inside the box.',
        messageAtBottom: true,
      ),
    );
  }
}

// =====================================================
// ATTENDANCE SUCCESS PAGE (student)
// =====================================================

class AttendanceSuccessPage extends StatelessWidget {
  final ExamSession session;
  final dynamic checkInTime;
  final bool alreadyRecorded;

  const AttendanceSuccessPage({
    super.key,
    required this.session,
    required this.checkInTime,
    this.alreadyRecorded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Recorded')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Attendance Recorded',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              alreadyRecorded
                  ? 'You have already checked in for this exam.'
                  : 'Your examination check-in has been recorded.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    InfoRow('Course Code', session.courseCode),
                    const Divider(),
                    InfoRow('Course', session.courseName),
                    const Divider(),
                    InfoRow('Venue', session.venue),
                    const Divider(),
                    InfoRow('Session ID', session.sessionId),
                    const Divider(),
                    InfoRow('Check-in Time', formatTimestamp(checkInTime)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// INVIGILATOR SCANNER (attendance OR examination)
// =====================================================
//
// ScanMode.attendance  -> student has no phone; scan matric QR
//                         -> writes to attendance (same collection
//                            as the student's own scan).
// ScanMode.submission  -> scan matric QR when receiving the
//                         answer script -> examSubmissions.
//
// For now both only open the camera (no session is picked).
//

enum ScanMode { attendance, submission }

class InvigilatorScannerPage extends StatefulWidget {
  final ScanMode mode;

  const InvigilatorScannerPage({super.key, required this.mode});

  @override
  State<InvigilatorScannerPage> createState() => _InvigilatorScannerPageState();
}

class _InvigilatorScannerPageState extends State<InvigilatorScannerPage> {
  bool get isAttendance => widget.mode == ScanMode.attendance;

  // For now the scanner only opens the camera.
  void handleQRCode(BarcodeCapture capture) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAttendance ? 'Scan Student Attendance' : 'Scan Submission',
        ),
      ),
      body: ScannerFrame(
        onDetect: handleQRCode,
        message: isAttendance
            ? 'Place the student matriculation QR code inside the box.'
            : 'Place the student QR code inside the box.',
        messageAtBottom: true,
      ),
    );
  }
}

// =====================================================
// SCAN RESULT PAGE (invigilator)
// =====================================================

class ScanResultPage extends StatelessWidget {
  final ExamSession session;
  final String studentId;
  final ScanMode mode;
  final bool alreadyRecorded;
  final dynamic time;

  const ScanResultPage({
    super.key,
    required this.session,
    required this.studentId,
    required this.mode,
    required this.alreadyRecorded,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isAttendance = mode == ScanMode.attendance;

    final heading = isAttendance
        ? 'Student Attendance Recorded'
        : 'Answer Script Received';

    final subtitle = alreadyRecorded
        ? (isAttendance
            ? 'This student was already checked in for this session.'
            : 'This student\'s script was already recorded for this session.')
        : (isAttendance
            ? 'Attendance has been saved to the database.'
            : 'The student examination submission has been recorded.');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAttendance ? 'Attendance Recorded' : 'Examination Submitted',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              alreadyRecorded
                  ? Icons.info_outline
                  : (isAttendance
                      ? Icons.check_circle
                      : Icons.assignment_turned_in),
              size: 100,
              color: alreadyRecorded ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    InfoRow('Student ID', studentId),
                    const Divider(),
                    InfoRow('Session', session.title),
                    const Divider(),
                    InfoRow(
                      'Method',
                      isAttendance ? 'Matriculation QR' : 'Script submission',
                    ),
                    if (alreadyRecorded) ...[
                      const Divider(),
                      InfoRow('First recorded', formatTimestamp(time)),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Scan Next Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// QR HELPER FUNCTIONS
// =====================================================

String getQRValue(String qrData, String key) {
  final lines = qrData.split('\n');

  for (final rawLine in lines) {
    final line = rawLine.trim();

    if (line.startsWith('$key=')) {
      return line.substring(key.length + 1).trim();
    }
  }

  return 'Unknown';
}

// =====================================================
// STUDENT ID EXTRACTION
// =====================================================
//
// The matriculation QR may contain:
//
// studentId=ABC12345
// OR matricNo=ABC12345
// OR simply the matriculation number as the QR value.
//
// IDs are normalised to upper case so they always match the
// matricNo saved at registration.
//

String extractStudentId(String qrData) {
  final studentId = getQRValue(qrData, 'studentId');

  if (studentId != 'Unknown' && studentId.isNotEmpty) {
    return studentId.toUpperCase();
  }

  final matricNo = getQRValue(qrData, 'matricNo');

  if (matricNo != 'Unknown' && matricNo.isNotEmpty) {
    return matricNo.toUpperCase();
  }

  return qrData.trim().toUpperCase();
}
