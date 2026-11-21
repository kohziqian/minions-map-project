import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exam_session.dart';
import '../../viewmodels/session_viewmodel.dart';

/// Shows loading / error / empty states, then calls [builder] with the
/// exam sessions held by [SessionViewModel].
class ExamSessionsBody extends StatelessWidget {
  final String emptyMessage;
  final String errorPrefix;
  final Widget Function(BuildContext context, List<ExamSession> sessions)
      builder;

  const ExamSessionsBody({
    super.key,
    this.emptyMessage = 'No exam sessions available.',
    this.errorPrefix = 'Could not load exam sessions.',
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SessionViewModel>();

    if (vm.sessionsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$errorPrefix\n${vm.sessionsError}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return builder(context, vm.sessions);
  }
}
