import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/audio/audio_capture_plugin.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/audio/microphone_access.dart';
import 'package:tapture/core/audio/microphone_arbiter.dart';
import 'package:tapture/core/audio/staged_take_recovery.dart';
import 'package:tapture/core/audio/wav_header.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/core/widgets/app_transcript_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/features/meetings/meetings.dart'
    show
        MeetingAttachment,
        MeetingLiveSection,
        meetingRepositoryProvider,
        meetingTranscriptTargetProvider;
import 'package:tapture/features/transcripts/transcripts.dart';

import '../../../support/fakes/fake_live_transcription_service.dart';
import '../../../support/fakes/fake_record_recorder.dart';
import '../../../support/fakes/fake_speech_engine.dart';
import '../../../support/live_transcription_rig.dart';
import '../../../support/pcm_fixtures.dart';
import '../../../support/spoken_script.dart';
import '../../transcripts/fakes/fake_transcript_repository.dart';
import '../../transcripts/presentation/transcript_screens.dart'
    show speechHostOverride;
import '../fakes/fake_meeting_repository.dart';
import '../meeting_live_harness.dart';

const AudioRecording _published = AudioRecording(
  relativePath: 'projects/alpha/meetings/m1/1/recording.wav',
  sha256: 'take-hash',
  byteLength: 44,
  duration: Duration(seconds: 2),
  mimeType: 'audio/wav',
);

const Key _start = ValueKey<String>('recording-bar-start');
const Key _resume = ValueKey<String>('recording-bar-resume');
const Key _stop = ValueKey<String>('recording-bar-stop');
const Key _discard = ValueKey<String>('recording-bar-discard');

