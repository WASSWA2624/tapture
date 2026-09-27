import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/agenda_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';

void main() {
  final DateTime started = DateTime.utc(2026, 9, 27, 9, 30);
  final DateTime ended = DateTime.utc(2026, 9, 27, 10, 15);
  final DateTime due = DateTime.utc(2026, 10, 1);

  Meeting sample() {
    return Meeting(
      id: 'm1',
      projectId: 'p1',
      title: 'Kick-off',
      startedAt: started,
      endedAt: ended,
      location: 'Site A',
      secretary: 'Ada',
      recordId: 'r1',
      agenda: const <AgendaEntry>[
        AgendaEntry(id: 'g1', title: 'Welcome', notes: 'Opened.'),
      ],
      attendees: const <Attendee>[
        Attendee(id: 'a1', name: 'Ada', title: 'Chair', organisation: 'Acme'),
        Attendee(
          id: 'a2',
          name: 'Ben',
          status: AttendanceStatus.apology,
          contact: 'ben@example.com',
          suggestedStaffId: 's1',
          matchScore: 0.9,
        ),
      ],
      decisions: const <Decision>[
        Decision(id: 'd1', text: 'Adopt the plan', source: 'Adopt the plan'),
      ],
      actions: <ActionEntry>[
        ActionEntry(
          id: 'c1',
          text: 'Send the minutes',
          ownerId: 'a1',
          ownerName: 'Ada',
          due: due,
          status: ActionStatus.done,
          source: 'Send the minutes',
        ),
      ],
      attachmentIds: const <String>['file-1'],
    );
  }

  test('every attribute round-trips', () {
    final Meeting meeting = sample();
    final Meeting back = Meeting.fromJson(meeting.toJson());
    expect(back, meeting);
    expect(back.attendanceCount, 1);
    expect(back.actionRegister.single['owner'], 'Ada');
    expect(back.actionRegister.single['status'], 'done');
    expect(back.exportBlocks(requireOwner: true), isEmpty);
  });

  test(
    'an apology is not attendance and an ownerless action blocks export',
    () {
      final Meeting meeting = sample().copyWith(
        actions: const <ActionEntry>[
          ActionEntry(id: 'c2', text: 'Book the room'),
        ],
      );
      expect(meeting.attendanceCount, 1);
      expect(meeting.exportBlocks(requireOwner: true), <String>[
        'Book the room',
      ]);
      expect(meeting.exportBlocks(requireOwner: false), isEmpty);
    },
  );
}
