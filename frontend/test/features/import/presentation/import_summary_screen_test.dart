import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/import/domain/record_import.dart';
import 'package:tapture/features/import/presentation/import_summary_screen.dart';
import 'package:tapture/features/import/presentation/record_import_controller.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'The summary could not be read.',
    recoveryAction: 'Try again.',
  );
  const RecordImportResult mixed = (
    created: <ImportedRow>[
      (
        row: 2,
        source: 'IMPORTED_TABLE',
        values: <String, String>{},
        existingId: null,
      ),
    ],
    updated: <ImportedRow>[],
    skipped: <RowFailure>[
      (row: 4, reason: 'Kept the existing record.', values: <String, String>{}),
    ],
    failures: <RowFailure>[
      (row: 3, reason: 'Serial is required.', values: <String, String>{}),
    ],
  );

  testWidgets('a failed row offers retry', (WidgetTester tester) async {
    await _pump(tester, _view(result: mixed));
    expect(find.textContaining('3'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('import-retry')), findsOneWidget);
    expect(
      tester.widget<AppPage>(find.byType(AppPage)).layout,
      AppPageLayout.compact,
    );
    expect(
      tester
          .widgetList<AppListTile>(find.byType(AppListTile))
          .every((AppListTile row) => row.wrapText),
      isTrue,
    );
  });

  testWidgets('a clean run does not offer retry', (WidgetTester tester) async {
    await _pump(
      tester,
      _view(
        result: (
          created: mixed.created,
          updated: const <ImportedRow>[],
          skipped: const <RowFailure>[],
          failures: const <RowFailure>[],
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('import-retry')), findsNothing);
  });

  testWidgets('no result is the empty state', (WidgetTester tester) async {
    await _pump(tester, _view());
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('a running import shows its progress', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _view(running: true));
    expect(
      find.byKey(const ValueKey<String>('import-running')),
      findsOneWidget,
    );
  });

  testWidgets('a failed summary stays on the page', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _view(failure: failed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}

RecordImportView _view({
  RecordImportResult? result,
  bool running = false,
  Failure? failure,
}) {
  return (
    templateId: null,
    columnToField: null,
    checking: false,
    running: running,
    done: 0,
    total: 0,
    result: result,
    failure: failure,
  );
}

Future<void> _pump(WidgetTester tester, RecordImportView view) async {
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const ImportSummaryScreen(),
      ),
    ),
  );
  await tester.pump();
  container.read(recordImportControllerProvider.notifier).present(view);
  await tester.pump();
}
