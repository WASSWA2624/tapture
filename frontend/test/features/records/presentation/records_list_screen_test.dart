import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show currentProjectProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_selection.dart';
import 'package:tapture/features/records/presentation/records_list_controller.dart';
import 'package:tapture/features/records/presentation/records_list_view.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../fakes/fake_record_repository.dart';
import 'records_list_harness.dart';

const StorageFailure _unreadable = StorageFailure(
  message: 'The records could not be read.',
  recoveryAction: 'Try again in a moment.',
);

void main() {
  late FakeRecordRepository fake;
  late CountingRecords records;

  setUp(() {
    fake = FakeRecordRepository();
    records = CountingRecords(fake);
  });

  tearDown(() {
    fake.dispose();
  });

  final int pageSize = AppConstants.lists.pageSize;

  Finder searchInput() => find.descendant(
    of: find.byKey(const ValueKey<String>('records-search')),
    matching: find.byType(EditableText),
  );

  Future<void> typeSearch(WidgetTester tester, String text) async {
    await tester.enterText(searchInput(), text);
    await tester.pump(AppConstants.interaction.debounce);
    await tester.pumpAndSettle();
  }

  RecordsListController controllerOf(WidgetTester tester) {
    return listContainer(
      tester,
    ).read(recordsListControllerProvider('project-1').notifier);
  }

  group('paging', () {
    testWidgets('only a page of rows is built and only one page is read', (
      WidgetTester tester,
    ) async {
      fake.seedMany(500);
      await pumpRecordsList(tester, records: records);

      final int built = find
          .byWidgetPredicate(
            (Widget widget) =>
                widget is AppListTile &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'record-row-',
                ),
            skipOffstage: false,
          )
          .evaluate()
          .length;
      expect(built, greaterThan(0));
      expect(built, lessThan(pageSize));
      expect(records.pageReads, <({int offset, int limit})>[
        (offset: 0, limit: pageSize),
      ]);
      expect(find.text('Record 500'), findsOneWidget);
      expect(find.text('Record 1', skipOffstage: false), findsNothing);
    });

    testWidgets('the next page is read when the list scrolls to it, and '
        'pages scrolled away are let go', (WidgetTester tester) async {
      fake.seedMany(500);
      await pumpRecordsList(tester, records: records);

      await tester.scrollUntilVisible(
        find.text('Record 440'),
        600,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey<String>('records-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record 440'), findsOneWidget);
      expect(
        records.pageReads,
        contains((offset: pageSize, limit: pageSize)),
      );

      await tester.scrollUntilVisible(
        find.text('Record 250'),
        1200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey<String>('records-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record 250'), findsOneWidget);
      for (final ({int offset, int limit}) read in records.pageReads) {
        expect(read.limit, pageSize);
      }
      // The first page is off screen and no longer read.
      expect(records.livePages, lessThanOrEqualTo(2));
      expect(
        records.mostLivePages,
        lessThanOrEqualTo(AppConstants.scrolling.livePages),
      );
    });

    testWidgets('a row whose page is still loading shows a skeleton', (
      WidgetTester tester,
    ) async {
      fake.seedMany(120);
      records.heldOffsets.add(pageSize);
      await pumpRecordsList(tester, records: records);

      final ScrollableState list = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('records-list')),
          matching: find.byType(Scrollable),
        ),
      );
      list.position.jumpTo(list.position.maxScrollExtent / 2);
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel(Copy.loading), findsWidgets);
      expect(find.text('Record 60'), findsNothing);
    });

    testWidgets('a page that cannot be read says why and reads again on tap', (
      WidgetTester tester,
    ) async {
      fake.seedMany(120);
      records.failedOffsets[pageSize] = _unreadable;
      await pumpRecordsList(tester, records: records);

      final ScrollableState list = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('records-list')),
          matching: find.byType(Scrollable),
        ),
      );
      list.position.jumpTo(list.position.maxScrollExtent / 2);
      await tester.pumpAndSettle();

      expect(find.text(_unreadable.message), findsWidgets);

      records.failedOffsets.clear();
      await tester.tap(find.text(_unreadable.message).first);
      await tester.pumpAndSettle();

      expect(find.text(_unreadable.message), findsNothing);
      expect(find.text('Record 60'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('while the count loads the list shows skeleton rows', (
      WidgetTester tester,
    ) async {
      records.holdCount = true;
      await pumpRecordsList(tester, records: records);

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
    });

    testWidgets('a project with no records offers to capture one', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpRecordsList(tester, records: records);

      expect(
        find.byKey(const ValueKey<String>('records-empty')),
        findsOneWidget,
      );
      expect(find.text(Copy.recordsEmptyHeadline), findsOneWidget);

      await tester.tap(find.text(Copy.recordsEmptyAction));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.path,
        RoutePaths.projectCapture('project-1'),
      );
    });

    testWidgets('with no project open the page offers to open one', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpRecordsList(
        tester,
        records: records,
        location: RoutePaths.records,
      );

      expect(
        find.byKey(const ValueKey<String>('records-no-project')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('route-records')), findsOne);
      expect(records.countReads, 0);

      await tester.tap(find.text(Copy.recordsOpenProject));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, RoutePaths.projects);
    });

    testWidgets('the Records destination lists the open project and opens '
        'records there', (WidgetTester tester) async {
      fake.seedMany(3);
      final GoRouter router = await pumpRecordsList(
        tester,
        records: records,
        location: RoutePaths.records,
      );
      listContainer(
        tester,
      ).read(currentProjectProvider.notifier).open('project-1');
      await tester.pumpAndSettle();

      expect(find.text('Record 3'), findsOneWidget);

      await tester.tap(find.text('Record 2'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, RoutePaths.record('project-1-record-2'));
    });

    testWidgets('a search that matches nothing says so and clears in a tap', (
      WidgetTester tester,
    ) async {
      fake.seedMany(3);
      await pumpRecordsList(tester, records: records);

      await typeSearch(tester, 'zebra');

      expect(
        find.byKey(const ValueKey<String>('records-no-match')),
        findsOneWidget,
      );
      expect(find.text(Copy.recordsNoMatch('zebra')), findsOneWidget);
      expect(find.text(Copy.searchNoMatchMessage), findsOneWidget);

      await tester.tap(find.text(Copy.recordsClearSearch));
      await tester.pumpAndSettle();

      expect(find.text('Record 3'), findsOneWidget);
      expect(tester.widget<EditableText>(searchInput()).controller.text, '');
    });

    testWidgets('filters that match nothing offer to clear them', (
      WidgetTester tester,
    ) async {
      fake.seedMany(3);
      await pumpRecordsList(tester, records: records);
      controllerOf(tester).applyFilter(
        RecordFilter.forStatus(RecordStatus.approved),
      );
      await tester.pumpAndSettle();

      expect(find.text(Copy.searchFilterNoMatchMessage), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('records-no-match')),
          matching: find.text(Copy.searchClearFilters),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record 3'), findsOneWidget);
    });

    testWidgets('a list that cannot be read shows the failure and retries', (
      WidgetTester tester,
    ) async {
      fake.seedMany(3);
      fake.readFailure = _unreadable;
      await pumpRecordsList(tester, records: records);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(_unreadable.message), findsOneWidget);

      fake.readFailure = null;
      await tester.tap(find.text(Copy.tryAgain));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsNothing);
      expect(find.text('Record 3'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('a row shows name, number, identifier, context, status and '
        'the first photo', (WidgetTester tester) async {
      fake.seedEntry(
        aRecordEntry(
          id: 'boiler',
          number: 7,
          name: 'Boiler',
          identifier: 'SN-1',
          context: const <String, String>{'site': 'North'},
          status: RecordStatus.needsReview,
          photos: 1,
        ),
      );
      await pumpRecordsList(tester, records: records);

      final AppListTile row = tester.widget<AppListTile>(rowOf('boiler'));
      expect(row.title, 'Boiler');
      expect(row.subtitle, '#7 · SN-1 · North');
      expect(row.status?.status, RecordStatus.needsReview);
      expect(
        find.descendant(of: rowOf('boiler'), matching: find.byType(RecordThumb)),
        findsOneWidget,
      );
    });

    testWidgets('a record nothing names yet is called by its number', (
      WidgetTester tester,
    ) async {
      fake.seedEntry(
        aRecordEntry(id: 'plain', number: 12, fields: const <String, String>{}),
      );
      await pumpRecordsList(tester, records: records);

      expect(
        tester.widget<AppListTile>(rowOf('plain')).title,
        Copy.recordsUntitled(12),
      );
      expect(
        find.descendant(of: rowOf('plain'), matching: find.byType(RecordThumb)),
        findsNothing,
      );
    });

    testWidgets('a tap opens the record and edit opens its capture page', (
      WidgetTester tester,
    ) async {
      fake.seedMany(2);
      final GoRouter router = await pumpRecordsList(tester, records: records);

      await tester.tap(find.text('Record 2'));
      await tester.pumpAndSettle();
      expect(
        router.state.uri.path,
        RoutePaths.projectRecord('project-1', 'project-1-record-2'),
      );

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('record-edit-project-1-record-1')),
      );
      await tester.pumpAndSettle();
      expect(
        router.state.uri.path,
        RoutePaths.projectRecordEdit('project-1', 'project-1-record-1'),
      );
    });

    testWidgets('delete confirms, then moves the record to the bin', (
      WidgetTester tester,
    ) async {
      fake.seedMany(2);
      await pumpRecordsList(tester, records: records);

      await tester.tap(
        find.byKey(const ValueKey<String>('record-delete-project-1-record-2')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text(Copy.recordsDeleteTitle(1)), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.text(Copy.recordsDeleteConfirm),
        ),
      );
      await tester.pumpAndSettle();

      expect(fake.isTombstoned('project-1-record-2'), isTrue);
      expect(rowOf('project-1-record-2'), findsNothing);
      expect(find.text('Record 1'), findsOneWidget);
    });

    testWidgets('long-press selects, and while selecting a tap selects too', (
      WidgetTester tester,
    ) async {
      fake.seedMany(3);
      final GoRouter router = await pumpRecordsList(tester, records: records);

      await tester.longPress(find.text('Record 3'));
      await tester.pumpAndSettle();

      final ProviderContainer container = listContainer(tester);
      expect(container.read(recordSelectionProvider('project-1')), <String>{
        'project-1-record-3',
      });
      expect(
        tester.widget<AppListTile>(rowOf('project-1-record-3')).selected,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey<String>('record-edit-project-1-record-2')),
        findsNothing,
      );

      await tester.tap(find.text('Record 2'));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.path,
        RoutePaths.projectRecords('project-1'),
      );
      expect(container.read(recordSelectionProvider('project-1')), <String>{
        'project-1-record-3',
        'project-1-record-2',
      });
    });
  });

  group('filters', () {
    void seedMixed() {
      fake.seedEntry(
        aRecordEntry(
          id: 'a',
          number: 1,
          name: 'Alpha',
          status: RecordStatus.needsReview,
          templateId: 'template-1',
        ),
      );
      fake.seedEntry(
        aRecordEntry(
          id: 'b',
          number: 2,
          name: 'Bravo',
          status: RecordStatus.needsReview,
          templateId: 'template-2',
        ),
      );
      fake.seedEntry(
        aRecordEntry(
          id: 'c',
          number: 3,
          name: 'Charlie',
          status: RecordStatus.approved,
          templateId: 'template-1',
        ),
      );
      fake.seedTemplate('template-1', name: 'Boilers');
      fake.seedTemplate('template-2', name: 'Pumps');
    }

    testWidgets('filters combine, each chip removes its own value, and '
        'clear filters removes them all in one tap', (
      WidgetTester tester,
    ) async {
      seedMixed();
      await pumpRecordsList(tester, records: records);
      await typeSearch(tester, 'a');

      controllerOf(tester).applyFilter(
        const RecordFilter(
          statuses: <RecordStatus>{RecordStatus.needsReview},
          templateIds: <String>{'template-1'},
        ),
      );
      await tester.pumpAndSettle();

      expect(visibleTitles(tester), <String>['Alpha']);
      expect(
        find.byKey(const ValueKey<String>('records-chip-status-needsReview')),
        findsOneWidget,
      );
      expect(
        find.text(Copy.recordsChipTemplate('Boilers')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('records-chip-status-needsReview')),
          matching: find.bySemanticsLabel(
            Copy.dismissChip(Copy.statusNeedsReview),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(visibleTitles(tester), <String>['Charlie', 'Alpha']);
      expect(
        find.byKey(const ValueKey<String>('records-chip-status-needsReview')),
        findsNothing,
      );

      controllerOf(tester).applyFilter(
        const RecordFilter(
          statuses: <RecordStatus>{RecordStatus.approved},
          templateIds: <String>{'template-2'},
          flags: <RecordFlag>{RecordFlag.hasPhotos},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('records-no-match')), findsOne);
      expect(find.byType(AppChip), findsNWidgets(4));

      await tester.tap(
        find.byKey(const ValueKey<String>('records-clear-filters')),
      );
      await tester.pumpAndSettle();

      expect(visibleTitles(tester), <String>['Charlie', 'Bravo', 'Alpha']);
      expect(
        find.byKey(const ValueKey<String>('records-active-filters')),
        findsNothing,
      );
      // The search is its field's to clear.
      expect(controllerOf(tester).state.filter.search, 'a');
      expect(controllerOf(tester).state.filter.activeCount, 0);
    });

    testWidgets('the route filter lists one status for the visit and leaves '
        'the remembered filter alone', (WidgetTester tester) async {
      seedMixed();
      final SettingsStore settings = SettingsStore.fake();
      await pumpRecordsList(
        tester,
        records: records,
        settings: settings,
        location:
            '${RoutePaths.projectRecords('project-1')}?'
            '${RoutePaths.filterQuery}=needsReview',
      );

      expect(visibleTitles(tester), <String>['Bravo', 'Alpha']);
      expect(
        find.byKey(const ValueKey<String>('records-chip-status-needsReview')),
        findsOneWidget,
      );
      expect(settings.read(SettingKeys.recordListCriteria), '{}');
      expect(find.text('Charlie'), findsNothing);
    });
  });

  group('sort', () {
    testWidgets('sorting orders the rows both ways on every key', (
      WidgetTester tester,
    ) async {
      // Number, capture date and name each give a different order.
      fake.seedEntry(
        aRecordEntry(
          id: 'x',
          number: 1,
          name: 'Charlie',
          capturedAt: DateTime.utc(2026, 9, 2),
        ),
      );
      fake.seedEntry(
        aRecordEntry(
          id: 'y',
          number: 2,
          name: 'alpha',
          capturedAt: DateTime.utc(2026, 9, 3),
        ),
      );
      fake.seedEntry(
        aRecordEntry(
          id: 'z',
          number: 3,
          name: 'Bravo',
          capturedAt: DateTime.utc(2026, 9, 1),
        ),
      );
      await pumpRecordsList(tester, records: records);

      final Map<String, List<String>> expected = <String, List<String>>{
        Copy.recordsSortNumberDescending: <String>['Bravo', 'alpha', 'Charlie'],
        Copy.recordsSortNumberAscending: <String>['Charlie', 'alpha', 'Bravo'],
        Copy.recordsSortCapturedDescending: <String>[
          'alpha',
          'Charlie',
          'Bravo',
        ],
        Copy.recordsSortCapturedAscending: <String>[
          'Bravo',
          'Charlie',
          'alpha',
        ],
        Copy.recordsSortNameAscending: <String>['alpha', 'Bravo', 'Charlie'],
        Copy.recordsSortNameDescending: <String>['Charlie', 'Bravo', 'alpha'],
      };
      expect(visibleTitles(tester), expected[Copy.recordsSortNumberDescending]);

      for (final MapEntry<String, List<String>> order in expected.entries) {
        await tester.tap(find.byKey(const ValueKey<String>('records-sort')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(order.key));
        await tester.pumpAndSettle();

        expect(visibleTitles(tester), order.value, reason: order.key);
      }
    });
  });

  group('remembered per project', () {
    testWidgets('filter and sort survive a restart, per project, and the '
        'search does not', (WidgetTester tester) async {
      fake.seedMany(3);
      fake.seedMany(2, projectId: 'project-2');
      final SettingsStore settings = SettingsStore.fake();

      // First run: project 1 filtered to needs review and sorted by name;
      // project 2 only sorted by capture date.
      await pumpRecordsList(tester, records: records, settings: settings);
      await typeSearch(tester, 'Record');
      final ProviderContainer first = listContainer(tester);
      first
          .read(recordsListControllerProvider('project-1').notifier)
          .applyFilter(RecordFilter.forStatus(RecordStatus.needsReview));
      first
          .read(recordsListControllerProvider('project-1').notifier)
          .applySort(
            const RecordSort(key: RecordSortKey.name, ascending: true),
          );
      final ProviderSubscription<RecordsListCriteria> second = first.listen(
        recordsListControllerProvider('project-2'),
        (RecordsListCriteria? _, RecordsListCriteria _) {},
      );
      first
          .read(recordsListControllerProvider('project-2').notifier)
          .applySort(
            const RecordSort(key: RecordSortKey.capturedAt, ascending: true),
          );
      second.close();
      await tester.pumpAndSettle();

      // Restart: a new app over the same stored settings.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpRecordsList(
        tester,
        records: CountingRecords(fake),
        settings: settings,
      );

      final ProviderContainer restarted = listContainer(tester);
      final RecordsListCriteria one = restarted.read(
        recordsListControllerProvider('project-1'),
      );
      expect(one.filter, RecordFilter.forStatus(RecordStatus.needsReview));
      expect(
        one.sort,
        const RecordSort(key: RecordSortKey.name, ascending: true),
      );
      expect(one.filter.search, isEmpty);
      expect(
        find.byKey(const ValueKey<String>('records-chip-status-needsReview')),
        findsOneWidget,
      );
      expect(tester.widget<EditableText>(searchInput()).controller.text, '');

      final ProviderSubscription<RecordsListCriteria> two = restarted.listen(
        recordsListControllerProvider('project-2'),
        (RecordsListCriteria? _, RecordsListCriteria _) {},
      );
      expect(two.read().filter, RecordFilter.none);
      expect(
        two.read().sort,
        const RecordSort(key: RecordSortKey.capturedAt, ascending: true),
      );
      two.close();

      final Map<String, Object?> stored =
          jsonDecode(settings.read(SettingKeys.recordListCriteria))
              as Map<String, Object?>;
      expect(stored.keys, unorderedEquals(<String>['project-1', 'project-2']));
      expect(jsonEncode(stored), isNot(contains('Record')));
    });

    test('a broken or foreign stored value reads as no filter, newest first', () {
      for (final String stored in <String>[
        'not json',
        '[]',
        '{"project-1": "flat"}',
        '{"project-1": {"filter": 3, "sort": {"key": "colour"}}}',
      ]) {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            projectSettingsStoreOverride(
              SettingsStore.fake(
                stored: <String, Object?>{
                  SettingKeys.recordListCriteria.name: stored,
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        final RecordsListCriteria criteria = container.read(
          recordsListControllerProvider('project-1'),
        );
        expect(criteria.filter, RecordFilter.none, reason: stored);
        expect(criteria.sort, RecordSort.newestFirst, reason: stored);
      }
    });

    test('going back to no filter, newest first, forgets the project', () {
      final SettingsStore settings = SettingsStore.fake();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[projectSettingsStoreOverride(settings)],
      );
      addTearDown(container.dispose);
      final ProviderSubscription<RecordsListCriteria> list = container.listen(
        recordsListControllerProvider('project-1'),
        (RecordsListCriteria? _, RecordsListCriteria _) {},
      );
      addTearDown(list.close);
      final RecordsListController controller = container.read(
        recordsListControllerProvider('project-1').notifier,
      );

      controller.applySort(RecordSort.newestFirst.reversed());
      expect(settings.read(SettingKeys.recordListCriteria), contains('project-1'));

      controller.applySort(RecordSort.newestFirst);
      expect(settings.read(SettingKeys.recordListCriteria), '{}');
    });
  });

  group('layouts', () {
    for (final ({String name, Size size, double scale}) layout
        in <({String name, Size size, double scale})>[
          (name: '393 dp', size: const Size(393, 886), scale: 1),
          (name: '800 dp', size: const Size(800, 1000), scale: 1),
          (name: '1200 dp', size: const Size(1200, 800), scale: 1),
          (name: 'landscape', size: const Size(886, 393), scale: 1),
          (name: '200 percent text', size: const Size(393, 886), scale: 2),
        ]) {
      testWidgets('at ${layout.name} the list shows its rows, chips and '
          'controls without overflowing', (WidgetTester tester) async {
        setSurface(tester, layout.size, scale: layout.scale);
        fake.seedEntry(
          aRecordEntry(
            id: 'long',
            number: 1,
            name: 'A very long record name that cannot fit on one line at all',
            identifier: 'SERIAL-0000000001',
            context: const <String, String>{'site': 'North plant room'},
            status: RecordStatus.needsReview,
          ),
        );
        fake.seedMany(30);
        await pumpRecordsList(tester, records: records);
        controllerOf(tester).applyFilter(
          const RecordFilter(
            statuses: <RecordStatus>{
              RecordStatus.needsReview,
              RecordStatus.captured,
            },
            flags: <RecordFlag>{},
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('records-search')), findsOne);
        expect(find.byKey(const ValueKey<String>('records-sort')), findsOne);
        expect(find.byKey(const ValueKey<String>('records-clear-filters')), findsOne);
        expect(find.byType(AppStatusPill), findsWidgets);
        expect(find.text('Record 30'), findsOneWidget);
      });
    }

    testWidgets('in the narrow pane rows drop their controls and mark the '
        'open record', (WidgetTester tester) async {
      setSurface(tester, const Size(280, 800), scale: 2);
      fake.seedMany(4);
      await pumpRecordsList(tester, records: records);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: listContainer(tester),
          child: MaterialApp(
            home: Scaffold(
              body: RecordsListView(
                projectId: 'project-1',
                pane: true,
                currentRecordId: 'project-1-record-3',
                onOpen: (String _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<AppListTile>(rowOf('project-1-record-3')).current,
        isTrue,
      );
      expect(
        tester.widget<AppListTile>(rowOf('project-1-record-4')).current,
        isFalse,
      );
      expect(tester.widget<AppListTile>(rowOf('project-1-record-4')).dense, isTrue);
      expect(
        find.byKey(const ValueKey<String>('record-edit-project-1-record-4')),
        findsNothing,
      );
    });

    testWidgets('a pane row opens through its callback', (
      WidgetTester tester,
    ) async {
      fake.seedMany(2);
      await pumpRecordsList(tester, records: records);
      final List<String> opened = <String>[];
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: listContainer(tester),
          child: MaterialApp(
            home: Scaffold(
              body: RecordsListView(
                projectId: 'project-1',
                pane: true,
                onOpen: opened.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record 1'));
      await tester.pump();

      expect(opened, <String>['project-1-record-1']);
    });
  });

  testWidgets('rows, chips and controls are named 48 dp targets', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    fake.seedMany(5);
    await pumpRecordsList(tester, records: records);
    controllerOf(tester).applyFilter(
      RecordFilter.forStatus(RecordStatus.captured),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      tester.getSemantics(rowOf('project-1-record-5')),
      isSemantics(
        label: 'Record 5',
        hint: '#5',
        isButton: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    expect(
      find.bySemanticsLabel(
        Copy.recordsSortLabel(Copy.recordsSortNumberDescending),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(Copy.searchFilters(1)), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'ten thousand records scroll top to bottom within the frame budget, '
    'holding no more than a few pages (FE-PERF-01, FE-TEST-09)',
    (WidgetTester tester) async {
      setSurface(tester, const Size(393, 886));
      fake.seedMany(10000);
      await pumpRecordsList(tester, records: records);
      final Finder list = find.byKey(const ValueKey<String>('records-list'));
      final ScrollPosition position = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));

      // Warm up: the first frames of a row compile its code.
      for (int step = 0; step < 3; step++) {
        await tester.drag(list, const Offset(0, -800));
        await tester.pump();
        await tester.pump();
      }
      position.jumpTo(0);
      await tester.pumpAndSettle();
      records.mostLivePages = records.livePages;

      final List<int> frames = <int>[];
      final Stopwatch watch = Stopwatch();
      int steps = 0;
      while (position.pixels < position.maxScrollExtent && steps < 1000) {
        steps++;
        await tester.drag(list, const Offset(0, -2400));
        for (int frame = 0; frame < 2; frame++) {
          watch
            ..reset()
            ..start();
          await tester.pump();
          watch.stop();
          frames.add(watch.elapsedMicroseconds);
        }
      }
      await tester.pumpAndSettle();

      expect(position.pixels, position.maxScrollExtent);
      expect(find.text('Record 1'), findsOneWidget);
      frames.sort();
      final int p90 = frames[(frames.length * 0.9).floor() - 1];
      final int worst = frames.last;
      // ignore: avoid_print
      print(
        'records scroll: ${frames.length} frames over $steps drags, '
        'p50 ${frames[frames.length ~/ 2]} us, p90 $p90 us, worst $worst us, '
        'most pages held ${records.mostLivePages}',
      );
      expect(p90, lessThanOrEqualTo(AppConstants.scrolling.frame.inMicroseconds));
      expect(
        worst,
        lessThanOrEqualTo(AppConstants.scrolling.worstFrame.inMicroseconds),
      );
      expect(
        records.mostLivePages,
        lessThanOrEqualTo(AppConstants.scrolling.livePages),
      );
      for (final ({int offset, int limit}) read in records.pageReads) {
        expect(read.limit, pageSize);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
