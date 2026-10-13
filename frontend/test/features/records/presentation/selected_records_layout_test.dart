import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/presentation/record_selection.dart';
import 'package:tapture/features/records/presentation/records_list_view.dart';

import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import '../fakes/fake_record_repository.dart';
import 'records_list_harness.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);
  late FakeRecordRepository fake;
  late CountingRecords records;
  setUp(() {
    fake = FakeRecordRepository();
    records = CountingRecords(fake);
  });
  tearDown(() => fake.dispose());
  for (final (Brightness, bool) theme in <(Brightness, bool)>[
    (Brightness.light, false),
    (Brightness.dark, false),
    (Brightness.light, true),
  ]) {
    testWidgets(
      'selected actions fit the bounded compact body with keyboard ${theme.$1.name} ${theme.$2}',
      (WidgetTester tester) async {
        final List<String> ids = fake.seedMany(3);
        await pumpRecordsList(
          tester,
          records: records,
          cell: ScreenMatrix(const Size(393, 320), 2, theme.$1, theme.$2),
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 96);
        addTearDown(tester.view.resetViewInsets);
        listContainer(
          tester,
        ).read(recordSelectionProvider('project-1').notifier).selectAll(ids);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Finder bulk = find.byKey(
          const ValueKey<String>('records-bulk-bar'),
        );
        final Rect list = tester.getRect(find.byType(RecordsListView));
        expect(
          tester.getSize(bulk).height,
          lessThanOrEqualTo(list.height * 0.5),
        );
        for (final String key in <String>[
          'records-bulk-clear',
          'records-bulk-delete',
          'records-bulk-approve',
        ]) {
          final Finder action = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(ScreenProbe.reachabilityIssues(tester, action), isEmpty);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        }
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
    );
  }
}
