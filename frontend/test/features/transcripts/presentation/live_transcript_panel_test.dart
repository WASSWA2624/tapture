import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/core/widgets/app_transcript_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/features/transcripts/transcripts.dart';

import '../../../support/fakes/fake_live_transcription_service.dart';
import '../../../support/fakes/fake_speech_engine.dart';
import '../../../support/live_transcription_rig.dart';
import '../../../support/pump_app.dart';
import '../fakes/fake_transcript_repository.dart';

const String _key = 'meeting:m1';

const AudioRecording _published = AudioRecording(
  relativePath: 'projects/p1/meetings/m1/recording.wav',
  sha256: 'abc',
  byteLength: 44,
  duration: Duration(seconds: 2),
  mimeType: 'audio/wav',
);

const Key _start = ValueKey<String>('recording-bar-start');
const Key _pause = ValueKey<String>('recording-bar-pause');
const Key _resume = ValueKey<String>('recording-bar-resume');
const Key _stop = ValueKey<String>('recording-bar-stop');
const Key _discard = ValueKey<String>('recording-bar-discard');

void main() {
  late FakeLiveTranscriptionService service;
  late FakeTranscriptRepository repository;
  late LeaveGuard guard;
  late LifecycleObserver lifecycle;
  late FakeSpeechEngine engine;
  late List<String> calls;
  Failure? fileFailure;

  setUp(() {
    service = FakeLiveTranscriptionService(recording: _published);
    repository = FakeTranscriptRepository();
    guard = LeaveGuard.fake();
    lifecycle = LifecycleObserver.fake();
    engine = FakeSpeechEngine();
    calls = <String>[];
    fileFailure = null;
  });

  tearDown(() async {
    await service.dispose();
    await repository.dispose();
    await engine.dispose();
    lifecycle.dispose();
  });

  TranscriptSessionTarget target({TranscriptMode mode = TranscriptMode.live}) {
    return TranscriptSessionTarget(
      sessionKey: _key,
      projectId: 'p1',
      ownerKind: TranscriptOwnerKind.meeting,
      ownerId: 'm1',
      audioPath: () async =>
          const Success<String>('projects/p1/meetings/m1/recording.wav'),
      fileAudio: (AudioRecording audio) async {
        calls.add('fileAudio');
        final Failure? failure = fileFailure;
        if (failure != null) {
          fileFailure = null;
          return FailureResult<String?>(failure);
        }
        return const Success<String?>('attachment-1');
      },
      onDiscard: () async => calls.add('onDiscard'),
      mode: mode,
    );
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    TranscriptMode mode = TranscriptMode.live,
    bool showIdleControls = true,
    bool showEmptyIdleTranscript = true,
    ValueChanged<String>? onOpenTranscript,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: LiveTranscriptPanel(
            target: target(mode: mode),
            showIdleControls: showIdleControls,
            showEmptyIdleTranscript: showEmptyIdleTranscript,
            onOpenTranscript: onOpenTranscript,
          ),
        ),
      ),
      overrides: <Override>[
        liveTranscriptionServiceProvider.overrideWithValue(service),
        transcriptRepositoryProvider.overrideWithValue(repository),
        leaveGuardProvider.overrideWithValue(guard),
        lifecycleObserverProvider.overrideWithValue(lifecycle),
        speechEngineHostProvider.overrideWith((Ref ref) {
          final SpeechEngineHost host = SpeechEngineHost(
            engine: engine,
            store: SpeechModelStore.fake(testInstalledModels()),
            probe: const SpeechDeviceProbe.fake(testDesktopDevice),
            quality: () => SpeechQuality.fast,
            lifecycle: lifecycle.states,
            memoryPressure: lifecycle.memoryPressure,
            delay: (Duration _) => Completer<void>().future,
          );
          ref.onDispose(() => unawaited(host.dispose()));
          return host;
        }),
      ],
    );
  }

  Future<void> startRecording(WidgetTester tester) async {
    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    expect(find.byKey(_stop), findsOneWidget);
  }

  testWidgets('starts from idle, shows it is on this device and shows the '
      'words as they are heard', (WidgetTester tester) async {
    await pumpPanel(tester);
    expect(find.byKey(_start), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsOneWidget);
    expect(find.text(Copy.liveTranscriptEmpty), findsOneWidget);

    await startRecording(tester);
    expect(find.byKey(_pause), findsOneWidget);
    expect(find.byKey(_discard), findsOneWidget);
    expect(find.text(Copy.liveTranscriptStatusListening), findsOneWidget);
    expect(repository.stored.single.status, TranscriptStatus.live);

    final FakeLiveTranscriptionSession session = service.session;
    session.draft(1, 'check the', 'pump');
    await tester.pumpAndSettle();
    expect(find.text('check the pump'), findsOneWidget);
    await session.say(<String>['Check the pump.']);
    await tester.pumpAndSettle();
    expect(find.text('Check the pump.'), findsOneWidget);
  });

  testWidgets('without idle controls nothing shows until a session starts', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester, showIdleControls: false);
    expect(find.byKey(_start), findsNothing);
    expect(find.byType(LiveTranscriptPanel), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsNothing);
  });

  testWidgets('compact idle keeps controls and shows the pane throughout '
      'recording, pause and saved transcript review', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester, showEmptyIdleTranscript: false);
    expect(find.byType(AppTranscriptView), findsNothing);
    expect(find.byKey(_start), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsOneWidget);

    final Completer<void> opening = Completer<void>();
    service.holdStart = opening;
    await tester.tap(find.byKey(_start));
    await pumpUntil(
      tester,
      () => find.byType(AppTranscriptView).evaluate().isNotEmpty,
    );
    expect(find.byType(AppTranscriptView), findsOneWidget);
    opening.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AppTranscriptView), findsOneWidget);
    expect(find.text(Copy.liveTranscriptEmpty), findsOneWidget);
    await tester.tap(find.byKey(_pause));
    await tester.pumpAndSettle();
    expect(find.byType(AppTranscriptView), findsOneWidget);
    await tester.tap(find.byKey(_resume));
    await tester.pumpAndSettle();

    service.session.draft(1, 'Check the', 'pump');
    await tester.pumpAndSettle();
    expect(find.text('Check the pump'), findsOneWidget);
    await service.session.say(<String>['Check the pump.']);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    expect(find.text('Check the pump.'), findsOneWidget);
    await service.session.complete();
    await tester.pumpAndSettle();
    expect(find.text(Copy.liveTranscriptStatusSaved), findsOneWidget);
    expect(find.text('Check the pump.'), findsOneWidget);
  });

  testWidgets('discard asks first, and only a confirmed discard tombstones '
      'the transcript', (WidgetTester tester) async {
    await pumpPanel(tester);
    await startRecording(tester);

    await tester.tap(find.byKey(_discard));
    await tester.pumpAndSettle();
    expect(find.text(Copy.liveTranscriptCancelTitle), findsOneWidget);
    expect(find.text(Copy.liveTranscriptCancelMessage), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.cancel),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.discarded, isEmpty);
    expect(service.session.cancels, 0);
    expect(find.byKey(_stop), findsOneWidget);

    await tester.tap(find.byKey(_discard));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.liveTranscriptCancel),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.discarded, hasLength(1));
    expect(service.session.cancels, 1);
    expect(calls, <String>['onDiscard']);
    expect(find.byKey(_start), findsOneWidget);
  });

  testWidgets('a background pause says why, and only the operator resumes', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester);
    await startRecording(tester);
    service.session.pauseFor(CapturePauseReason.background);
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.liveTranscriptStatusPausedBackground),
      findsOneWidget,
    );
    expect(find.byKey(_resume), findsOneWidget);

    service.session.pauseFor(CapturePauseReason.interruption);
    await tester.pumpAndSettle();
    expect(find.byKey(_resume), findsOneWidget, reason: 'still paused');

    await tester.tap(find.byKey(_resume));
    await tester.pumpAndSettle();
    expect(find.byKey(_pause), findsOneWidget);
    expect(find.text(Copy.liveTranscriptStatusListening), findsOneWidget);
  });

  testWidgets('an interruption and a withdrawn permission each say why', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester);
    await startRecording(tester);
    service.session.pauseFor(CapturePauseReason.interruption);
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.liveTranscriptStatusPausedInterruption),
      findsOneWidget,
    );
    service.session.resumeFailure = const PermissionFailure();
    await tester.tap(find.byKey(_resume));
    await tester.pumpAndSettle();
    expect(find.text(Copy.liveTranscriptPermissionRevoked), findsOneWidget);
    expect(find.byKey(_stop), findsOneWidget, reason: 'it can still be kept');
  });

  testWidgets('a failed filing step shows the failure and a retry; the '
      'retry saves, and the saved transcript can be opened', (
    WidgetTester tester,
  ) async {
    final List<String> opened = <String>[];
    await pumpPanel(tester, onOpenTranscript: opened.add);
    await startRecording(tester);
    fileFailure = const StorageFailure();

    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('live-transcript-failure')),
      findsOneWidget,
    );
    final Finder retry = find.byKey(
      const ValueKey<String>('live-transcript-retry'),
    );
    expect(retry, findsOneWidget);
    expect(find.byKey(_start), findsNothing, reason: 'the take is not filed');

    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(calls, <String>['fileAudio', 'fileAudio']);
    expect(find.text(Copy.liveTranscriptStatusDraining), findsOneWidget);
    expect(retry, findsNothing);

    await service.session.complete();
    await tester.pumpAndSettle();
    expect(find.text(Copy.liveTranscriptStatusSaved), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('live-transcript-open')),
    );
    expect(opened, <String>[repository.stored.single.id]);
  });

  testWidgets('warnings and record-only sessions are explained', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester, mode: TranscriptMode.audioOnly);
    expect(find.text(Copy.liveTranscriptAudioOnly), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsNothing);
    await startRecording(tester);
    expect(find.text(Copy.audioRecorderStatus('recording')), findsOneWidget);

    service.session.emit(
      const TranscriptionWarning(kind: TranscriptionWarningKind.storageLow),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.liveTranscriptStorageLow), findsOneWidget);
  });
}
