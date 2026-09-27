import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/records_list_controller.dart';
import 'package:tapture/features/records/presentation/records_sort_menu.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../fakes/fake_record_repository.dart';
import 'records_list_harness.dart';

void main() {
  late FakeRecordRepository fake;
  late CountingRecords records;

  setUp(() {
    fake = FakeRecordRepository();
    records = CountingRecords(fake);
    fake.seedEntry(aRecordEntry(id: 'one', number: 1, name: 'Bravo'));
    fake.seedEntry(aRecordEntry(id: 'two', number: 2, name: 'alpha'));
    fake.seedEntry(aRecordEntry(id: 'three', number: 3, name: 'Charlie'));
  });

  tearDown(() {
    fake.dispose();
  });

  final Finder sortControl = find.byKey(const ValueKey<String>('records-sort'));

  const List<String> labels = <String>[
    Copy.recordsSortNumberDescending,
    Copy.recordsSortNumberAscending,
    Copy.recordsSortCapturedDescending,
    Copy.recordsSortCapturedAscending,
    Copy.recordsSortNameAscending,
    Copy.recordsSortNameDescending,
  ];

  Future<void> openChoice(WidgetTester tester) async {
    await tester.tap(sortControl);
    await tester.pumpAndSettle();
  }

  RecordSort sortOf(WidgetTester tester) {
    return listContainer(
      tester,
    ).read(recordsListControllerProvider('project-1')).sort;
  }

  test('six orders, one per key and direction, each named once', () {
    expect(RecordsSortMenu.orders, hasLength(6));
    expect(RecordsSortMenu.orders.toSet(), hasLength(6));
    expect(RecordsSortMenu.orders.first, RecordSort.newestFirst);
    for (final RecordSortKey key in RecordSortKey.values) {
      expect(
        RecordsSortMenu.orders.where((RecordSort sort) => sort.key == key),
        hasLength(2),
        reason: key.stored,
      );
    }
    expect(RecordsSortMenu.orders.map(RecordsSortMenu.labelOf), labels);
  });

  testWidgets('the control names the current order and is a 48 dp target', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpRecordsList(tester, records: records);

    expect(sortControl, meetsTapTarget());
    expect(
      find.bySemanticsLabel(
        Copy.recordsSortLabel(Copy.recordsSortNumberDescending),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the choice offers the six orders with the current one checked', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpRecordsList(tester, records: records);

    await openChoice(tester);

    expect(find.text(Copy.recordsSortTitle), findsOneWidget);
    final List<double> tops = <double>[
      for (final String label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    expect(tops, List<double>.of(tops)..sort(), reason: 'shown in order');
    for (final String label in labels) {
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(
          isChecked: label == Copy.recordsSortNumberDescending,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
        reason: label,
      );
    }
    semantics.dispose();
  });

  testWidgets('choosing an order applies it, remembers it and closes the '
      'choice', (WidgetTester tester) async {
    final SettingsStore settings = SettingsStore.fake();
    await pumpRecordsList(tester, records: records, settings: settings);
    expect(visibleTitles(tester), <String>['Charlie', 'alpha', 'Bravo']);

    await openChoice(tester);
    await tester.tap(find.text(Copy.recordsSortNameAscending));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsNothing);
    expect(
      sortOf(tester),
      const RecordSort(key: RecordSortKey.name, ascending: true),
    );
    expect(visibleTitles(tester), <String>['alpha', 'Bravo', 'Charlie']);
    final Map<String, Object?> stored =
        jsonDecode(settings.read(SettingKeys.recordListCriteria))
            as Map<String, Object?>;
    expect(stored['project-1'], <String, Object?>{
      'filter': <String, Object?>{},
      'sort': <String, Object?>{'key': 'name', 'ascending': true},
    });
    expect(
      find.bySemanticsLabel(
        Copy.recordsSortLabel(Copy.recordsSortNameAscending),
      ),
      findsOneWidget,
    );
  });

  testWidgets('choosing the current order again changes nothing', (
    WidgetTester tester,
  ) async {
    final SettingsStore settings = SettingsStore.fake();
    await pumpRecordsList(tester, records: records, settings: settings);
    final int reads = records.pageReads.length;

    await openChoice(tester);
    await tester.tap(find.text(Copy.recordsSortNumberDescending));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsNothing);
    expect(sortOf(tester), RecordSort.newestFirst);
    expect(records.pageReads, hasLength(reads));
    expect(settings.read(SettingKeys.recordListCriteria), '{}');
  });

  testWidgets('an order set elsewhere is the one the choice checks', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpRecordsList(tester, records: records);
    listContainer(tester)
        .read(recordsListControllerProvider('project-1').notifier)
        .applySort(
          const RecordSort(key: RecordSortKey.capturedAt, ascending: true),
        );
    await tester.pumpAndSettle();

    await openChoice(tester);

    expect(
      tester.getSemantics(find.text(Copy.recordsSortCapturedAscending)),
      isSemantics(isChecked: true),
    );
    expect(
      tester.getSemantics(find.text(Copy.recordsSortNumberDescending)),
      isSemantics(isChecked: false),
    );
    semantics.dispose();
  });
}
