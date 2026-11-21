import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/record_result.dart';
import 'service_exception.dart';

/// Writes attendance/{sessionId}_{studentId} and
/// examSubmissions/{sessionId}_{studentId}.
class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DateTime? _toDate(dynamic value) =>
      value is Timestamp ? value.toDate() : null;

  Future<RecordResult> recordAttendance({
    required String sessionId,
    required String studentId,
    required String studentName,
    required String method, // 'Student QR' | 'Matriculation QR'
    String? recordedBy,
  }) =>
      guardFirebase(() async {
        final ref =
            _db.collection('attendance').doc('${sessionId}_$studentId');

        final existing = await ref.get();

        if (existing.exists) {
          return RecordResult(
            created: false,
            time: _toDate(existing.data()?['checkInTime']),
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
      });

  Future<RecordResult> recordSubmission({
    required String sessionId,
    required String studentId,
    required String studentQrData,
    String? recordedBy,
  }) =>
      guardFirebase(() async {
        final ref =
            _db.collection('examSubmissions').doc('${sessionId}_$studentId');

        final existing = await ref.get();

        if (existing.exists) {
          return RecordResult(
            created: false,
            time: _toDate(existing.data()?['submissionTime']),
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
      });

  /// Live number of students who have checked in to a session
  /// (QR scans AND invigilator scans use the same collection).
  Stream<int> watchAttendanceCount(String sessionId) => _db
      .collection('attendance')
      .where('sessionId', isEqualTo: sessionId)
      .snapshots()
      .map((snap) => snap.docs.length);
}
