import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/presentation/meeting_attachments.dart';

import '../pump.dart';

void main() {
  testWidgets('lists kind and size and opens', (WidgetTester tester) async {
    String? opened;
    await pumpMeeting(
      tester,
      MeetingAttachments(
        files: const <MeetingFile>[
          (id: 'f1', name: 'Agenda.pdf', kind: 'agenda', bytes: 1200),
        ],
        onOpen: (String id) => opened = id,
      ),
    );
    expect(find.text('agenda · 1200 B'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('attachment-f1')));
    await tester.pump();
    expect(opened, 'f1');
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, MeetingAttachments(onAdd: () {}));
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.meetingAddAttachment), findsOneWidget);
    await pumpMeeting(tester, const MeetingAttachments(failure: meetingFailed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
