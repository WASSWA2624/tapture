import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/pump_app.dart';

const Failure _failed = StorageFailure(
  message: 'The pairs could not be read.',
  recoveryAction: 'Try again.',
);

const List<DuplicatePairRow> _identity = <DuplicatePairRow>[
  (id: '1', title: 'Pump', subtitle: 'Serial A-1 · A-2', group: 'Identity'),
  (id: '2', title: 'Pump 2', subtitle: 'Serial B-1 · B-2', group: 'Identity'),
];

const DuplicatePairRow _photo = (
  id: '3',
  title: 'Valve',
  subtitle: 'Photo · Photo',
  group: 'Same photo',
);

Finder _pair(String id) => find.byKey(ValueKey<String>('duplicate-pair-$id'));

Finder _groupButton(String group) =>
    find.byKey(ValueKey<String>('duplicate-group-$group'));

Finder get _confirm => find.widgetWithText(AppButton, Copy.duplicateLinkBoth);

void main() {
  testWidgets('an empty list shows the empty state', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const DuplicatesScreen(pairs: <DuplicatePairRow>[]));
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.duplicatesEmptyHeadline), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
  });

  testWidgets('a failure shows the error state with its message', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const DuplicatesScreen(pairs: _identity, failure: _failed),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_failed.message), findsOneWidget);
    expect(_pair('1'), findsNothing);
  });

  testWidgets('pairs are grouped, with the differing fields on each row', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const DuplicatesScreen(pairs: <DuplicatePairRow>[..._identity, _photo]),
    );
    expect(
      tester
          .widgetList<AppSectionHeader>(find.byType(AppSectionHeader))
          .map((AppSectionHeader header) => header.title),
      <String>['Identity', 'Same photo'],
    );
    expect(find.text('Serial A-1 · A-2'), findsOneWidget);
    expect(find.text('Serial B-1 · B-2'), findsOneWidget);
    expect(find.text('Photo · Photo'), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(3));
  });

  testWidgets('a group is cleared pair by pair without opening a record', (
    WidgetTester tester,
  ) async {
    final List<String> resolved = <String>[];
    await pumpApp(
      tester,
      DuplicatesScreen(pairs: _identity, onResolve: resolved.add),
    );
    await tester.tap(_pair('1'));
    await tester.pump();
    expect(resolved, <String>['1']);
    await tester.tap(_pair('2'));
    await tester.pump();
    expect(resolved, <String>['1', '2']);
  });

  testWidgets('a bulk choice names the count and applies once confirmed', (
    WidgetTester tester,
  ) async {
    ({String group, int count})? applied;
    await pumpApp(
      tester,
      DuplicatesScreen(
        pairs: _identity,
        onResolveGroup: (String group, int count) =>
            applied = (group: group, count: count),
      ),
    );
    await tester.tap(_groupButton('Identity'));
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.duplicatesBulkTitle(2, Copy.duplicateLinkBoth)),
      findsOneWidget,
    );
    expect(find.text(Copy.duplicatesBulkMessage(2)), findsOneWidget);
    expect(applied, isNull);
    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(applied, (group: 'Identity', count: 2));
  });

  testWidgets('a bulk choice applies only to the group it was confirmed for', (
    WidgetTester tester,
  ) async {
    final List<({String group, int count})> applied =
        <({String group, int count})>[];
    await pumpApp(
      tester,
      DuplicatesScreen(
        pairs: const <DuplicatePairRow>[..._identity, _photo],
        onResolveGroup: (String group, int count) =>
            applied.add((group: group, count: count)),
      ),
    );
    await tester.tap(_groupButton('Same photo'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.duplicatesBulkMessage(1)), findsOneWidget);
    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(applied, <({String group, int count})>[
      (group: 'Same photo', count: 1),
    ]);
  });

  testWidgets('cancelling the confirmation clears nothing', (
    WidgetTester tester,
  ) async {
    var applied = false;
    await pumpApp(
      tester,
      DuplicatesScreen(
        pairs: _identity,
        onResolveGroup: (String _, int _) => applied = true,
      ),
    );
    await tester.tap(_groupButton('Identity'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, Copy.cancel));
    await tester.pumpAndSettle();
    expect(applied, isFalse);
    expect(_pair('1'), findsOneWidget);
    expect(_pair('2'), findsOneWidget);
  });

  testWidgets('a hundred pairs are cleared with one confirmation', (
    WidgetTester tester,
  ) async {
    final List<DuplicatePairRow> hundred = <DuplicatePairRow>[
      for (int i = 1; i <= 100; i++)
        (
          id: '$i',
          title: 'Pump $i',
          subtitle: 'Serial A-$i · B-$i',
          group: 'Identity',
        ),
    ];
    final List<String> opened = <String>[];
    ({String group, int count})? applied;
    await pumpApp(
      tester,
      DuplicatesScreen(
        pairs: hundred,
        onResolve: opened.add,
        onResolveGroup: (String group, int count) =>
            applied = (group: group, count: count),
      ),
    );
    await tester.ensureVisible(_groupButton('Identity'));
    await tester.pumpAndSettle();
    await tester.tap(_groupButton('Identity'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.duplicatesBulkMessage(100)), findsOneWidget);
    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(applied, (group: 'Identity', count: 100));
    expect(opened, isEmpty);
  });
}
