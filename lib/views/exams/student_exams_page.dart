import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/exam_session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../widgets/exam_meta_row.dart';
import '../widgets/exam_sessions_body.dart';
import '../widgets/section_header.dart';

// My Examinations list (Student)
// Grouped by Today / Upcoming / Completed
class StudentExamsPage extends StatelessWidget {
  const StudentExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Examinations')),
      body: ExamSessionsBody(
        emptyMessage: 'No examination sessions scheduled.',
        errorPrefix: 'Could not load examinations.',
        builder: (context, sessions) {
          final groups = context.read<SessionViewModel>().groupForStudent();

          final children = <Widget>[];

          void addSection(String label, List<ExamSession> list,
              {bool dimmed = false}) {
            if (list.isEmpty) return;
            children.add(SectionHeader(label));
            for (final s in list) {
              children.add(_examCard(s, dimmed: dimmed));
            }
          }

          addSection('Today', groups.today);
          addSection('Upcoming', groups.upcoming);
          addSection('Completed', groups.completed, dimmed: true);

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
