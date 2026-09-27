import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/exports/presentation/export_history_screen.dart';
import 'package:tapture/features/exports/presentation/export_share_action.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'History could not be read.',
    recoveryAction: 'Try again.',
  );

  testWidgets(
    'a missing file offers a re-run and a present file shares its path',
    (WidgetTester tester) async {
      String? shared;
      String? rerun;
      await tester.pumpWidget(
        MaterialApp(
          home: ExportHistoryScreen(
            entries: const <ExportHistoryRow>[
              (
                id: 'e1',
                folder: '2026-09-28/v1',
                operatorName: 'Ada',
                recordCount: 4,
                path: 'exports/v1/pack.zip',
                missing: true,
              ),
            ],
            onRerun: (String id) => rerun = id,
          ),
        ),
      );
      expect(find.text('Ada · 4'), findsOneWidget);
      expect(find.text(Copy.exportMissing), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('export-rerun')));
      await tester.pump();
      expect(rerun, 'e1');
      await tester.pumpWidget(
        MaterialApp(
          home: ExportShareAction(
            path: 'exports/v1/pack.zip',
            onShare: (String path) => shared = path,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('export-share')));
      await tester.pump();
      expect(shared, 'exports/v1/pack.zip');
    },
  );

  testWidgets('history and share empty and failure states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExportHistoryScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportHistoryScreen(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportShareAction(empty: true)),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: ExportShareAction(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
