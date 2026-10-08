import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';
import 'package:tapture/features/processing/presentation/processing_controller.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';
import 'package:tapture/features/processing/presentation/queue_screen.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_processing_repository.dart';

void main() {
  testWidgets(
    'project queues bound failures retry and Process all to their owner',
    (WidgetTester tester) async {
      final FakeProcessingRepository repository = FakeProcessingRepository();
      addTearDown(repository.dispose);
      for (final String project in <String>['a', 'b']) {
        for (final bool failed in <bool>[false, true]) {
          final String id = '$project-${failed ? 'failed' : 'pending'}';
          repository.recordProjects[id] = project;
          await repository.save(
            ProcessingJob(
              id: id,
              recordId: id,
              status: failed ? JobStatus.failed : JobStatus.queued,
              lastError: failed ? 'Read failed' : null,
            ),
          );
        }
      }
      final GoRouter router = GoRouter(
        initialLocation: RoutePaths.projectQueue('a'),
        routes: <RouteBase>[
          GoRoute(
            path: '/projects/:projectId/queue',
            builder: (BuildContext _, GoRouterState state) =>
                QueueScreen(projectId: state.pathParameters['projectId']),
          ),
          GoRoute(
            path: '/projects/:projectId/records/:recordId',
            builder: (BuildContext _, GoRouterState state) => Text(
              'opened ${state.pathParameters['projectId']}/${state.pathParameters['recordId']}',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            processingRepositoryProvider.overrideWith((_) => repository),
            queueSnapshotForProjectProvider.overrideWith(
              (Ref _, String projectId) =>
                  repository.watchAll().map((List<ProcessingJob> jobs) {
                    final Iterable<ProcessingJob> owned = jobs.where(
                      (ProcessingJob job) =>
                          repository.recordProjects[job.recordId] == projectId,
                    );
                    return (
                      unprocessed: 0,
                      queued: owned
                          .where(
                            (ProcessingJob job) =>
                                job.status == JobStatus.queued,
                          )
                          .length,
                      failed: owned
                          .where(
                            (ProcessingJob job) =>
                                job.status == JobStatus.failed,
                          )
                          .length,
                      requestsToday: 0,
                      imagesToday: 0,
                      requestCap: 20,
                      groups: const <QueueGroup>[],
                    );
                  }),
            ),
          ],
          child: MaterialApp.router(
            theme: buildTheme(brightness: Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final String project in <String>['a', 'b']) {
        router.go(RoutePaths.projectQueue(project));
        await tester.pumpAndSettle();
        final String other = project == 'a' ? 'b' : 'a';
        final Finder failedRow = find.byKey(
          ValueKey<String>('queue-failure-$project-failed'),
        );
        expect(failedRow, findsOneWidget);
        expect(
          find.byKey(ValueKey<String>('queue-failure-$other-failed')),
          findsNothing,
        );
        await tester.tap(failedRow);
        await tester.pumpAndSettle();
        expect(
          router.state.uri.path,
          RoutePaths.projectRecord(project, '$project-failed'),
        );
        router.pop();
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(ValueKey<String>('queue-retry-$project-failed')),
        );
        await tester.pumpAndSettle();
        expect(
          repository.stored
              .singleWhere((ProcessingJob job) => job.id == '$project-failed')
              .status,
          JobStatus.queued,
        );
        if (project == 'a') {
          expect(
            repository.stored
                .singleWhere((ProcessingJob job) => job.id == 'b-failed')
                .status,
            JobStatus.failed,
          );
        }
        await tester.tap(find.text(Copy.queueProcessAll));
        await tester.pumpAndSettle();
        expect(
          repository.stored
              .where(
                (ProcessingJob job) =>
                    repository.recordProjects[job.recordId] == project,
              )
              .every((ProcessingJob job) => job.status == JobStatus.completed),
          isTrue,
        );
        if (project == 'a') {
          expect(
            repository.stored
                .singleWhere((ProcessingJob job) => job.id == 'b-pending')
                .status,
            JobStatus.queued,
          );
          expect(
            repository.stored
                .singleWhere((ProcessingJob job) => job.id == 'b-failed')
                .status,
            JobStatus.failed,
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('the queue shows one summary, one primary action and grouped '
      'rows', (WidgetTester tester) async {
    await _pump(tester, snapshot: _mixed);

    final Finder summary = find.byKey(const ValueKey<String>('queue-summary'));
    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.byType(Wrap)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.byType(AppStatusPill)),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.text(Copy.queueUsage(3, 8, 20)),
      ),
      findsOneWidget,
    );

    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(
      find.widgetWithText(AppPrimaryAction, Copy.queueProcessAll),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((AppButton b) => b.variant == AppButtonVariant.primary),
      isEmpty,
      reason: 'Process all is the only primary action',
    );

    final List<String> order = <String>[
      for (final Widget widget in tester.widgetList<Widget>(
        find.byWidgetPredicate(
          (Widget w) => w is AppSectionHeader || w is AppListTile,
        ),
      ))
        if (widget is AppSectionHeader)
          widget.title
        else if (widget is AppListTile)
          widget.title,
    ];
    expect(order, <String>[
      Copy.queueFailedTitle,
      'Main pump',
      Copy.recordsUntitled(12),
      Copy.queueGroupsTitle,
      'Kampala / Plant room',
      'Kampala / Store',
    ]);
  });

  testWidgets('a failed row names its record, shows a failed badge and '
      'retries from its own control', (WidgetTester tester) async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(
        id: 'job-1',
        recordId: 'record-1',
        status: JobStatus.failed,
        lastError: '401 authentication failed',
      ),
    );
    await _pump(tester, snapshot: _mixed, repository: repository);

    final Finder row = find.byKey(
      const ValueKey<String>('queue-failure-job-1'),
    );
    final AppListTile tile = tester.widget<AppListTile>(row);
    expect(tile.title, 'Main pump');
    expect(tile.subtitle, '401 authentication failed');
    expect(tile.status?.status, RecordStatus.failed);
    expect(find.textContaining('record-1'), findsNothing);
    final Finder retry = find.byKey(
      const ValueKey<String>('queue-retry-job-1'),
    );
    expect(retry, hasSemanticLabel(Copy.queueRetryLabel('Main pump')));
    expect(retry, meetsTapTarget());

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(repository.stored.single.status, JobStatus.queued);
  });

  testWidgets('tapping a failed row opens its record', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: RoutePaths.queue,
      routes: <RouteBase>[
        GoRoute(
          path: RoutePaths.queue,
          builder: (BuildContext _, GoRouterState _) => const QueueScreen(),
        ),
        GoRoute(
          path: '${RoutePaths.records}/:recordId',
          builder: (BuildContext _, GoRouterState state) =>
              Text('opened ${state.pathParameters['recordId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          queueFailurePageProvider.overrideWith(
            (Ref ref, query) => Stream<QueueFailurePage>.value(
              const QueueFailurePage(items: _mixedFailures),
            ),
          ),
          queueSnapshotProvider.overrideWith(
            (Ref ref) => Stream<QueueSnapshot>.value(_mixed),
          ),
        ],
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Main pump'));
    await tester.pumpAndSettle();

    expect(find.text('opened record-1'), findsOneWidget);
  });

  testWidgets('an empty queue names capture as the next step', (
    WidgetTester tester,
  ) async {
    await _pump(tester, snapshot: emptyQueueSnapshot);

    final AppEmptyState empty = tester.widget<AppEmptyState>(
      find.byType(AppEmptyState),
    );
    expect(empty.actionLabel, Copy.recordsEmptyAction);
    expect(empty.onAction, isNotNull);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('in a browser the queue says on-device reading is unavailable', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      snapshot: _mixed,
      extra: <Override>[
        onDeviceReadingUnavailableProvider.overrideWithValue(true),
      ],
    );

    expect(
      find.widgetWithText(AppBanner, Copy.ocrBrowserUnavailable),
      findsOneWidget,
    );
  });

  testWidgets('the queue scrolls whole and keeps 48dp labelled targets at '
      '200 percent text', (WidgetTester tester) async {
    await _pump(tester, snapshot: _mixed);

    await expectNoA11yIssues(tester);
  });

  testWidgets('an undecided template opens the choice sheet and applies the '
      'chosen id', (WidgetTester tester) async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(id: 'job-1', recordId: 'record-1'),
    );
    final List<TemplateChoice> applied = <TemplateChoice>[];
    const QueueSnapshot snapshot = (
      unprocessed: 0,
      queued: 1,
      failed: 0,
      requestsToday: 0,
      imagesToday: 0,
      requestCap: 20,
      groups: <QueueGroup>[],
    );
    await _pump(
      tester,
      snapshot: snapshot,
      repository: repository,
      extra: <Override>[
        processingStageWorkProvider.overrideWith((_) {
          return (JobStage stage, ProcessingJob _, CancellationToken _) async {
            if (stage == JobStage.detect && applied.isEmpty) {
              return const TemplateChoiceNeeded(
                recordId: 'record-1',
                projectId: 'project-1',
                shortlist: <({String templateId, String label})>[
                  (templateId: 'pump', label: 'Pump'),
                  (templateId: 'motor', label: 'Motor'),
                ],
              );
            }
            return null;
          };
        }),
        processingTemplateChoiceProvider.overrideWith((_) {
          return (TemplateChoiceNeeded _, TemplateChoice choice) async {
            applied.add(choice);
            return const Success<void>(null);
          };
        }),
      ],
    );

    await tester.tap(find.text(Copy.queueProcessAll));
    await _pumpUntil(tester, find.text('Motor').hitTestable());
    expect(find.text(Copy.templateChoiceTitle), findsOneWidget);
    expect(find.text(Copy.templateChoiceOther), findsOneWidget);
    await tester.tap(find.text('Motor'));
    await _pumpUntil(tester, find.text(Copy.queueSummary(1, 0)));

    expect(applied, <TemplateChoice>[(templateId: 'motor', pin: true)]);
  });

  testWidgets('tapping groups picks them and Process selected runs them', (
    WidgetTester tester,
  ) async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    const QueueSnapshot snapshot = (
      unprocessed: 6,
      queued: 0,
      failed: 0,
      requestsToday: 0,
      imagesToday: 0,
      requestCap: 20,
      groups: <QueueGroup>[
        (label: 'Kampala / Plant room', records: 3),
        (label: 'Kampala / Store', records: 2),
        (label: 'Unassigned', records: 1),
      ],
    );
    await _pump(tester, snapshot: snapshot, repository: repository);
    expect(find.text(Copy.queueProcessSelected), findsNothing);

    for (final String label in <String>[
      'Kampala / Plant room',
      'Kampala / Store',
      'Unassigned',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    // A second tap puts a group back.
    await tester.tap(find.text('Unassigned'));
    await tester.pumpAndSettle();
    expect(repository.queuedGroups, isEmpty, reason: 'a tap only picks');

    await tester.tap(find.text(Copy.queueProcessSelected));
    await tester.pumpAndSettle();

    expect(repository.queuedGroups.single.toSet(), <String>{
      'Kampala / Plant room',
      'Kampala / Store',
    });
    expect(
      find.text(Copy.queueProcessSelected),
      findsNothing,
      reason: 'running a selection clears it',
    );
  });
}

/// A queue with two failures, one named and one numbered, and two groups.
const QueueSnapshot _mixed = (
  unprocessed: 38,
  queued: 12,
  failed: 2,
  requestsToday: 3,
  imagesToday: 8,
  requestCap: 20,
  groups: <QueueGroup>[
    (label: 'Kampala / Plant room', records: 12),
    (label: 'Kampala / Store', records: 17),
  ],
);

const List<QueueFailure> _mixedFailures = <QueueFailure>[
  (
    job: ProcessingJob(
      id: 'job-1',
      recordId: 'record-1',
      status: JobStatus.failed,
      lastError: '401 authentication failed',
    ),
    name: 'Main pump',
    number: 4,
  ),
  (
    job: ProcessingJob(
      id: 'job-2',
      recordId: 'record-2',
      status: JobStatus.failed,
    ),
    name: '',
    number: 12,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required QueueSnapshot snapshot,
  FakeProcessingRepository? repository,
  List<Override> extra = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        queueFailurePageProvider.overrideWith(
          (Ref ref, query) => Stream<QueueFailurePage>.value(
            const QueueFailurePage(items: _mixedFailures),
          ),
        ),
        queueSnapshotProvider.overrideWith(
          (Ref ref) => Stream<QueueSnapshot>.value(snapshot),
        ),
        if (repository != null)
          processingRepositoryProvider.overrideWith((_) => repository),
        ...extra,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const QueueScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps frames until [finder] matches. A busy primary action spins, so the
/// screen never settles while a batch is open.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 100 && finder.evaluate().isEmpty; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(finder, findsWidgets);
}
