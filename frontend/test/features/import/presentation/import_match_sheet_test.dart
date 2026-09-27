import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/import/domain/import_duplicates.dart';
import 'package:tapture/features/import/presentation/import_match_sheet.dart';

void main() {
  testWidgets('a choice can apply to the rest of the run', (
    WidgetTester tester,
  ) async {
    ImportDuplicateChoice? choice;
    bool? applyToAll;
    await tester.pumpWidget(
      MaterialApp(
        home: ImportMatchSheet(
          onChoice: (ImportDuplicateChoice picked, bool all) {
            choice = picked;
            applyToAll = all;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('import-match-keep')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.importApplyToAllConfirm));
    await tester.pumpAndSettle();
    expect(choice, ImportDuplicateChoice.keepExisting);
    expect(applyToAll, isTrue);
  });
}
