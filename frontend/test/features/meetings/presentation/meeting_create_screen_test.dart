import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/presentation/meeting_create_screen.dart';

import '../pump.dart';

void main() {
  testWidgets('a prefilled header starts with one tap', (
    WidgetTester tester,
  ) async {
    Meeting? started;
    await pumpMeeting(
      tester,
      MeetingCreateScreen(
        projectId: 'p1',
        startedAt: DateTime.utc(2026, 9, 27, 9, 5),
        location: 'Site A',
        secretary: 'Ada',
        onStart: (Meeting meeting) => started = meeting,
      ),
    );
    expect(find.text('2026-09-27'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('Site A'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('meeting-start')));
    await tester.pump();
    expect(started?.title, Copy.meetingStartedTitle(DateTime.utc(2026, 9, 27)));
    expect(started?.location, 'Site A');
    expect(started?.secretary, 'Ada');
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const MeetingCreateScreen());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(
      tester,
      const MeetingCreateScreen(failure: meetingFailed),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
