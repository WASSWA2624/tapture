import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_transcription.dart';
import 'package:tapture/features/meetings/meetings.dart'
    show MeetingLiveSection, meetingRepositoryProvider;
import 'package:tapture/features/meetings/presentation/meeting_review_screen.dart';
import 'package:tapture/features/settings/settings.dart'
    show OperatorProfile, currentOperatorProvider;
import 'package:tapture/features/transcripts/transcripts.dart';

import '../../../support/fakes/fake_live_transcription_service.dart';
import '../../../support/fakes/fake_speech_engine.dart';
import '../../transcripts/fakes/fake_transcript_repository.dart';
import '../../transcripts/presentation/transcript_screens.dart'
    show speechHostOverride;
import '../fakes/fake_meeting_repository.dart';
import '../meeting_live_harness.dart';
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

  group('opened by id', () {
    late FakeMeetingRepository meetings;
    late FakeTranscriptRepository repository;
    late FakeLiveTranscriptionService service;
    late FakeSpeechEngine engine;
    late LifecycleObserver lifecycle;

    setUp(() {
      meetings = FakeMeetingRepository();
      repository = FakeTranscriptRepository();
      service = FakeLiveTranscriptionService();
      engine = FakeSpeechEngine();
      lifecycle = LifecycleObserver.fake();
    });

    tearDown(() async {
      await repository.dispose();
      await service.dispose();
      await engine.dispose();
      lifecycle.dispose();
    });

    Future<GoRouter> pumpById(WidgetTester tester, {String? id}) {
      return pumpMeetingRoutes(
        tester,
        page: (String meetingId, String projectId) => MeetingReviewScreen(
          meetingId: id ?? meetingId,
          projectId: projectId,
          requireActionDetails: true,
        ),
        overrides: <Override>[
          meetingRepositoryProvider.overrideWithValue(meetings),
          transcriptRepositoryProvider.overrideWithValue(repository),
          liveTranscriptionServiceProvider.overrideWithValue(service),
          leaveGuardProvider.overrideWithValue(LeaveGuard.fake()),
          lifecycleObserverProvider.overrideWithValue(lifecycle),
          speechHostOverride(engine, lifecycle, ready: true),
          speechLanguageProvider.overrideWithValue('en'),
          currentOperatorProvider.overrideWithValue(
            const OperatorProfile(name: 'Ada', initials: 'AL'),
          ),
        ],
      );
    }

    testWidgets('the review route loads the meeting by id, records it live '
        'after its summary, lists its transcripts and online runs as one list, and a '
        'transcript opens in the editor', (WidgetTester tester) async {
      meetings.seed(
        aLiveMeeting(),
        notes: 'raw notes',
        transcript: 'we agreed to fence the reservoir',
        versions: const <TranscriptVersion>[
          (version: 1, text: 'cloud words', failedChunks: <int>[]),
        ],
      );
      repository.seed(
        aMeetingTranscript(id: 't1', preview: 'we agreed'),
        lines: const <TranscriptLine>[
          TranscriptLine(
            seq: 1,
            start: Duration.zero,
            end: Duration(seconds: 2),
            text: 'we agreed to fence the reservoir',
          ),
        ],
      );
      final GoRouter router = await pumpById(tester);

      expect(
        find.byKey(const ValueKey<String>('route-meeting-review')),
        findsOneWidget,
      );
      final Finder live = find.byType(MeetingLiveSection);
      expect(live, findsOneWidget);
      expect(
        tester.getTopLeft(live).dy,
        greaterThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey<String>('meeting-attendance-count')),
              )
              .dy,
        ),
        reason: 'the summary precedes recording controls',
      );
      expect(
        find.byKey(const ValueKey<String>('recording-bar-start')),
        findsOneWidget,
      );
      expect(
        find.text('we agreed to fence the reservoir'),
        findsOneWidget,
        reason: "the meeting's transcript is shown",
      );
      final Finder row = find.byKey(
        const ValueKey<String>('transcript-row-t1'),
      );
      final Finder cloud = find.byKey(
        const ValueKey<String>('audio-version-1'),
      );
      expect(row, findsOneWidget);
      expect(cloud, findsOneWidget);
      expect(find.text(Copy.liveTranscriptListTitle), findsOneWidget);
      expect(tester.getTopLeft(row).dy, lessThan(tester.getTopLeft(cloud).dy));

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        router.state.uri.path,
        RoutePaths.projectTranscript(liveMeetingProject, 't1'),
      );
      expect(find.byType(TranscriptEditor), findsOneWidget);
    });

    testWidgets('edits survive rebuild, resize, failure and reopen', (
      WidgetTester tester,
    ) async {
      meetings.seed(aLiveMeeting(), notes: 'source', minutes: 'before');
      final GoRouter router = await pumpById(tester);
      final Finder notes = find.descendant(
        of: find.byKey(const ValueKey<String>('meeting-notes')),
        matching: find.byType(TextField),
      );
      final Finder minutes = find.descendant(
        of: find.byKey(const ValueKey<String>('meeting-minutes')),
        matching: find.byType(TextField),
      );
      await tester.enterText(notes, 'edited notes');
      await tester.pumpAndSettle();
      meetings.saveFailure = meetingFailed;
      await tester.enterText(minutes, 'edited minutes');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('meeting-retry-save')),
        findsOneWidget,
      );
      final EditableText before = tester.widget<EditableText>(
        find.descendant(of: minutes, matching: find.byType(EditableText)),
      );
      before.controller.selection = const TextSelection.collapsed(offset: 3);
      expect(before.focusNode.hasFocus, isTrue);
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(minutes).controller!.text,
        'edited minutes',
      );
      final EditableText after = tester.widget<EditableText>(
        find.descendant(of: minutes, matching: find.byType(EditableText)),
      );
      expect(after.controller, same(before.controller));
      expect(after.controller.selection.baseOffset, 3);
      expect(after.focusNode.hasFocus, isTrue);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('route-meeting-review')),
        findsOneWidget,
      );
      meetings.saveFailure = null;
      final Finder retry = find.byKey(
        const ValueKey<String>('meeting-retry-save'),
      );
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(meetings.records[liveMeetingId]!.notes, 'edited notes');
      expect(meetings.records[liveMeetingId]!.minutes, 'edited minutes');
      expect(meetings.records[liveMeetingId]!.originalNotes, 'source');
      router.go(RoutePaths.projects);
      await tester.pumpAndSettle();
      router.go(
        RoutePaths.projectMeetingReview(liveMeetingProject, liveMeetingId),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(notes).controller!.text, 'edited notes');
      expect(
        tester.widget<TextField>(minutes).controller!.text,
        'edited minutes',
      );
    });

    testWidgets('a meeting not on this device is the empty state', (
      WidgetTester tester,
    ) async {
      await pumpById(tester, id: 'gone');
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text(Copy.meetingReviewEmpty), findsOneWidget);
      expect(find.byType(MeetingLiveSection), findsNothing);
    });

    testWidgets('a failed read shows the error', (WidgetTester tester) async {
      meetings.readFailure = meetingFailed;
      await pumpById(tester);
      expect(find.byType(AppErrorState), findsOneWidget);
    });
  });
}
