import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/domain/record_import.dart';
import 'package:tapture/features/import/presentation/import_summary_screen.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The summary could not be read.',
    recoveryAction: 'Try again.',
  );

  testWidgets('retry sends only the failed rows', (WidgetTester tester) async {
    Set<int>? retried;
    await tester.pumpWidget(
      MaterialApp(
        home: ImportSummaryScreen(
          result: (
            created: const <ImportedRow>[
              (
                row: 2,
                source: 'IMPORTED_TABLE',
                values: <String, String>{},
                existingId: null,
              ),
            ],
            updated: const <ImportedRow>[],
            skipped: const <RowFailure>[
              (
                row: 4,
                reason: 'Kept the existing record.',
                values: <String, String>{},
              ),
            ],
            failures: const <RowFailure>[
              (
                row: 3,
                reason: 'Serial is required.',
                values: <String, String>{},
              ),
            ],
          ),
          onRetry: (Set<int> rows) => retried = rows,
        ),
      ),
    );
    expect(find.textContaining('Row 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('import-retry')));
    await tester.pump();
    expect(retried, <int>{3});
  });

  testWidgets('an all-successful result has no retry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ImportSummaryScreen(
          result: (
            created: <ImportedRow>[
              (
                row: 2,
                source: 'IMPORTED_TABLE',
                values: <String, String>{},
                existingId: null,
              ),
            ],
            updated: <ImportedRow>[],
            skipped: <RowFailure>[],
            failures: <RowFailure>[],
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('import-retry')), findsNothing);
  });

  testWidgets('empty, loading and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImportSummaryScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ImportSummaryScreen(loading: true)),
    );
    expect(find.byType(AppEmptyState), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: ImportSummaryScreen(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
