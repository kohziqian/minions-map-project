import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exam_session.dart';
import 'service_exception.dart';

// Reads exam sessions examSessions{sessionId}
class ExamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ExamSession _toSession(DocumentSnapshot<Map<String, dynamic>> doc) {
    final s = doc.data() ?? {};
    final dateValue = s['date'];

    return ExamSession(
      sessionId: doc.id,
      courseCode: (s['courseCode'] ?? '').toString(),
      courseName: (s['courseName'] ?? '').toString(),
      venue: (s['venue'] ?? '').toString(),
      date: dateValue is Timestamp ? dateValue.toDate() : null,
      startTime: (s['startTime'] ?? '').toString(),
      endTime: (s['endTime'] ?? '').toString(),
      registeredStudents: (s['registeredStudents'] as num?)?.toInt(),
    );
  }

  Stream<List<ExamSession>> watchSessions() => _db
      .collection('examSessions')
      .snapshots()
      .map((snap) => snap.docs.map(_toSession).toList());

  // null when the session does not exists
  Future<ExamSession?> getSession(String sessionId) => guardFirebase(() async {
        final doc = await _db.collection('examSessions').doc(sessionId).get();
        return doc.exists ? _toSession(doc) : null;
      });

  // Number of users registered with role Student
  Stream<int> watchStudentCount() => _db
      .collection('users')
      .where('role', isEqualTo: 'Student')
      .snapshots()
      .map((snap) => snap.docs.length);
}
