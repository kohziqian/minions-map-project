import 'package:flutter/material.dart';

import '../../models/scan_mode.dart';
import '../exams/exam_sessions_page.dart';
import '../scanner/invigilator_scanner_page.dart';
import '../widgets/profile_icon_button.dart';

class InvigilatorHomePage extends StatelessWidget {
  final String userName;

  const InvigilatorHomePage({super.key, required this.userName});

  void _openScanner(BuildContext context, ScanMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvigilatorScannerPage(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExamGuard - Invigilator'),
        actions: const [ProfileIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Manage examination sessions'),
              const SizedBox(height: 30),

              // EXAM SESSIONS (select a session to display its QR code)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Exam Sessions'),
                  subtitle: const Text(
                    'Select a session to display its attendance QR code',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExamSessionsPage(),
                      ),
                    );
                  },
                ),
              ),

              // SCAN STUDENT ATTENDANCE
              Card(
                child: ListTile(
                  leading: const Icon(Icons.how_to_reg),
                  title: const Text('Scan Student Attendance'),
                  subtitle: const Text(
                    'Scan matriculation QR if student does not have a phone',
                  ),
                  onTap: () => _openScanner(context, ScanMode.attendance),
                ),
              ),

              // SCAN EXAMINATION
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text('Scan Submission'),
                  subtitle: const Text(
                    'Scan student matric QR when receiving the answer script',
                  ),
                  onTap: () => _openScanner(context, ScanMode.submission),
                ),
              ),

              // ATTENDANCE LIST
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Student Attendance'),
                  subtitle: const Text('View student attendance'),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
