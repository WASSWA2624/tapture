import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/export/pdf/minutes_report.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/core/export/pdf/transcript_report.dart';
import 'package:tapture/features/exports/data/export_pdf.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';
import 'package:tapture/features/meetings/meetings.dart'
    show meetingRepositoryProvider, MeetingReviewScreen;
import 'package:tapture/features/meetings/presentation/meeting_review_controller.dart';
import 'package:tapture/features/transcripts/transcripts.dart';

import '../test/features/meetings/meeting_live_harness.dart';
import '../test/features/transcripts/fakes/fake_transcript_repository.dart';
import '../test/support/matchers.dart';
import 'support/harness.dart';

void main() {
  testWidgets(
    'production review route saves typed notes and minutes offline and reopens',
    (WidgetTester tester) async {
      final TestApp app = (await tester.runAsync(bootTestApp))!;
      addTearDown(app.dispose);
      final FakeTranscriptRepository transcripts = FakeTranscriptRepository();
      addTearDown(transcripts.dispose);
      app.backend.markUnreachable();
      await tester.runAsync(
        () => app.meetings.save(
          Meeting(
            id: 'review-1',
            projectId: 'project-1',
            title: 'Field review',
            startedAt: app.clock.nowUtc(),
          ),
          recordId: 'review-record',
          templateId: 'template-1',
          notes: 'Original evidence',
          minutes: 'Initial minutes',
          transcript: 'Verbatim source',
        ),
      );
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            networkOnlineOverride(),
            meetingRepositoryProvider.overrideWithValue(app.meetings),
            transcriptRepositoryProvider.overrideWithValue(transcripts),
          ],
          child: const TaptureApp(receiveIncomingBundles: false),
        ),
      );
      await tester.pumpAndSettle();
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(TaptureApp)),
      );
      container.read(openProjectIdProvider.notifier).open('project-1');
      final GoRouter router = container.read(routerProvider);
      final String path = RoutePaths.projectMeetingReview(
        'project-1',
        'review-1',
      );
      router.go(path);
      await settleUntil(
        tester,
        () =>
            find.byType(MeetingReviewScreen).evaluate().isNotEmpty &&
            find
                .byKey(const ValueKey<String>('meeting-notes'))
                .evaluate()
                .isNotEmpty,
      );
      final Finder notes = find.descendant(
        of: find.byKey(const ValueKey<String>('meeting-notes')),
        matching: find.byType(TextField),
      );
      final Finder minutes = find.descendant(
        of: find.byKey(const ValueKey<String>('meeting-minutes')),
        matching: find.byType(TextField),
      );
      await tester.enterText(notes, 'Working notes');
      await tester.enterText(minutes, 'Reviewed minutes');
      expect(
        await drive(
          tester,
          () => container
              .read(meetingReviewControllerProvider('review-1').notifier)
              .flush(),
        ),
        isTrue,
      );
      router.go(RoutePaths.projects);
      await tester.pumpAndSettle();
      router.go(path);
      await settleUntil(tester, () => notes.evaluate().isNotEmpty);
      expect(tester.widget<TextField>(notes).controller!.text, 'Working notes');
      expect(
        tester.widget<TextField>(minutes).controller!.text,
        'Reviewed minutes',
      );
      final MeetingRecord stored = (await drive(
        tester,
        () => app.meetings.read('review-1'),
      )).getOrThrow()!;
      expect(stored.originalNotes, 'Original evidence');
      expect(stored.transcript, 'Verbatim source');
      expect(app.outboundCallCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

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
        engine: exportPdfEngine(),
        project: 'Field',
        meeting: (
          title: stored.meeting.title,
          date: '',
          present: <String>[stored.meeting.attendees.single.name],
          apologies: const <String>[],
          agenda: <MinutesTopic>[(title: stored.meeting.title, notes: '')],
          rawNotes: stored.transcript,
          transcripts: const <TranscriptContent>[],
          refinedMinutes: stored.minutes,
          decisions: <String>[stored.meeting.decisions.single.text],
          actions: const <MinutesAction>[],
          photos: const <PdfPhoto>[],
        ),
      );
      expect(pdf.bodyLines.join('\n'), contains('Ada Lovelace'));
      expect(pdf.bodyLines.join('\n'), contains('Paint the gate'));
      expect(pdf.bodyLines.join('\n'), contains(transcript));
      expect(app.outboundCallCount, 0);
    },
  );
}
