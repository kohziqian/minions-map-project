import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/date_format.dart';
import '../../models/exam_session.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../widgets/exam_meta_row.dart';
import '../widgets/exam_sessions_body.dart';
import '../widgets/section_header.dart';
import 'exam_qr_page.dart';

// Exam Sessions list (invigilator)
// Grouped by date, sorted by time
// Upcoming session displays the exam QR code
// Completed sessions cannot display

class ExamSessionsPage extends StatefulWidget {
  final String title;
  final IconData trailingIcon;

  const ExamSessionsPage({
    super.key,
    this.title = 'Exam Sessions',
    this.trailingIcon = Icons.qr_code,
  });

  @override
  State<ExamSessionsPage> createState() => _ExamSessionsPageState();
}

class _ExamSessionsPageState extends State<ExamSessionsPage> {
  late final SessionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<SessionViewModel>();
    _vm.startWatchingStudentCount();
  }

  @override
  void dispose() {
    _vm.stopWatchingStudentCount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ExamSessionsBody(
        builder: (context, sessions) {
          final groups = _vm.groupForInvigilator();

          final children = <Widget>[];

          void addGroup(List<ExamSession> list, {required bool isPast}) {
            DateTime? lastDay;
            String? lastSlot;

            for (final s in list) {
              if (s.day != lastDay) {
                children.add(SectionHeader(formatLongDate(s.day!)));
                lastDay = s.day;
                lastSlot = null;
              }

              if (s.formattedTime != lastSlot) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(s.formattedTime, style: kSubSectionStyle),
                  ),
                );
                lastSlot = s.formattedTime;
              }

              children.add(_sessionCard(context, s, isPast: isPast));
            }
          }

          addGroup(groups.upcoming, isPast: false);

          if (groups.past.isNotEmpty) {
            children.add(const SectionHeader('Completed sessions'));
            addGroup(groups.past, isPast: true);
          }

          if (groups.undated.isNotEmpty) {
            children.add(const SectionHeader('Date not set'));
            for (final s in groups.undated) {
              children.add(_sessionCard(context, s, isPast: false));
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: children,
          );
        },
      ),
    );
  }

  Widget _sessionCard(BuildContext context, ExamSession s,
      {required bool isPast}) {
    // Only upcoming sessions open the QR.
    final enabled = !isPast;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: !enabled
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamQRPage(session: s),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: kCardTitleStyle),
                      ExamMetaRow(
                        icon: Icons.access_time,
                        text: s.formattedTime,
                      ),
                      ExamMetaRow(
                        icon: Icons.location_on_outlined,
                        text: s.venue.isEmpty ? 'Hall not set' : s.venue,
                      ),
                      _RegisteredStudents(session: s),
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 12),
                  Icon(widget.trailingIcon),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Displays number of Registered students: x
class _RegisteredStudents extends StatelessWidget {
  final ExamSession session;

  const _RegisteredStudents({required this.session});

  @override
  Widget build(BuildContext context) {
    final fixed = session.registeredStudents;

    if (fixed != null) {
      return ExamMetaRow(
        icon: Icons.people_outline,
        text: 'Registered students: $fixed',
      );
    }

    final count =
        context.select<SessionViewModel, int?>((vm) => vm.studentCount);

    return ExamMetaRow(
      icon: Icons.people_outline,
      text: 'Registered students: ${count ?? '…'}',
    );
  }
}
