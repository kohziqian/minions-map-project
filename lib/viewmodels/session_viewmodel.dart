import 'dart:async';

import '../models/exam_session.dart';
import '../services/auth_service.dart';
import '../services/exam_service.dart';
import 'base_viewmodel.dart';

// Student's "My Examinations" page
class StudentExamGroups {
  final List<ExamSession> today;
  final List<ExamSession> upcoming;
  final List<ExamSession> completed;

  const StudentExamGroups(this.today, this.upcoming, this.completed);
}

// Invigilator's "Exam Sessions" page
class InvigilatorExamGroups {
  final List<ExamSession> upcoming; // not finished
  final List<ExamSession> past;     // finished
  final List<ExamSession> undated;  // missing date

  const InvigilatorExamGroups(this.upcoming, this.past, this.undated);
}

// Live list of exam sessions
// Starts listen when someone signs in, stops when they sign out
class SessionViewModel extends BaseViewModel {
  final ExamService _exams;
  final AuthService _auth;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<List<ExamSession>>? _sessionsSub;
  StreamSubscription<int>? _countSub;

  List<ExamSession> _sessions = const [];
  bool _loaded = false;
  String? _sessionsError;
  int? _studentCount;

  SessionViewModel(this._exams, this._auth) {
    _authSub = _auth.uidChanges.listen(_onUidChanged);
  }

  List<ExamSession> get sessions => _sessions;

  // False until the first snapshot (or error) has arrived
  bool get loaded => _loaded;

  String? get sessionsError => _sessionsError;

  // Number of registered students; null until loaded
  int? get studentCount => _studentCount;

  void _onUidChanged(String? uid) {
    _sessionsSub?.cancel();
    _sessionsSub = null;
    _countSub?.cancel();
    _countSub = null;

    _sessions = const [];
    _loaded = false;
    _sessionsError = null;
    _studentCount = null;

    if (uid != null) {
      _sessionsSub = _exams.watchSessions().listen(
        (list) {
          _sessions = list;
          _loaded = true;
          _sessionsError = null;
          notifyListeners();
        },
        onError: (Object e) {
          _sessionsError = e.toString();
          _loaded = true;
          notifyListeners();
        },
      );
    }

    notifyListeners();
  }

  // Used by the invigilator's session list 
  // Displays "Registered students: x"
  // Call from initState; stop from dispose
  void startWatchingStudentCount() {
    _countSub?.cancel();
    _studentCount = null;
    _countSub = _exams.watchStudentCount().listen(
      (n) {
        _studentCount = n;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void stopWatchingStudentCount() {
    _countSub?.cancel();
    _countSub = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _sessionsSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }

  // Sorting by date
  // Undated sessions placed last
  int compare(ExamSession a, ExamSession b) {
    final ad = a.day;
    final bd = b.day;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    final c = ad.compareTo(bd);
    return c != 0 ? c : a.startMinutes.compareTo(b.startMinutes);
  }

  StudentExamGroups groupForStudent() {
    final today = <ExamSession>[];
    final upcoming = <ExamSession>[];
    final completed = <ExamSession>[];

    for (final s in _sessions) {
      if (s.date == null) continue; // cannot be placed in time
      if (s.isToday) {
        today.add(s);
      } else if (s.isCompleted) {
        completed.add(s);
      } else {
        upcoming.add(s);
      }
    }

    today.sort(compare);
    upcoming.sort(compare);
    // most recently finished first
    completed.sort((a, b) => compare(b, a));

    return StudentExamGroups(today, upcoming, completed);
  }

  InvigilatorExamGroups groupForInvigilator() {
    final dated = _sessions.where((s) => s.date != null).toList();
    final undated = _sessions.where((s) => s.date == null).toList();

    final upcoming = dated.where((s) => !s.isCompleted).toList()
      ..sort(compare);
    final past = dated.where((s) => s.isCompleted).toList()..sort(compare);

    return InvigilatorExamGroups(upcoming, past, undated);
  }
}
