import '../core/utils/qr_codec.dart';
import '../models/exam_session.dart';
import '../models/record_result.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/exam_service.dart';
import '../services/service_exception.dart';
import '../services/user_service.dart';
import 'base_viewmodel.dart';

// Not implemented yet
enum StudentScanStatus { ignored, invalidQr, noStudentId, error, success }

// After the student scanned a QR code
class StudentScanOutcome {
  final StudentScanStatus status;
  final String? message;      // for invalidQr/noStudentId /error
  final ExamSession? session; // for success
  final RecordResult? result; // for success

  const StudentScanOutcome._(
    this.status, {
    this.message,
    this.session,
    this.result,
  });

  const StudentScanOutcome.ignored() : this._(StudentScanStatus.ignored);

  const StudentScanOutcome.failed(StudentScanStatus status, String message)
      : this._(status, message: message);

  const StudentScanOutcome.success(ExamSession session, RecordResult result)
      : this._(
          StudentScanStatus.success,
          session: session,
          result: result,
        );
}

// Student scans the exam QR containing session id
// The session id loads details from Firestore, the student's name and matric number come from their profile
class ScannerViewModel extends BaseViewModel {
  final AuthService _auth;
  final UserService _users;
  final ExamService _exams;
  final AttendanceService _attendance;

  ScannerViewModel({
    required AuthService auth,
    required UserService users,
    required ExamService exams,
    required AttendanceService attendance,
  })  : _auth = auth,
        _users = users,
        _exams = exams,
        _attendance = attendance;

  bool _busy = false;

  // Call when the scanner page opens
  void reset() => _busy = false;

  // Camera fires many times per second; only handle one scan at a time.
  void _releaseAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () => _busy = false);
  }

  Future<StudentScanOutcome> scanStudentQr(List<String> rawValues) async {
    if (_busy) return const StudentScanOutcome.ignored();

    for (final value in rawValues) {
      if (value.isEmpty) continue;

      final sessionId = getQRValue(value, 'sessionId');

      if (sessionId == 'Unknown' ||
          sessionId.isEmpty ||
          sessionId.contains('/')) {
        continue;
      }

      _busy = true;

      final uid = _auth.currentUid;

      if (uid == null) {
        _busy = false;
        return const StudentScanOutcome.ignored();
      }

      try {
        // 1. Load the session from the database.
        final session = await _exams.getSession(sessionId);

        if (session == null) {
          _releaseAfterDelay();
          return const StudentScanOutcome.failed(
            StudentScanStatus.invalidQr,
            'Invalid exam QR code.',
          );
        }

        // 2. Load the student's profile (name + matric number).
        final profile = await _users.getUser(uid);
        final matricNo = (profile?.matricNo ?? '').trim();
        final fullName = (profile?.fullName ?? '').trim();

        if (matricNo.isEmpty) {
          _releaseAfterDelay();
          return const StudentScanOutcome.failed(
            StudentScanStatus.noStudentId,
            'Your profile has no Student ID. Contact the admin.',
          );
        }

        // 3. Record attendance (duplicate-safe).
        final result = await _attendance.recordAttendance(
          sessionId: sessionId,
          studentId: matricNo,
          studentName:
              fullName.isEmpty ? (_auth.currentEmail ?? 'Student') : fullName,
          method: 'Student QR',
          recordedBy: uid,
        );

        // _busy = true: the page is replaced by the success page
        return StudentScanOutcome.success(session, result);
      } on ServiceException catch (e) {
        _busy = false;
        return StudentScanOutcome.failed(
          StudentScanStatus.error,
          'Could not record attendance: ${e.message}',
        );
      }
    }

    return const StudentScanOutcome.ignored();
  }
}
