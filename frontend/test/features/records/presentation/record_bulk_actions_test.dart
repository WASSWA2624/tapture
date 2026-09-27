import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/processing.dart'
    show
        JobStatus,
        ProcessingJob,
        processingEgressSummaryProvider,
        processingRepositoryProvider;
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_bulk_actions.dart';
import 'package:tapture/features/records/presentation/record_selection.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_processing_repository.dart';
import '../fakes/fake_record_repository.dart';

const String _project = 'project-1';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

/// A bar this wide keeps approve and delete in reach and tucks the rest.
const double _narrow = 360;

/// A bar this wide shows every action.
const double _wide = 1024;

void main() {
  late FakeRecordRepository records;
  late FakeProcessingRepository processing;

  setUp(() {
    records = FakeRecordRepository();
    processing = FakeProcessingRepository();
  });

  tearDown(() {
    records.dispose();
    processing.dispose();
  });

  /// Records `record-1` up of [_project], each in [status].
  List<String> seed(
    int count, {
    RecordStatus status = RecordStatus.needsReview,
  }) {
    return <String>[
      for (int n = 1; n <= count; n++)
        records.seedEntry(aRecordEntry(id: 'record-$n', status: status)),
    ];
  }

  List<Override> overridesFor({
    RecordRepository? repository,
    bool offline = false,
    List<Override> extra = const <Override>[],
  }) {
    return <Override>[
      recordRepositoryProvider.overrideWith((Ref _) => repository ?? records),
      processingRepositoryProvider.overrideWith((Ref _) => processing),
      projectSettingsStoreProvider.overrideWith(
        (Ref _) => SettingsStore.fake(),
      ),
      offlineNowProvider.overrideWith((Ref _) => offline),
      ...extra,
    ];
  }

  /// The bar at the foot of a page [width] wide.
  Future<void> pump(
    WidgetTester tester, {
    double width = _narrow,
    List<String> selectable = const <String>[],
    ValueChanged<List<String>>? onExport,
    RecordRepository? repository,
    bool offline = false,
    List<Override> extra = const <Override>[],
  }) async {
    tester.view.physicalSize = Size(width, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: overridesFor(
          repository: repository,
          offline: offline,
          extra: extra,
        ),
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                const Expanded(child: SizedBox.expand()),
                RecordBulkActions(
                  projectId: _project,
                  selectable: selectable,
                  onExport: onExport,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer scopeOf(WidgetTester tester) {
    return ProviderScope.containerOf(
      tester.element(find.byType(RecordBulkActions)),
    );
  }

  Future<void> tick(WidgetTester tester, List<String> ids) async {
    scopeOf(
      tester,
    ).read(recordSelectionProvider(_project).notifier).selectAll(ids);
    await tester.pumpAndSettle();
  }

  Set<String> ticked(WidgetTester tester) {
    return scopeOf(tester).read(recordSelectionProvider(_project));
  }

  Finder control(String key) => find.byKey(ValueKey<String>(key));

  Finder bar() => control('records-bulk-bar');

  AppIconButton button(WidgetTester tester, String key) {
    return tester.widget<AppIconButton>(control(key));
  }

  Finder inDialog(String text) {
    return find.descendant(
      of: find.byType(AppDialog),
      matching: find.text(text),
    );
  }

  /// Opens the narrow bar's overflow and chooses [label].
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(control('records-bulk-more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, String label) async {
    await tester.tap(inDialog(label));
    await tester.pumpAndSettle();
  }

  group('with nothing ticked', () {
    testWidgets('draws nothing', (WidgetTester tester) async {
      seed(3);
      await pump(tester, selectable: const <String>['record-1']);

      expect(bar(), findsNothing);
      expect(find.byType(AppIconButton), findsNothing);
      expect(find.byType(AppOverflowMenu), findsNothing);
      expect(tester.getSize(find.byType(RecordBulkActions)).height, 0);
    });

    testWidgets('clear unticks everything and the bar goes', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester);
      await tick(tester, ids);
      expect(bar(), findsOneWidget);

      await tester.tap(control('records-bulk-clear'));
      await tester.pumpAndSettle();

      expect(ticked(tester), isEmpty);
      expect(bar(), findsNothing);
      expect(records.writes, isEmpty);
    });
  });

  group('the bar', () {
    testWidgets('names how many records are ticked', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester);

      await tick(tester, ids.sublist(0, 1));
      expect(find.text(Copy.recordsSelectedCount(1)), findsOneWidget);
      expect(Copy.recordsSelectedCount(1), '1 selected');

      await tick(tester, ids);
      expect(find.text(Copy.recordsSelectedCount(3)), findsOneWidget);
      expect(Copy.recordsSelectedCount(3), '3 selected');
    });

    testWidgets('select all shown ticks every record the list has shown', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(4);
      await pump(tester, width: _wide, selectable: ids);
      await tick(tester, ids.sublist(0, 1));

      await tester.tap(control('records-bulk-select-all'));
      await tester.pumpAndSettle();

      expect(ticked(tester), ids.toSet());
      expect(find.text(Copy.recordsSelectedCount(4)), findsOneWidget);
      // Nothing is left to tick, so the action goes.
      expect(control('records-bulk-select-all'), findsNothing);
    });

    testWidgets('keeps approve and delete in reach on a narrow bar', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester, selectable: <String>[...ids, 'record-9']);
      await tick(tester, ids);

      expect(control('records-bulk-approve'), findsOneWidget);
      expect(control('records-bulk-delete'), findsOneWidget);
      expect(control('records-bulk-archive'), findsNothing);

      await tester.tap(control('records-bulk-more'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordsSelectAllShown), findsOneWidget);
      expect(find.text(Copy.recordsArchiveLabel(3)), findsOneWidget);
      expect(find.text(Copy.recordsReprocessLabel(3)), findsOneWidget);
      expect(find.text(Copy.recordsExportLabel(3)), findsOneWidget);
    });

    testWidgets('shows every action on a wide bar', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester, width: _wide, selectable: <String>[...ids, 'x']);
      await tick(tester, ids);

      for (final String key in <String>[
        'records-bulk-clear',
        'records-bulk-select-all',
        'records-bulk-approve',
        'records-bulk-archive',
        'records-bulk-reprocess',
        'records-bulk-export',
        'records-bulk-delete',
      ]) {
        expect(control(key), findsOneWidget, reason: key);
      }
      expect(control('records-bulk-more'), findsNothing);
    });

    testWidgets('every control is a labelled 48dp target naming the count', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      await pump(tester, width: _wide);
      await tick(tester, ids);
      final SemanticsHandle handle = tester.ensureSemantics();

      final Map<String, String> labels = <String, String>{
        'records-bulk-clear': Copy.recordsClearSelection,
        'records-bulk-approve': Copy.recordsApproveLabel(2),
        'records-bulk-archive': Copy.recordsArchiveLabel(2),
        'records-bulk-reprocess': Copy.recordsReprocessLabel(2),
        'records-bulk-export': Copy.recordsExportLabel(2),
        'records-bulk-delete': Copy.recordsDeleteLabel(2),
      };
      for (final MapEntry<String, String> entry in labels.entries) {
        expect(control(entry.key), meetsTapTarget(), reason: entry.key);
        expect(
          control(entry.key),
          hasSemanticLabel(entry.value),
          reason: entry.key,
        );
        expect(button(tester, entry.key).tooltip, entry.value);
      }
      handle.dispose();
    });

    testWidgets(
      'meets the accessibility guidelines and reflows at 200 percent text',
      (WidgetTester tester) async {
        final List<String> ids = seed(12);
        await pump(tester, selectable: ids);
        await tick(tester, ids.sublist(0, 11));

        await expectNoA11yIssues(tester);
      },
    );
  });

  group('approve', () {
    testWidgets(
      'approves every ticked record, says how many, and unticks them',
      (WidgetTester tester) async {
        final List<String> ids = seed(3);
        await pump(tester);
        await tick(tester, ids);

        await tester.tap(control('records-bulk-approve'));
        await tester.pumpAndSettle();

        for (final String id in ids) {
          expect(records.entryOf(id)!.status, RecordStatus.approved);
        }
        expect(find.text(Copy.recordsApproved(3)), findsOneWidget);
        expect(ticked(tester), isEmpty);
        expect(bar(), findsNothing);
      },
    );

    testWidgets(
      'follows the lifecycle: a captured record is reported, left as it was, and stays ticked',
      (WidgetTester tester) async {
        final List<String> ready = seed(2);
        final String captured = records.seedEntry(
          aRecordEntry(id: 'record-3', status: RecordStatus.captured),
        );
        final RecordEntry before = records.entryOf(captured)!;
        final int history = records.historyOf(captured).length;
        await pump(tester);
        await tick(tester, <String>[...ready, captured]);

        await tester.tap(control('records-bulk-approve'));
        await tester.pumpAndSettle();

        for (final String id in ready) {
          expect(records.entryOf(id)!.status, RecordStatus.approved);
        }
        expect(records.entryOf(captured), before);
        expect(records.historyOf(captured), hasLength(history));
        expect(
          find.text(
            Copy.recordsBulkOutcome(
              done: Copy.recordsApproved(2),
              notDone: Copy.recordsNotApproved(1),
            ),
          ),
          findsOneWidget,
        );
        expect(ticked(tester), <String>{captured});
        expect(find.text(Copy.recordsSelectedCount(1)), findsOneWidget);
      },
    );
  });

  group('a partial failure', () {
    testWidgets(
      'leaves the successful records changed and the failed one untouched, and names both counts',
      (WidgetTester tester) async {
        final List<String> ids = seed(3);
        records.failuresById['record-2'] = _locked;
        final RecordEntry untouched = records.entryOf('record-2')!;
        final int history = records.historyOf('record-2').length;
        await pump(tester);
        await tick(tester, ids);

        await choose(tester, Copy.recordsArchiveLabel(3));
        expect(inDialog(Copy.recordsArchiveTitle(3)), findsOneWidget);
        await confirm(tester, Copy.recordsArchiveConfirm);

        expect(records.entryOf('record-1')!.status, RecordStatus.archived);
        expect(records.entryOf('record-3')!.status, RecordStatus.archived);
        expect(records.entryOf('record-2'), untouched);
        expect(records.entryOf('record-2')!.status, RecordStatus.needsReview);
        expect(records.historyOf('record-2'), hasLength(history));
        final String summary = Copy.recordsBulkOutcome(
          done: Copy.recordsArchived(2),
          notDone: Copy.recordsNotArchived(1),
        );
        expect(find.text(summary), findsOneWidget);
        expect(summary, '2 records archived. 1 record could not be archived.');
        expect(ticked(tester), <String>{'record-2'});
        expect(find.text(Copy.recordsSelectedCount(1)), findsOneWidget);
      },
    );
  });

  group('a store that refuses every write', () {
    testWidgets('says why for one record and keeps it ticked', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(1);
      records.writeFailure = _locked;
      await pump(tester);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-approve'));
      await tester.pumpAndSettle();

      expect(find.text(_locked.message), findsOneWidget);
      expect(ticked(tester), ids.toSet());
      expect(records.entryOf('record-1')!.status, RecordStatus.needsReview);
    });

    testWidgets('counts several and keeps them ticked', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      records.writeFailure = _locked;
      await pump(tester);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-approve'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordsNotApproved(3)), findsOneWidget);
      expect(ticked(tester), ids.toSet());
      expect(records.writes, isEmpty);
    });
  });

  group('archive', () {
    testWidgets('names the count in its confirm, and cancel changes nothing', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester);
      await tick(tester, ids);

      await choose(tester, Copy.recordsArchiveLabel(3));

      expect(inDialog(Copy.recordsArchiveTitle(3)), findsOneWidget);
      expect(inDialog(Copy.recordsArchiveMessage(3)), findsOneWidget);
      expect(Copy.recordsArchiveTitle(3), 'Archive 3 records?');
      await confirm(tester, Copy.cancel);

      expect(records.writes, isEmpty);
      expect(ticked(tester), ids.toSet());
    });

    testWidgets('archives every ticked record once confirmed', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      await pump(tester, width: _wide);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-archive'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.recordsArchiveConfirm);

      for (final String id in ids) {
        expect(records.entryOf(id)!.status, RecordStatus.archived);
      }
      expect(find.text(Copy.recordsArchived(2)), findsOneWidget);
      expect(ticked(tester), isEmpty);
    });
  });

  group('delete', () {
    testWidgets(
      'names the count in its confirm, moves every record to the bin and unticks them',
      (WidgetTester tester) async {
        final List<String> ids = seed(3);
        await pump(tester);
        await tick(tester, ids);

        await tester.tap(control('records-bulk-delete'));
        await tester.pumpAndSettle();
        expect(inDialog(Copy.recordsDeleteTitle(3)), findsOneWidget);
        await confirm(tester, Copy.recordsDeleteConfirm);

        for (final String id in ids) {
          expect(records.isTombstoned(id), isTrue);
          expect(records.entryOf(id)!.status, RecordStatus.deleted);
        }
        expect(find.text(Copy.recordsDeleted(3)), findsOneWidget);
        expect(ticked(tester), isEmpty);
      },
    );

    testWidgets('keeps a record that could not be deleted ticked', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      records.failuresById['record-3'] = _locked;
      await pump(tester);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-delete'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.recordsDeleteConfirm);

      expect(records.isTombstoned('record-1'), isTrue);
      expect(records.isTombstoned('record-2'), isTrue);
      expect(records.isTombstoned('record-3'), isFalse);
      expect(
        find.text(Copy.recordsDeletedPartly(deleted: 2, failed: 1)),
        findsOneWidget,
      );
      expect(ticked(tester), <String>{'record-3'});
    });
  });

  group('process again', () {
    testWidgets(
      'names the count, queues each record, runs the queue, and unticks the queued ones',
      (WidgetTester tester) async {
        final List<String> ids = seed(3);
        for (final String id in ids) {
          processing.recordStatuses[id] = RecordStatus.needsReview;
        }
        processing.requeueFailures['record-2'] = _locked;
        await pump(tester);
        await tick(tester, ids);

        await choose(tester, Copy.recordsReprocessLabel(3));
        expect(inDialog(Copy.recordsReprocessTitle(3)), findsOneWidget);
        expect(inDialog(Copy.recordsReprocessMessage(3)), findsOneWidget);
        await confirm(tester, Copy.recordsReprocessConfirm);

        expect(processing.requeued, <String>['record-1', 'record-3']);
        expect(
          find.text(
            Copy.recordsBulkOutcome(
              done: Copy.recordsRequeued(2),
              notDone: Copy.recordsNotRequeued(1),
            ),
          ),
          findsOneWidget,
        );
        expect(ticked(tester), <String>{'record-2'});
        // The queue ran once for the project and finished both jobs.
        expect(processing.queuedGroups, hasLength(1));
        final Map<String, JobStatus> jobs = <String, JobStatus>{
          for (final ProcessingJob job in processing.stored)
            job.recordId: job.status,
        };
        expect(jobs, <String, JobStatus>{
          'record-1': JobStatus.completed,
          'record-3': JobStatus.completed,
        });
      },
    );

    testWidgets('offline, queues the records and leaves them waiting', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      await pump(tester, offline: true, width: _wide);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-reprocess'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.recordsReprocessConfirm);

      expect(processing.requeued, ids);
      expect(processing.queuedGroups, isEmpty);
      expect(
        <JobStatus>{
          for (final ProcessingJob job in processing.stored) job.status,
        },
        <JobStatus>{JobStatus.queued},
      );
      expect(
        find.text(
          '${Copy.recordsRequeued(2)}. ${Copy.recordsRequeuedOffline(2)}',
        ),
        findsOneWidget,
      );
      expect(ticked(tester), isEmpty);
    });

    testWidgets(
      'shows what would leave the device before the first online step, and runs once it is accepted',
      (WidgetTester tester) async {
        final List<String> ids = seed(2);
        await pump(
          tester,
          width: _wide,
          extra: <Override>[
            processingEgressSummaryProvider.overrideWith(
              (Ref _) =>
                  (ProcessingJob _) async =>
                      (imageCount: 2, payloadBytes: 2048),
            ),
          ],
        );
        await tick(tester, ids);

        await tester.tap(control('records-bulk-reprocess'));
        await tester.pumpAndSettle();
        await confirm(tester, Copy.recordsReprocessConfirm);

        expect(inDialog(Copy.egressTitle), findsOneWidget);
        await confirm(tester, Copy.egressSend);

        expect(
          <JobStatus>{
            for (final ProcessingJob job in processing.stored) job.status,
          },
          <JobStatus>{JobStatus.completed},
        );
        expect(find.byType(AppDialog), findsNothing);
      },
    );

    testWidgets('a declined preview leaves the queued records waiting', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      await pump(
        tester,
        width: _wide,
        extra: <Override>[
          processingEgressSummaryProvider.overrideWith(
            (Ref _) =>
                (ProcessingJob _) async => (imageCount: 1, payloadBytes: 512),
          ),
        ],
      );
      await tick(tester, ids);

      await tester.tap(control('records-bulk-reprocess'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.recordsReprocessConfirm);
      await confirm(tester, Copy.egressDecline);

      expect(processing.requeued, ids);
      expect(
        <JobStatus>{
          for (final ProcessingJob job in processing.stored) job.status,
        },
        <JobStatus>{JobStatus.queued},
      );
      expect(find.byType(AppDialog), findsNothing);
    });

    testWidgets('cancel queues nothing', (WidgetTester tester) async {
      final List<String> ids = seed(2);
      await pump(tester, width: _wide);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-reprocess'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.cancel);

      expect(processing.requeued, isEmpty);
      expect(processing.queuedGroups, isEmpty);
      expect(ticked(tester), ids.toSet());
    });
  });

  group('export', () {
    testWidgets(
      'names the count and what the package holds, then hands the ticked records over',
      (WidgetTester tester) async {
        final List<String> ids = seed(2);
        final List<List<String>> exported = <List<String>>[];
        await pump(tester, onExport: exported.add);
        await tick(tester, ids);

        await choose(tester, Copy.recordsExportLabel(2));
        expect(inDialog(Copy.recordsExportTitle(2)), findsOneWidget);
        expect(inDialog(Copy.recordsExportMessage(2)), findsOneWidget);
        expect(Copy.recordsExportMessage(2), contains('the 2 selected'));
        await confirm(tester, Copy.recordsExportConfirm);

        expect(exported, <List<String>>[ids]);
        expect(records.writes, isEmpty);
      },
    );

    testWidgets('cancel exports nothing', (WidgetTester tester) async {
      final List<String> ids = seed(2);
      final List<List<String>> exported = <List<String>>[];
      await pump(tester, width: _wide, onExport: exported.add);
      await tick(tester, ids);

      await tester.tap(control('records-bulk-export'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.cancel);

      expect(exported, isEmpty);
    });

    testWidgets('without a handler, opens the project export page', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      tester.view.physicalSize =
          const Size(_wide, 800) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => const Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: SizedBox.expand()),
                  RecordBulkActions(projectId: _project),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/projects/:projectId/exports',
            builder: (BuildContext _, GoRouterState state) => Scaffold(
              body: Text('export ${state.pathParameters['projectId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (int _, Object _) => null,
          overrides: overridesFor(),
          child: MaterialApp.router(
            theme: buildTheme(brightness: Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tick(tester, ids);

      await tester.tap(control('records-bulk-export'));
      await tester.pumpAndSettle();
      await confirm(tester, Copy.recordsExportConfirm);

      expect(find.text('export $_project'), findsOneWidget);
    });
  });

  group('while an action runs', () {
    testWidgets('holds every control, then gives them back', (
      WidgetTester tester,
    ) async {
      final _HeldTransition held = _HeldTransition();
      await pump(tester, repository: held);
      await tick(tester, <String>['record-1', 'record-2']);

      await tester.tap(control('records-bulk-approve'));
      await tester.pump();

      expect(button(tester, 'records-bulk-approve').onPressed, isNull);
      expect(button(tester, 'records-bulk-delete').onPressed, isNull);
      expect(button(tester, 'records-bulk-clear').onPressed, isNull);
      expect(
        tester.widget<AppOverflowMenu>(control('records-bulk-more')).items,
        isEmpty,
      );

      held.release.complete(const Success<void>(null));
      await tester.pumpAndSettle();

      expect(held.asked, <String>['record-1', 'record-2']);
      expect(ticked(tester), isEmpty);
      expect(find.text(Copy.recordsApproved(2)), findsOneWidget);
    });
  });
}

/// A store whose status moves wait for the test to release them.
final class _HeldTransition implements RecordRepository {
  final Completer<Result<void>> release = Completer<Result<void>>();
  final List<String> asked = <String>[];

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) {
    asked.add(id);
    return release.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
