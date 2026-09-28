import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/pump_app.dart';

const Failure _failed = StorageFailure(
  message: 'The variances could not be read.',
  recoveryAction: 'Try again.',
);

const List<VarianceRow> _rows = <VarianceRow>[
  (
    id: '1',
    fieldKey: 'serial',
    label: 'Serial',
    context: 'North',
    status: VarianceStatus.changed,
    recordId: 'r1',
  ),
  (
    id: '2',
    fieldKey: 'note',
    label: 'Note',
    context: 'North',
    status: VarianceStatus.match,
    recordId: 'r1',
  ),
  (
    id: '3',
    fieldKey: 'custodian',
    label: 'Custodian',
    context: 'South',
    status: VarianceStatus.missing,
    recordId: 'r2',
  ),
  (
    id: '4',
    fieldKey: 'location',
    label: 'Location',
    context: '',
    status: VarianceStatus.changed,
    recordId: 'r3',
  ),
];

Finder _row(String id) => find.byKey(ValueKey<String>('variance-$id'));

Finder _chip(VarianceStatus status) =>
    find.byKey(ValueKey<String>('variance-filter-${status.name}'));

String _statusLabel(VarianceStatus status) => switch (status) {
  VarianceStatus.match => Copy.varianceMatch,
  VarianceStatus.changed => Copy.varianceChanged,
  VarianceStatus.missing => Copy.varianceMissing,
};

void main() {
  testWidgets(
    'rows are grouped by context level with the status readable on the row',
    (WidgetTester tester) async {
      await pumpApp(tester, const VarianceScreen(rows: _rows));
      expect(
        tester
            .widgetList<AppSectionHeader>(find.byType(AppSectionHeader))
            .map((AppSectionHeader header) => header.title),
        <String>['North', 'South', Copy.varianceTitle],
      );
      for (final VarianceRow row in _rows) {
        final AppListTile tile = tester.widget<AppListTile>(_row(row.id));
        expect(tile.title, row.label);
        expect(tile.subtitle, _statusLabel(row.status));
      }
      expect(find.byType(AppListTile), findsNWidgets(4));
    },
  );

  group('each filter shows only its rows and marks its chip', () {
    for (final VarianceStatus status in VarianceStatus.values) {
      testWidgets(status.name, (WidgetTester tester) async {
        await pumpApp(tester, VarianceScreen(rows: _rows, filter: status));
        for (final VarianceRow row in _rows) {
          expect(
            _row(row.id),
            row.status == status ? findsOneWidget : findsNothing,
            reason: 'row ${row.id}',
          );
        }
        for (final VarianceStatus chip in VarianceStatus.values) {
          expect(
            tester.widget<AppChip>(_chip(chip)).selected,
            chip == status,
            reason: chip.name,
          );
        }
      });
    }
  });

  testWidgets('tapping a filter reports it and tapping it again clears it', (
    WidgetTester tester,
  ) async {
    final List<VarianceStatus?> filters = <VarianceStatus?>[];
    await pumpApp(tester, VarianceScreen(rows: _rows, onFilter: filters.add));
    await tester.tap(_chip(VarianceStatus.match));
    await tester.pump();
    expect(filters, <VarianceStatus?>[VarianceStatus.match]);

    await pumpApp(
      tester,
      VarianceScreen(
        rows: _rows,
        filter: VarianceStatus.match,
        onFilter: filters.add,
      ),
    );
    await tester.tap(_chip(VarianceStatus.match));
    await tester.pump();
    expect(filters, <VarianceStatus?>[VarianceStatus.match, null]);
  });

  testWidgets('a record-scoped view shows only that record', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const VarianceScreen(rows: _rows, recordId: 'r1'));
    expect(_row('1'), findsOneWidget);
    expect(_row('2'), findsOneWidget);
    expect(_row('3'), findsNothing);
    expect(_row('4'), findsNothing);
    expect(find.byType(AppSectionHeader), findsOneWidget);
  });

  testWidgets('a record-scoped view still honours the filter', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const VarianceScreen(
        rows: _rows,
        recordId: 'r1',
        filter: VarianceStatus.match,
      ),
    );
    expect(_row('1'), findsNothing);
    expect(_row('2'), findsOneWidget);
  });

  testWidgets('a row opens its record', (WidgetTester tester) async {
    String? opened;
    await pumpApp(
      tester,
      VarianceScreen(rows: _rows, onOpen: (String id) => opened = id),
    );
    await tester.tap(_row('3'));
    await tester.pump();
    expect(opened, 'r2');
  });

  testWidgets('no rows shows the empty state and keeps the filters', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const VarianceScreen(rows: <VarianceRow>[]));
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.varianceEmptyHeadline), findsOneWidget);
    expect(find.byType(AppChip), findsNWidgets(VarianceStatus.values.length));
  });

  testWidgets('a filter with no matching rows shows the empty state', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const VarianceScreen(
        rows: _rows,
        recordId: 'r2',
        filter: VarianceStatus.match,
      ),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
  });

  testWidgets('a failure shows the error state and retry reads again', (
    WidgetTester tester,
  ) async {
    var retried = 0;
    await pumpApp(
      tester,
      VarianceScreen(
        rows: _rows,
        failure: _failed,
        onRetry: () => retried += 1,
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_failed.message), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
    expect(find.byType(AppChip), findsNothing);
    await tester.tap(find.widgetWithText(AppButton, Copy.tryAgain));
    await tester.pump();
    expect(retried, 1);
  });
}
