import 'package:flutter/material.dart';

import '../../core/utils/date_format.dart';
import '../../models/exam_session.dart';
import '../widgets/info_row.dart';

// Shown to the student after a successful exam QR scan.
// Not implemented yet

class AttendanceSuccessPage extends StatelessWidget {
  final ExamSession session;
  final DateTime? checkInTime;
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
