import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/merge/domain/conflict_choice.dart';
import 'package:tapture/features/merge/presentation/conflict_bulk_actions.dart';
import 'package:tapture/features/merge/presentation/merge_history_screen.dart';

void main() {
  const Failure failed = StorageFailure(
    message: 'History could not be read.',
    recoveryAction: 'Try again.',
  );

  testWidgets('history names the source and the undo deadline', (
    WidgetTester tester,
  ) async {
    String? undone;
    await tester.pumpWidget(
      MaterialApp(
        home: MergeHistoryScreen(
          entries: const <MergeHistoryRow>[
            (
              id: 'm1',
              sourceDevice: 'device-b',
              bundleId: 'b1',
              recordCount: 3,
              resolved: 2,
              undoUntil: '1 Oct',
            ),
          ],
          onUndo: (String id) => undone = id,
        ),
      ),
    );
    expect(find.text('device-b'), findsOneWidget);
    expect(find.textContaining('b1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('merge-undo-m1')));
    await tester.pump();
    expect(undone, 'm1');
  });

  testWidgets('empty, loading and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MergeHistoryScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: MergeHistoryScreen(loading: true)),
    );
    expect(find.byType(AppEmptyState), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: MergeHistoryScreen(failure: failed)),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  test('a bulk action is one audit line per conflict', () {
    final List<ConflictAudit> lines = ConflictBulkActions.settle(
      conflictIds: const <String>['c1', 'c2'],
      choice: ConflictChoice.mine,
      chooser: 'Ada',
    );
    expect(lines, hasLength(2));
    expect(lines.map((ConflictAudit line) => line.conflictId), <String>[
      'c1',
      'c2',
    ]);
    expect(lines.every((ConflictAudit line) => line.chooser == 'Ada'), isTrue);
  });
}
