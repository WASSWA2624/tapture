import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/presentation/meeting_review_controller.dart';
import 'package:tapture/features/transcripts/transcripts.dart';

/// The meeting the live meeting tests record, on project `p1`.
const String liveMeetingId = 'm1';

/// The project of [liveMeetingId].
const String liveMeetingProject = 'p1';

/// Meeting [liveMeetingId] as stored.
Meeting aLiveMeeting() => Meeting(
  id: liveMeetingId,
  projectId: liveMeetingProject,
  title: 'Site meeting',
  startedAt: DateTime.utc(2026, 10, 4, 9),
  recordId: 'r1',
);

/// A settled transcript recorded for meeting [liveMeetingId].
TranscriptSummary aMeetingTranscript({
  required String id,
  String preview = '',
  TranscriptStatus status = TranscriptStatus.complete,
  DateTime? startedAt,
}) {
  return TranscriptSummary(
    id: id,
    projectId: liveMeetingProject,
    ownerKind: TranscriptOwnerKind.meeting,
    ownerId: liveMeetingId,
    audioPath: 'projects/alpha/meetings/$liveMeetingId/$id/recording.wav',
    title: '',
    status: status,
    startedAt: startedAt ?? DateTime.utc(2026, 10, 4, 9, 30),
    languageTag: 'en',
    modelId: 'tiny-q5_1',
    attachmentId: 'attachment-$id',
    duration: const Duration(seconds: 20),
    coveredMs: 20000,
    preview: preview,
  );
}

/// Pumps [page] at the review route of meeting [liveMeetingId], under a
/// router whose transcript route opens the real transcript page, and
/// returns the router.
Future<GoRouter> pumpMeetingRoutes(
  WidgetTester tester, {
  required Widget Function(String meetingId, String projectId) page,
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final GoRouter router = GoRouter(
    initialLocation: RoutePaths.projectMeetingReview(
      liveMeetingProject,
      liveMeetingId,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.projects,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: SizedBox.shrink()),
        routes: <RouteBase>[
          GoRoute(
            path: ':projectId/meetings/:meetingId/review',
            onExit: (BuildContext context, GoRouterState state) =>
                ProviderScope.containerOf(context, listen: false)
                    .read(
                      meetingReviewControllerProvider(
                        state.pathParameters['meetingId']!,
                      ).notifier,
                    )
                    .flush(),
            builder: (BuildContext _, GoRouterState state) => page(
              state.pathParameters['meetingId']!,
              state.pathParameters['projectId']!,
            ),
          ),
          GoRoute(
            path: ':projectId/transcripts/:transcriptId',
            builder: (BuildContext _, GoRouterState state) =>
                TranscriptDetailScreen(
                  transcriptId: state.pathParameters['transcriptId']!,
                  projectId: state.pathParameters['projectId'],
                ),
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

/// Lets real asynchronous work (file writes, the engine) run until
/// [condition] holds, pumping frames between turns.
Future<void> settleUntil(
  WidgetTester tester,
  bool Function() condition, {
  String? reason,
}) async {
  for (int turn = 0; turn < 400 && !condition(); turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  expect(condition(), isTrue, reason: reason);
}

/// Starts [action] on the real event loop and settles until it finishes,
/// pumping frames meanwhile, so work it shares with the widget tree never
/// waits on a frame that is not pumped.
Future<T> drive<T>(WidgetTester tester, Future<T> Function() action) async {
  Future<T>? pending;
  await tester.runAsync(() async {
    pending = action();
  });
  bool done = false;
  late T value;
  pending!.then((T result) {
    value = result;
    done = true;
  }).ignore();
  await settleUntil(tester, () => done);
  return value;
}
