import 'package:flutter/material.dart';

import '../../core/utils/date_format.dart';
import '../../models/exam_session.dart';
import '../../models/scan_mode.dart';
import '../widgets/info_row.dart';

// Invigilator after scanning a student
// Not implemented yet (the invigilator scanner only opens camera)

class ScanResultPage extends StatelessWidget {
  final ExamSession session;
  final String studentId;
  final ScanMode mode;
  final bool alreadyRecorded;
  final DateTime? time;

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
