import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show
        currentProjectProvider,
        projectRepositoryProvider,
        projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/transcripts/transcripts.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_id_service.dart';
import '../../../support/fakes/fake_live_transcription_service.dart';
import '../../../support/fakes/fake_project_repository.dart';
import '../../../support/fakes/fake_speech_engine.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import '../fakes/fake_transcript_repository.dart';
import 'transcript_screens.dart';

const String _project = 'created-1';
const String _take = 'projects/created-1/audio/take-1.wav';

const AudioRecording _published = AudioRecording(
  relativePath: _take,
  sha256: 'abc',
  byteLength: 44,
  duration: Duration(seconds: 2),
  mimeType: 'audio/wav',
);

const Key _start = ValueKey<String>('recording-bar-start');
const Key _stop = ValueKey<String>('recording-bar-stop');

void main() {
  setUpAll(ScreenFonts.loadForApp);
  late FakeProjectRepository projects;
  late FakeTranscriptRepository repository;
  late FakeLiveTranscriptionService service;
  late FakeSpeechEngine engine;
  late LifecycleObserver lifecycle;
  late LeaveGuard guard;

  setUp(() async {
    projects = FakeProjectRepository();
    await projects.createReady(name: 'Field');
    repository = FakeTranscriptRepository();
    service = FakeLiveTranscriptionService(recording: _published);
    engine = FakeSpeechEngine();
    lifecycle = LifecycleObserver.fake();
    guard = LeaveGuard.fake();
  });

  tearDown(() async {
    await service.dispose();
    await repository.dispose();
    await engine.dispose();
    lifecycle.dispose();
    projects.dispose();
  });

  Future<GoRouter> pump(
    WidgetTester tester,
    String location, {
    bool ready = true,
    ScreenMatrix? cell,
  }) {
    return pumpTranscriptRoutes(
      tester,
      location,
      cell: cell,
      overrides: <Override>[
        projectRepositoryProvider.overrideWithValue(projects),
        projectSettingsStoreProvider.overrideWithValue(SettingsStore.fake()),
        transcriptRepositoryProvider.overrideWithValue(repository),
        liveTranscriptionServiceProvider.overrideWithValue(service),
        leaveGuardProvider.overrideWithValue(guard),
        lifecycleObserverProvider.overrideWithValue(lifecycle),
        speechHostOverride(engine, lifecycle, ready: ready),
        speechLanguageProvider.overrideWithValue('en'),
        transcriptIdsProvider.overrideWithValue(FakeIdService(prefix: 'take')),
      ],
    );
  }

  Future<void> tapEmptyAction(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppEmptyState),
        matching: find.widgetWithText(AppButton, label),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets('transcription controls stay in reach ${cell.description}', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = cell.size;
      tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, RoutePaths.projectTranscribe(_project), cell: cell);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(_start));
      await tester.pumpAndSettle();
      expect(
        ScreenProbe.reachabilityIssues(tester, find.byKey(_start)),
        isEmpty,
      );
      expect(
        tester.getSize(find.byKey(_start)).height,
        greaterThanOrEqualTo(64),
      );
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
      await tester.tap(find.byKey(_start));
      await tester.pumpAndSettle();
      await service.session.say(<String>['Durable field note.']);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(_stop));
      await tester.pumpAndSettle();
      expect(
        ScreenProbe.reachabilityIssues(tester, find.byKey(_stop)),
        isEmpty,
      );
      expect(find.text('Durable field note.'), findsOneWidget);
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
      await tester.tap(find.byKey(_stop));
      await tester.pumpAndSettle();
      expect(repository.filedAudio.values.single, _published);
      await service.session.complete();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('with no project open it asks for one', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pump(tester, RoutePaths.transcribe);
    expect(find.text(Copy.transcriptsNoProject), findsOneWidget);
    expect(find.text(Copy.transcriptsNoProjectMessage), findsOneWidget);
    await tapEmptyAction(tester, Copy.navProjects);
    expect(router.state.uri.path, RoutePaths.projects);
  });

  testWidgets('a project that is not on this device is no project to '
      'record into', (WidgetTester tester) async {
    await pump(tester, RoutePaths.projectTranscribe('gone'));
    expect(find.text(Copy.transcriptsNoProject), findsOneWidget);
    expect(find.byKey(_start), findsNothing);
  });

  testWidgets('explains when transcription is unavailable and links to '
      'Language settings', (WidgetTester tester) async {
    final GoRouter router = await pump(
      tester,
      RoutePaths.projectTranscribe(_project),
      ready: false,
    );
    expect(find.text(Copy.liveTranscriptUnavailable), findsOneWidget);
    expect(find.text(Copy.liveTranscriptUnavailableRecovery), findsOneWidget);
    expect(find.byKey(_start), findsNothing);
    await tapEmptyAction(tester, Copy.settingsLanguageTitle);
    expect(router.state.uri.path, RoutePaths.settingsLanguage);
    expect(find.text(languagePage), findsOneWidget);
  });

  testWidgets('records into the project folder, saves, and opens the '
      'transcript, read-only until its last words are written', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pump(
      tester,
      RoutePaths.projectTranscribe(_project),
    );
    expect(find.text(Copy.transcriptLanguage('en')), findsOneWidget);
    expect(find.text(Copy.speechOfflineBadge), findsOneWidget);
    expect(find.byKey(_start), meetsTapTarget());

    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    expect(service.requests.single.audioPath, _take);
    final TranscriptSummary started = repository.stored.single;
    expect(started.status, TranscriptStatus.live);
    expect(started.ownerKind, TranscriptOwnerKind.standalone);
    expect(started.projectId, _project);
    expect(started.audioPath, _take);

    await service.session.say(<String>['Check the pump.']);
    await tester.pumpAndSettle();
    expect(find.text('Check the pump.'), findsOneWidget);

    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    expect(repository.filedAudio[started.id], _published);
    expect(repository.stored.single.attachmentId, isNotNull);
    expect(
      router.state.uri.path,
      RoutePaths.projectTranscript(_project, started.id),
    );
    expect(find.byType(TranscriptDetailScreen), findsOneWidget);
    expect(find.text(Copy.transcriptStillRecording), findsOneWidget);

    await service.session.complete();
    await tester.pumpAndSettle();
    expect(repository.stored.single.status, TranscriptStatus.complete);
    expect(find.text(Copy.transcriptStillRecording), findsNothing);
    final Finder field = find.descendant(
      of: find.byKey(const ValueKey<String>('transcript-edited')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(field).controller.text,
      'Check the pump.',
    );
    expect(guard.isHeld, isFalse);
  });

  testWidgets('from More it records into the open project and opens the '
      'transcript under More', (WidgetTester tester) async {
    final GoRouter router = await pump(tester, RoutePaths.transcripts);
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(TranscriptsScreen)),
    );
    container.read(currentProjectProvider.notifier).open(_project);
    router.go(RoutePaths.transcribe);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();
    await service.session.say(<String>['Close the gate.']);
    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    final String id = repository.stored.single.id;
    expect(router.state.uri.path, RoutePaths.transcript(id));
    expect(repository.filedAudio[id], _published);
  });

  for (final Size size in <Size>[
    const Size(360, 800),
    const Size(800, 900),
    const Size(1280, 900),
  ]) {
    testWidgets('lays the details and the panel out at ${size.width} wide', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, RoutePaths.projectTranscribe(_project));
      expect(tester.takeException(), isNull);
      final Rect details = tester.getRect(
        find.text(Copy.transcriptLanguage('en')),
      );
      final Rect start = tester.getRect(find.byKey(_start));
      expect(start.right, lessThanOrEqualTo(size.width));
      expect(details.bottom, lessThanOrEqualTo(start.top));
      expect(start.bottom, lessThanOrEqualTo(size.height));
    });
  }
}
