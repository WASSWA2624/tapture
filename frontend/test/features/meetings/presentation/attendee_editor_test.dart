import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/presentation/attendee_editor.dart';

import '../pump.dart';

void main() {
  testWidgets('a present person counts and an apology does not', (
    WidgetTester tester,
  ) async {
    List<Attendee> people = const <Attendee>[
      Attendee(id: 'a1', name: 'Ada'),
      Attendee(id: 'a2', name: 'Ben', status: AttendanceStatus.apology),
    ];
    await pumpMeeting(
      tester,
      AttendeeEditor(
        people: people,
        onChanged: (List<Attendee> next) => people = next,
      ),
    );
    expect(find.text(Copy.meetingAttendanceCount(1)), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
  });

  testWidgets('a staff suggestion is linked only when accepted', (
    WidgetTester tester,
  ) async {
    List<Attendee> people = const <Attendee>[
      Attendee(id: 'a1', name: 'Ada', suggestedStaffId: 's1', matchScore: 0.9),
    ];
    await pumpMeeting(
      tester,
      AttendeeEditor(
        people: people,
        onChanged: (List<Attendee> next) => people = next,
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('attendee-staff-a1')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey<String>('attendee-link-a1')));
    await tester.pump();
    expect(people.single.staffId, 's1');
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const AttendeeEditor());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(tester, const AttendeeEditor(failure: meetingFailed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
