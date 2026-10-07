import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/features/transcripts/transcripts.dart';

import '../../../support/fakes/fake_speech_engine.dart';
import '../../../support/live_transcription_rig.dart';

/// Text the stand-in pages show, so a test can tell where it landed.
const String projectsPage = 'projects page';
const String languagePage = 'language page';

/// Pumps the transcript screens under a router of their own routes,
/// opened at [location], and returns the router.
Future<GoRouter> pumpTranscriptRoutes(
  WidgetTester tester,
  String location, {
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.projects,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text(projectsPage)),
        routes: <RouteBase>[
          GoRoute(
            path: ':projectId/transcripts',
            builder: (BuildContext _, GoRouterState state) =>
                TranscriptsScreen(projectId: state.pathParameters['projectId']),
            routes: _children(inProject: true),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.more,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: SizedBox.shrink()),
        routes: <RouteBase>[
          GoRoute(
            path: 'language',
            builder: (BuildContext _, GoRouterState _) =>
                const Scaffold(body: Text(languagePage)),
          ),
          GoRoute(
            path: 'transcripts',
            builder: (BuildContext _, GoRouterState _) =>
                const TranscriptsScreen(),
            routes: _children(inProject: false),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: overrides,
      child: MaterialApp.router(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

List<RouteBase> _children({required bool inProject}) {
  return <RouteBase>[
    GoRoute(
      path: 'new',
      builder: (BuildContext _, GoRouterState state) => TranscribeScreen(
        projectId: inProject ? state.pathParameters['projectId'] : null,
      ),
    ),
    GoRoute(
      path: ':transcriptId',
      builder: (BuildContext _, GoRouterState state) => TranscriptDetailScreen(
        transcriptId: state.pathParameters['transcriptId']!,
        projectId: inProject ? state.pathParameters['projectId'] : null,
      ),
    ),
  ];
}

/// A speech host over [engine] whose readiness is ready when [ready], with
/// every bundled model; otherwise no model is installed.
Override speechHostOverride(
  FakeSpeechEngine engine,
  LifecycleObserver lifecycle, {
  required bool ready,
}) {
  return speechEngineHostProvider.overrideWith((Ref ref) {
    final SpeechEngineHost host = SpeechEngineHost(
      engine: engine,
      store: SpeechModelStore.fake(
        ready ? testInstalledModels() : <String, SpeechModelStatus>{},
      ),
      probe: const SpeechDeviceProbe.fake(testDesktopDevice),
      quality: () => SpeechQuality.fast,
      lifecycle: lifecycle.states,
      memoryPressure: lifecycle.memoryPressure,
      delay: (Duration _) => Completer<void>().future,
    );
    ref.onDispose(() => unawaited(host.dispose()));
    return host;
  });
}

/// A settled transcript header for list and page tests.
TranscriptSummary aTranscript({
  required String id,
  String projectId = 'p1',
  TranscriptOwnerKind ownerKind = TranscriptOwnerKind.standalone,
  String title = '',
  TranscriptStatus status = TranscriptStatus.complete,
  DateTime? startedAt,
  Duration? duration = const Duration(seconds: 20),
  int coveredMs = 20000,
  List<TranscriptGap> gaps = const <TranscriptGap>[],
  String preview = '',
  bool edited = false,
  String? attachmentId = 'attachment-1',
}) {
  return TranscriptSummary(
    id: id,
    projectId: projectId,
    ownerKind: ownerKind,
    audioPath: 'projects/folder/audio/$id.wav',
    title: title,
    status: status,
    startedAt: startedAt ?? DateTime.utc(2026, 10, 4, 8),
    languageTag: 'en',
    modelId: 'tiny-q5_1',
    attachmentId: attachmentId,
    duration: duration,
    coveredMs: coveredMs,
    gaps: gaps,
    preview: preview,
    edited: edited,
  );
}
