import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/presentation/import_screen.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'That file could not be read.',
    recoveryAction: 'Choose another file.',
  );

  testWidgets('each detected kind opens its own flow', (
    WidgetTester tester,
  ) async {
    Future<void> open(ImportKind kind, ImportFlow expected) async {
      ImportFlow? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: ImportScreen(
            kind: kind,
            onOpen: (ImportFlow flow) => chosen = flow,
          ),
        ),
      );
      expect(find.text(Copy.importBundleLine), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey<String>('import-open-${expected.name}')),
      );
      await tester.pump();
      expect(chosen, expected);
    }

    await open(ImportKind.bundle, ImportFlow.bundle);
    await open(ImportKind.spreadsheet, ImportFlow.spreadsheet);
    await open(ImportKind.document, ImportFlow.template);
    await tester.pumpWidget(
      const MaterialApp(home: ImportScreen(kind: ImportKind.image)),
    );
    expect(
      find.byKey(const ValueKey<String>('import-open-refused')),
      findsOneWidget,
    );
  });

  testWidgets('empty, loading and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImportScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ImportScreen(loading: true)),
    );
    expect(find.byType(AppEmptyState), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: ImportScreen(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
