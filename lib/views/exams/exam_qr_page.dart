import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/exam_session.dart';
import '../../viewmodels/exam_viewmodel.dart';

// Not implemented yet
// QR code only contains session id
// Session id is document in Firestore, contains exam details

class ExamQRPage extends StatefulWidget {
  final ExamSession session;

  const ExamQRPage({super.key, required this.session});

  @override
  State<ExamQRPage> createState() => _ExamQRPageState();
}

class _ExamQRPageState extends State<ExamQRPage> {
  late final ExamViewModel _vm;

  ExamSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ExamViewModel>();
    _vm.startWatchingAttendance(session.sessionId);
  }

  @override
  void dispose() {
    _vm.stopWatchingAttendance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _vm.qrDataFor(session);
    final count =
        context.select<ExamViewModel, int>((vm) => vm.attendanceCount);

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
                      _buildQrSection(qrData, qrSize),
                    ],
                  )
                else ...[
                  _buildExamDetailsCard(),
                  const SizedBox(height: 30),
                  _buildQrSection(qrData, qrSize),
                ],
                const SizedBox(height: 30),

                // Live count of students who have checked in
                // Student QR scans AND invigilator scans records to the same collection
                Text(
                  'Students: $count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildQrSection(String qrData, double qrSize) {
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
