import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/presentation/meeting_review_screen.dart';

import '../pump.dart';

void main() {
  final DateTime due = DateTime.utc(2026, 10, 1);

  Meeting complete() {
    return Meeting(
      id: 'm1',
      projectId: 'p1',
      title: 'Kick-off',
      startedAt: DateTime.utc(2026, 9, 27, 9),
      recordId: 'r1',
      attendees: const <Attendee>[
        Attendee(id: 'a1', name: 'Ada'),
        Attendee(id: 'a2', name: 'Ben', status: AttendanceStatus.apology),
      ],
      decisions: const <Decision>[Decision(id: 'd1', text: 'Adopt the plan')],
      actions: <ActionEntry>[
        ActionEntry(
          id: 'c1',
          text: 'Send the minutes',
          ownerId: 'a1',
          ownerName: 'Ada',
          due: due,
        ),
      ],
    );
  }

  testWidgets('a complete meeting can be approved', (
    WidgetTester tester,
  ) async {
    var approved = false;
    await pumpMeeting(
      tester,
      MeetingReviewScreen(
        meeting: complete(),
        notes: 'raw',
        minutes: 'refined',
        transcript: 'verbatim',
        requireActionDetails: true,
        onApprove: () => approved = true,
      ),
    );
    expect(find.text(Copy.meetingAttendanceCount(1)), findsOneWidget);
    expect(find.text('verbatim'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('meeting-notes')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('meeting-minutes')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('meeting-approve')));
    await tester.pump();
    expect(approved, isTrue);
  });

  testWidgets('an ownerless action blocks approval and names it', (
    WidgetTester tester,
  ) async {
    var approved = false;
    await pumpMeeting(
      tester,
      MeetingReviewScreen(
        meeting: complete().copyWith(
          actions: const <ActionEntry>[
            ActionEntry(id: 'c2', text: 'Book the room'),
          ],
        ),
        requireActionDetails: true,
        onApprove: () => approved = true,
      ),
    );
    expect(
      find.text(Copy.meetingActionBlocked('Book the room')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey<String>('meeting-approve')),
          )
          .onPressed,
      isNull,
    );
    expect(approved, isFalse);
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const MeetingReviewScreen());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(
      tester,
      const MeetingReviewScreen(failure: meetingFailed),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