void main() {
  late FakeLiveTranscriptionService service;
  late FakeTranscriptRepository repository;
  late FakeMeetingRepository meetings;
  late FakeSpeechEngine engine;
  late LifecycleObserver lifecycle;
  late LeaveGuard guard;

  setUp(() {
    service = FakeLiveTranscriptionService(recording: _published);
    repository = FakeTranscriptRepository();
    meetings = FakeMeetingRepository()..seed(aLiveMeeting());
    engine = FakeSpeechEngine();
    lifecycle = LifecycleObserver.fake();
    guard = LeaveGuard.fake();
  });

  tearDown(() async {
    await service.dispose();
    await repository.dispose();
    await engine.dispose();
    lifecycle.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool ready = true,
    bool isWeb = false,
  }) async {
    await pumpMeetingRoutes(
      tester,
      page: (String meetingId, String projectId) => Scaffold(
        body: SingleChildScrollView(
          child: MeetingLiveSection(
            meetingId: meetingId,
            projectId: projectId,
            isWeb: isWeb,
          ),
        ),
      ),
      overrides: <Override>[
        liveTranscriptionServiceProvider.overrideWithValue(service),
        transcriptRepositoryProvider.overrideWithValue(repository),
        meetingRepositoryProvider.overrideWithValue(meetings),
        leaveGuardProvider.overrideWithValue(guard),
        lifecycleObserverProvider.overrideWithValue(lifecycle),
        speechHostOverride(engine, lifecycle, ready: ready),
        speechLanguageProvider.overrideWithValue('en'),
      ],
    );
  }

  TranscriptSummary row() => repository.stored.single;

  testWidgets('live mode: start writes a live meeting row before the '
      'microphone, segments save, and stop files the take through '
      'attachStored and completes the transcript', (WidgetTester tester) async {
    await pump(tester);
    expect(find.text(Copy.meetingRecord), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsOneWidget);
    expect(find.byType(AppTranscriptView), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('live-transcript-audio-only')),
      findsNothing,
    );

    final List<TranscriptStatus> beforeMicrophone = <TranscriptStatus>[];
    service.onStart = (LiveTranscriptionRequest request) {
      beforeMicrophone.add(row().status);
    };
    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    expect(beforeMicrophone, <TranscriptStatus>[TranscriptStatus.live]);
    expect(find.byType(AppTranscriptView), findsOneWidget);
    final LiveTranscriptionRequest request = service.requests.single;
    expect(request.transcribe, isTrue);
    expect(request.kind, TranscriptionKind.longForm);
    expect(
      request.audioPath,
      startsWith('projects/alpha/meetings/$liveMeetingId/'),
    );
    expect(request.audioPath, endsWith('/recording.wav'));
    expect(row().ownerKind, TranscriptOwnerKind.meeting);
    expect(row().ownerId, liveMeetingId);
    expect(row().projectId, liveMeetingProject);

    final FakeLiveTranscriptionSession session = service.session;
    expect(
      await session.say(<String>['We agreed to fence the reservoir.']),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.text('We agreed to fence the reservoir.'), findsOneWidget);
    expect(repository.utterances[row().id], hasLength(1));

    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    final ({String meetingId, MeetingAttachment file, String sha256}) filed =
        meetings.stored.single;
    expect(filed.meetingId, liveMeetingId);
    expect(filed.file.relativePath, _published.relativePath);
    expect(filed.sha256, _published.sha256);
    expect(row().attachmentId, filed.file.id);
    expect(row().status, TranscriptStatus.live, reason: 'still draining');

    await session.complete();
    await tester.pumpAndSettle();
    expect(row().status, TranscriptStatus.complete);
    expect(find.text('We agreed to fence the reservoir.'), findsWidgets);
    expect(
      find.byKey(ValueKey<String>('transcript-row-${row().id}')),
      findsOneWidget,
      reason: 'the saved transcript joins the meeting list',
    );
    expect(guard.isHeld, isFalse);
  });

  testWidgets('without a model the meeting records audio only, explains why, '
      'and still files the take', (WidgetTester tester) async {
    await pump(tester, ready: false);
    expect(find.text(Copy.liveTranscriptAudioOnly), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsNothing);
    expect(find.byType(AppTranscriptView), findsNothing);
    expect(find.byKey(_start), findsOneWidget);

    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    expect(service.requests.single.transcribe, isFalse);
    expect(find.text(Copy.liveTranscriptAudioOnly), findsOneWidget);

    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    expect(meetings.stored.single.file.relativePath, _published.relativePath);
  });

  testWidgets('an idle meeting keeps its saved transcript available to open', (
    WidgetTester tester,
  ) async {
    repository.seed(
      aMeetingTranscript(id: 'previous', preview: 'The pump needs repair.'),
      lines: const <TranscriptLine>[
        TranscriptLine(
          seq: 1,
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'The pump needs repair.',
        ),
      ],
    );
    await pump(tester);
    expect(find.byType(AppTranscriptView), findsNothing);
    expect(find.byKey(_start), findsOneWidget);
    final Finder saved = find.byKey(
      const ValueKey<String>('transcript-row-previous'),
    );
    expect(saved, findsOneWidget);
    await tester.tap(saved);
    await tester.pumpAndSettle();
    expect(find.byType(TranscriptDetailScreen), findsOneWidget);
    expect(find.text('The pump needs repair.'), findsOneWidget);
  });

  testWidgets('a browser that cannot capture audio says so and stops '
      'offering to record', (WidgetTester tester) async {
    service.startFailure = ProviderFailure(
      kind: ProviderFailureKind.unavailable,
      localizedMessage: Copy.messages.audioRecorderUnavailable,
    );
    await pump(tester, isWeb: true);
    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('meeting-capture-unavailable')),
      findsOneWidget,
    );
    expect(find.text(Copy.audioRecorderUnavailable), findsOneWidget);
    expect(find.byKey(_start), findsNothing);
    expect(repository.discarded, hasLength(1), reason: 'nothing recorded');
    expect(meetings.stored, isEmpty);
  });

  testWidgets('away from a browser the same refusal keeps the recorder, so '
      'the operator can try again', (WidgetTester tester) async {
    service.startFailure = ProviderFailure(
      kind: ProviderFailureKind.unavailable,
      localizedMessage: Copy.messages.audioRecorderUnavailable,
    );
    await pump(tester);
    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('meeting-capture-unavailable')),
      findsNothing,
    );
    expect(find.byKey(_start), findsOneWidget);
  });

  testWidgets('a background pause names its reason and resumes only on tap', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    service.session.pauseFor(CapturePauseReason.background);
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.liveTranscriptStatusPausedBackground),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_resume));
    await tester.pumpAndSettle();
    expect(find.text(Copy.liveTranscriptStatusListening), findsOneWidget);
  });

  testWidgets('discard tombstones the transcript and files nothing', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    final String id = row().id;
    await tester.tap(find.byKey(_discard));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.liveTranscriptCancel),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.discarded, <String>{id});
    expect(meetings.stored, isEmpty);
    expect(service.session.cancels, 1);
    expect(find.byKey(_start), findsOneWidget);
    expect(find.byType(AppDialog), findsNothing);
  });

  group('on this machine (host mirror of the -d windows run)', () {
    /// [samples] as the bytes of a 16 kHz mono PCM WAV file.
    Uint8List wavOf(Int16List samples) => Uint8List.fromList(<int>[
      ...WavHeader.bytes(
        AppConstants.audio.sampleRate,
        AppConstants.audio.channels,
        dataLength: samples.lengthInBytes,
      ),
      ...samples.buffer.asUint8List(
        samples.offsetInBytes,
        samples.lengthInBytes,
      ),
    ]);

    testWidgets('a WAV-fed meeting session pauses with its reason when the '
        'app is backgrounded, and resumes only on tap', (
      WidgetTester tester,
    ) async {
      final SpokenScript script = SpokenScript(<SpokenWord>[
        ...SpokenScript.paced(
          <String>['check', 'the', 'pump'],
          startSample: SpokenScript.samplesOf(
            const Duration(milliseconds: 500),
          ),
        ).words,
        ...SpokenScript.paced(
          <String>['close', 'the', 'gate'],
          startSample: SpokenScript.samplesOf(const Duration(seconds: 4)),
        ).words,
      ]);
      final Int16List samples = PcmFixtures.fromScript(
        script,
        length:
            script.endSample +
            SpokenScript.samplesOf(const Duration(seconds: 2)),
      );
      // The app goes to the background in the pause between the two.
      final int split = SpokenScript.samplesOf(const Duration(seconds: 3));
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture_meeting_live_',
      );
      addTearDown(() => documents.deleteSync(recursive: true));
      final File first = File('${documents.path}/first.wav')
        ..writeAsBytesSync(wavOf(Int16List.sublistView(samples, 0, split)));
      final File second = File('${documents.path}/second.wav')
        ..writeAsBytesSync(wavOf(Int16List.sublistView(samples, split)));
      final StorageRoot root = StorageRoot.fake(documentsDirectory: documents);
      final FileWriter writer = FileWriter(storageRoot: root);
      final FakeRecordRecorder recorder = FakeRecordRecorder();
      final LiveTranscriptionRig rig = LiveTranscriptionRig(
        capture: AudioCapturePlugin(
          writer: writer,
          storageRoot: root,
          access: MicrophoneAccess(
            permissions: PermissionsService.fake(),
            recorderPermission: ({required bool request}) async => true,
            platform: TargetPlatform.windows,
            isWeb: false,
          ),
          arbiter: MicrophoneArbiter(),
          recorderFactory: () => recorder,
        ),
        engine: FakeSpeechEngine(script: script),
        storageRoot: root,
        recovery: StagedTakeRecovery(writer: writer, storageRoot: root),
      );
      await pumpMeetingRoutes(
        tester,
        page: (String meetingId, String projectId) => Scaffold(
          body: SingleChildScrollView(
            child: MeetingLiveSection(
              meetingId: meetingId,
              projectId: projectId,
            ),
          ),
        ),
        overrides: <Override>[
          liveTranscriptionServiceProvider.overrideWithValue(rig.service),
          transcriptRepositoryProvider.overrideWithValue(repository),
          meetingRepositoryProvider.overrideWithValue(meetings),
          leaveGuardProvider.overrideWithValue(rig.leaveGuard),
          lifecycleObserverProvider.overrideWithValue(rig.lifecycle),
          speechEngineHostProvider.overrideWithValue(rig.host),
          speechLanguageProvider.overrideWithValue('en'),
        ],
      );
      await settleUntil(
        tester,
        () => find.byKey(_start).evaluate().isNotEmpty,
        reason: 'readiness is known',
      );
      expect(find.text(Copy.speechOfflineBadge), findsOneWidget);

      // The session runs on the real event loop, as on the device: it is
      // started there, and only the operator's resume is a tap.
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MeetingLiveSection)),
      );
      final LiveTranscriptController controller = container.read(
        liveTranscriptControllerProvider(
          LiveTranscriptKey.meeting(liveMeetingId),
        ).notifier,
      );
      final TranscriptSessionTarget target = container.read(
        meetingTranscriptTargetProvider((
          meetingId: liveMeetingId,
          projectId: liveMeetingProject,
        )),
      );
      expect(target.mode, TranscriptMode.live);
      await drive(tester, () => controller.start(target));
      await settleUntil(
        tester,
        () => recorder.streaming,
        reason: 'the microphone opened',
      );
      await drive(tester, () => recorder.streamWav(first));
      await settleUntil(
        tester,
        () => (repository.utterances[row().id] ?? const <Object>[]).isNotEmpty,
        reason: 'the first thing said is saved',
      );

      await drive(tester, () => rig.lifecycle.handle(AppLifecycleState.paused));
      await settleUntil(
        tester,
        () => find
            .text(Copy.liveTranscriptStatusPausedBackground)
            .evaluate()
            .isNotEmpty,
        reason: 'the pause names its reason',
      );
      expect(recorder.pauses, 1);
      expect(find.byKey(_resume), findsOneWidget);

      await drive(
        tester,
        () => rig.lifecycle.handle(AppLifecycleState.resumed),
      );
      await settleUntil(tester, () => true);
      expect(
        find.text(Copy.liveTranscriptStatusPausedBackground),
        findsOneWidget,
        reason: 'the microphone reopens only when the operator asks',
      );
      expect(recorder.resumes, 0);

      await tester.tap(find.byKey(_resume));
      await settleUntil(
        tester,
        () =>
            find.text(Copy.liveTranscriptStatusListening).evaluate().isNotEmpty,
        reason: 'a tap resumes',
      );
      expect(recorder.resumes, 1);

      await drive(tester, () => recorder.streamWav(second));
      await drive(tester, controller.stop);
      await settleUntil(
        tester,
        () => meetings.stored.isNotEmpty,
        reason: 'the take is filed on the meeting',
      );
      await settleUntil(
        tester,
        () => row().status == TranscriptStatus.complete,
        reason: 'the transcript completes',
      );
      final MeetingAttachment take = meetings.stored.single.file;
      final Result<Directory> base = await drive(tester, root.resolve);
      expect(row().attachmentId, take.id);
      expect(
        File(
          '${(base as Success<Directory>).value.path}/${take.relativePath}',
        ).readAsBytesSync(),
        wavOf(samples),
        reason: 'paused and resumed, the take is every sample fed, in order',
      );
      final List<String> words = <String>[
        for (final FinishedUtterance utterance
            in repository.utterances[row().id]!)
          for (final TranscriptSegment segment in utterance.segments)
            for (final TranscriptWord word in segment.words) word.text,
      ];
      expect(words, <String>['check', 'the', 'pump', 'close', 'the', 'gate']);

      await tester.pumpWidget(const SizedBox.shrink());
      await drive(tester, rig.dispose);
    });
  });
}
