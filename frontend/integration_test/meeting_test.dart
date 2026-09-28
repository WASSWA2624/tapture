import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/pdf/minutes_report.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';

import '../test/support/matchers.dart';
import 'support/harness.dart';

void main() {
  test(
    'approved attendance and minutes export offline, and a discarded name is absent',
    () async {
      final TestApp app = await bootTestApp();
      addTearDown(app.dispose);
      app.backend.markUnreachable();
      const String transcript = 'We agreed to paint the gate.';
      final Meeting proposed = Meeting(
        id: 'meeting-1',
        projectId: 'project-1',
        title: 'Site meeting',
        startedAt: app.clock.nowUtc(),
        location: 'Yard',
        attendees: const <Attendee>[
          Attendee(id: 'person-1', name: 'Ada', suggestedStaffId: 'staff-1'),
        ],
      );
      expect(proposed.attendees.single.staffId, isNull);
      MeetingRecord stored = valueOf(
        await app.meetings.save(
          proposed.copyWith(
            attendees: const <Attendee>[
              Attendee(id: 'person-1', name: 'Ada', staffId: 'staff-1'),
            ],
          ),
          recordId: 'record-meeting',
          transcript: transcript,
          minutes: '',
        ),
      );
      expect(stored.transcript, transcript);
      expect(stored.meeting.attendees.single.name, 'Ada');
      stored = valueOf(
        await app.meetings.save(
          stored.meeting.copyWith(
            attendees: const <Attendee>[
              Attendee(
                id: 'person-1',
                name: 'Ada Lovelace',
                staffId: 'staff-1',
              ),
              Attendee(id: 'person-2', name: 'Grace', staffId: 'staff-2'),
            ],
            decisions: const <Decision>[
              Decision(id: 'd1', text: 'Paint the gate'),
            ],
          ),
          recordId: 'record-meeting',
          minutes: 'Paint the gate.',
        ),
      );
      expect(stored.transcript, transcript);
      expect(
        stored.meeting.attendees.map((Attendee person) => person.name),
        containsAll(<String>['Ada Lovelace', 'Grace']),
      );
      final Meeting discarded = stored.meeting.copyWith(
        attendees: <Attendee>[stored.meeting.attendees.first],
      );
      stored = valueOf(
        await app.meetings.save(
          discarded,
          recordId: 'record-meeting',
          minutes: stored.minutes,
        ),
      );
      expect(
        stored.meeting.attendees.any(
          (Attendee person) => person.name == 'Grace',
        ),
        isFalse,
      );
      final PdfDocument pdf = MinutesReport.build(
        engine: const PdfEngine(),
        project: 'Field',
        attendance: <String>[stored.meeting.attendees.single.name],
        agenda: <MinutesSection>[
          (
            title: stored.meeting.title,
            raw: stored.transcript,
            refined: stored.minutes,
            decisions: <String>[stored.meeting.decisions.single.text],
            actions: const <String>[],
          ),
        ],
        photos: const <({String caption, String path})>[],
      );
      expect(pdf.bodyLines.join('\n'), contains('Ada Lovelace'));
      expect(pdf.bodyLines.join('\n'), contains('Paint the gate'));
      expect(pdf.bodyLines.join('\n'), contains(transcript));
      expect(app.outboundCallCount, 0);
    },
  );
}
