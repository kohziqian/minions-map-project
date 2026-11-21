import 'dart:async';

import '../core/utils/qr_codec.dart';
import '../models/exam_session.dart';
import '../services/attendance_service.dart';
import 'base_viewmodel.dart';

// The invigilator's exam QR page (QR text & live check-in count)
class ExamViewModel extends BaseViewModel {
  final AttendanceService _attendance;
  StreamSubscription<int>? _sub;

  int _attendanceCount = 0;

  ExamViewModel(this._attendance);

  int get attendanceCount => _attendanceCount;

// QR code only contains session id
// Session id is document in Firestore, contains exam details
  String qrDataFor(ExamSession session) => sessionQrData(session.sessionId);

  // Call from the page's initState.
  void startWatchingAttendance(String sessionId) {
    _sub?.cancel();
    _attendanceCount = 0;
    _sub = _attendance.watchAttendanceCount(sessionId).listen(
      (n) {
        _attendanceCount = n;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // Call from the page's dispose.
  void stopWatchingAttendance() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
