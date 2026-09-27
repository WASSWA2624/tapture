import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/records_filter_sheet.dart';
import 'package:tapture/features/records/presentation/records_list_controller.dart';

import '../../../support/factories.dart';
import '../fakes/fake_record_repository.dart';
import 'records_list_harness.dart';

const StorageFailure _unreadable = StorageFailure(
  message: 'The filter choices could not be read.',
  recoveryAction: 'Close the filters and open them again.',
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

  /// Three records that differ on every dimension the sheet offers.
  void seedThree() {
    fake.seedEntry(
      aRecordEntry(
        id: 'alpha',
        number: 1,
        name: 'Alpha',
        status: RecordStatus.needsReview,
        templateId: 'template-1',
        context: const <String, String>{'site': 'North'},
        capturedBy: 'device-ann',
        fields: const <String, String>{'condition': 'Good'},
        photos: 1,
        capturedAt: DateTime.utc(2026, 9, 11, 12),
      ),
    );
    fake.seedEntry(
      aRecordEntry(
        id: 'bravo',
        number: 2,
        name: 'Bravo',
        templateId: 'template-2',
        context: const <String, String>{'site': 'South'},
        capturedBy: 'device-bob',
        fields: const <String, String>{'condition': 'Poor'},
        capturedAt: DateTime.utc(2026, 9, 9, 12),
      ),
    );
    fake.seedEntry(
      aRecordEntry(
        id: 'charlie',
        number: 3,
        name: 'Charlie',
        status: RecordStatus.approved,
        templateId: 'template-1',
        context: const <String, String>{'site': 'South'},
        capturedBy: 'device-bob',
        fields: const <String, String>{'condition': 'Poor'},
        capturedAt: DateTime.utc(2026, 9, 13, 12),
      ),
    );
    fake.seedTemplate('template-1', name: 'Boilers');
    fake.seedTemplate('template-2', name: 'Pumps');
    fake.contextLevelLabels['site'] = 'Site';
    fake.operatorLabels['device-ann'] = 'Ann';
    fake.operatorLabels['device-bob'] = 'Bob';
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('search-filter')));
    await tester.pumpAndSettle();
  }

  /// Closes the sheet on top, as a tap on the scrim above it does.
  Future<void> closeTopSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String field, String option) async {
    final Finder control = find.byKey(ValueKey<String>(field));
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomSheet).last,
        matching: find.text(option),
      ),
    );
    await tester.pumpAndSettle();
    await closeTopSheet(tester);
  }

  Future<void> pickDay(WidgetTester tester, String field, int day) async {
    final Finder control = find.byKey(ValueKey<String>(field));
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  RecordFilter filterOf(WidgetTester tester) {
    return listContainer(
      tester,
    ).read(recordsListControllerProvider('project-1')).filter;
  }

  testWidgets('while the choices load the sheet shows a skeleton', (
    WidgetTester tester,
  ) async {
    seedThree();
    records.holdFacets = true;
    await pumpRecordsList(tester, records: records);

    await openSheet(tester);

    expect(find.text(Copy.recordsFiltersTitle), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.byType(AppSkeleton),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppMultiChoiceField<RecordStatus>), findsNothing);
  });

  testWidgets('a project with no records has nothing to filter yet', (
    WidgetTester tester,
  ) async {
    await pumpRecordsList(tester, records: records);

    await openSheet(tester);

    expect(
      find.byKey(const ValueKey<String>('records-filters-empty')),
      findsOneWidget,
    );
    expect(find.text(Copy.recordsFiltersEmptyHeadline), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('records-filter-from')),
      findsNothing,
    );
  });

  testWidgets('choices that cannot be read say why, and a retry reads them '
      'again', (WidgetTester tester) async {
    seedThree();
    records.facetsFailure = _unreadable;
    await pumpRecordsList(tester, records: records);

    await openSheet(tester);

    expect(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.byType(AppErrorState),
      ),
      findsOneWidget,
    );
    expect(find.text(_unreadable.message), findsOneWidget);
    // The list behind the sheet is still there.
    expect(rowOf('alpha'), findsOneWidget);

    records.facetsFailure = null;
    await tester.tap(find.text(Copy.tryAgain));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('records-filter-status')),
      findsOneWidget,
    );
  });

  testWidgets('the sheet offers every dimension the records carry', (
    WidgetTester tester,
  ) async {
    seedThree();
    await pumpRecordsList(tester, records: records);

    await openSheet(tester);

    for (final String key in <String>[
      'records-filter-status',
      'records-filter-template',
      'records-filter-context-site',
      'records-filter-from',
      'records-filter-to',
      'records-filter-operator',
      'records-filter-condition',
      'records-filter-flags',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget, reason: key);
    }
    expect(
      tester
          .widget<AppMultiChoiceField<String>>(
            find.byKey(const ValueKey<String>('records-filter-context-site')),
          )
          .label,
      'Site',
    );
    expect(
      tester
          .widget<AppMultiChoiceField<RecordFlag>>(
            find.byKey(const ValueKey<String>('records-filter-flags')),
          )
          .options
          .map((Choice<RecordFlag> option) => option.value),
      isNot(contains(RecordFlag.mergedFromBundle)),
    );
  });

  for (final ({
        String name,
        String field,
        String option,
        List<String> listed,
        String chip,
      })
      dimension
      in <
        ({
          String name,
          String field,
          String option,
          List<String> listed,
          String chip,
        })
      >[
        (
          name: 'status',
          field: 'records-filter-status',
          option: Copy.statusNeedsReview,
          listed: <String>['Alpha'],
          chip: 'records-chip-status-needsReview',
        ),
        (
          name: 'template',
          field: 'records-filter-template',
          option: 'Pumps',
          listed: <String>['Bravo'],
          chip: 'records-chip-template-template-2',
        ),
        (
          name: 'context',
          field: 'records-filter-context-site',
          option: 'North',
          listed: <String>['Alpha'],
          chip: 'records-chip-context-site-North',
        ),
        (
          name: 'operator',
          field: 'records-filter-operator',
          option: 'Bob',
          listed: <String>['Charlie', 'Bravo'],
          chip: 'records-chip-operator-device-bob',
        ),
        (
          name: 'condition',
          field: 'records-filter-condition',
          option: 'Poor',
          listed: <String>['Charlie', 'Bravo'],
          chip: 'records-chip-condition-Poor',
        ),
        (
          name: 'quality flag',
          field: 'records-filter-flags',
          option: Copy.recordsFlagHasPhotos,
          listed: <String>['Alpha'],
          chip: 'records-chip-flag-hasPhotos',
        ),
      ]) {
    testWidgets('choosing a ${dimension.name} narrows the list at once', (
      WidgetTester tester,
    ) async {
      seedThree();
      await pumpRecordsList(tester, records: records);
      await openSheet(tester);

      await choose(tester, dimension.field, dimension.option);

      expect(filterOf(tester).activeCount, 1);
      await closeTopSheet(tester);
      expect(find.byType(AppBottomSheet), findsNothing);
      expect(visibleTitles(tester), dimension.listed);
      expect(find.byKey(ValueKey<String>(dimension.chip)), findsOneWidget);
    });
  }

  testWidgets('the capture dates keep whole days from the first to the last', (
    WidgetTester tester,
  ) async {
    seedThree();
    await pumpRecordsList(tester, records: records);
    await openSheet(tester);

    await pickDay(tester, 'records-filter-from', 10);
    await pickDay(tester, 'records-filter-to', 12);

    final RecordFilter filter = filterOf(tester);
    expect(filter.capturedFrom, DateTime(2026, 9, 10).toUtc());
    expect(filter.capturedTo, DateTime(2026, 9, 12, 23, 59, 59, 999).toUtc());
    expect(filter.activeCount, 1);

    await closeTopSheet(tester);
    expect(visibleTitles(tester), <String>['Alpha']);
    expect(
      find.byKey(const ValueKey<String>('records-chip-dates')),
      findsOneWidget,
    );

    // Clearing one bound keeps the other.
    await openSheet(tester);
    await tester.tap(
      find.bySemanticsLabel(Copy.clearField(Copy.recordsFilterFrom)),
    );
    await tester.pumpAndSettle();
    expect(filterOf(tester).capturedFrom, isNull);
    expect(filterOf(tester).capturedTo, isNotNull);
  });

  testWidgets('choices in two dimensions combine, and the sheet shows them', (
    WidgetTester tester,
  ) async {
    seedThree();
    await pumpRecordsList(tester, records: records);
    await openSheet(tester);

    await choose(tester, 'records-filter-template', 'Boilers');
    await choose(tester, 'records-filter-condition', 'Poor');

    expect(filterOf(tester).templateIds, <String>{'template-1'});
    expect(filterOf(tester).conditions, <String>{'Poor'});
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('records-filter-template')),
        matching: find.text('Boilers'),
      ),
      findsOneWidget,
    );

    await closeTopSheet(tester);
    expect(visibleTitles(tester), <String>['Charlie']);
  });

  testWidgets('clear filters in the sheet turns every filter off and closes '
      'it, keeping the search', (WidgetTester tester) async {
    seedThree();
    await pumpRecordsList(tester, records: records);
    final RecordsListController controller = listContainer(
      tester,
    ).read(recordsListControllerProvider('project-1').notifier);
    controller.setSearch('a');
    controller.applyFilter(
      const RecordFilter(
        statuses: <RecordStatus>{RecordStatus.approved},
        conditions: <String>{'Poor'},
      ),
    );
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), <String>['Charlie']);

    await openSheet(tester);
    final Finder clear = find.byKey(
      const ValueKey<String>('filter-sheet-clear'),
    );
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsNothing);
    expect(filterOf(tester).activeCount, 0);
    expect(filterOf(tester).search, 'a');
    expect(visibleTitles(tester), <String>['Charlie', 'Bravo', 'Alpha']);
  });

  testWidgets('show opens the sheet from any control, over the list state', (
    WidgetTester tester,
  ) async {
    seedThree();
    await pumpRecordsList(tester, records: records);
    listContainer(tester)
        .read(recordsListControllerProvider('project-1').notifier)
        .applyFilter(RecordFilter.forStatus(RecordStatus.approved));
    await tester.pumpAndSettle();

    unawaited(
      RecordsFilterSheet.show(
        tester.element(rowOf('charlie')),
        projectId: 'project-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecordsFilterSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('records-filter-status')),
        matching: find.text(Copy.statusApproved),
      ),
      findsOneWidget,
    );
    expect(records.facetReads, 1);
  });
}
