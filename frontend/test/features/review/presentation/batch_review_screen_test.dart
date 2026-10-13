import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/review/review.dart';

import 'review_harness.dart';

const StorageFailure _unreadable = StorageFailure(
  message: 'Records could not be read.',
  recoveryAction: 'Try again.',
);

void main() {
  late ReviewHarness harness;

  setUp(() async {
    harness = ReviewHarness();
    await harness.seedTemplate();
  });

  /// Three records waiting for review, record-3 first (newest).
  void seedThree() {
    for (final String id in <String>['record-1', 'record-2', 'record-3']) {
      harness.seedRecord(id: id);
    }
  }

  Future<void> previous(WidgetTester tester) async {
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.reviewPreviousRecord));
    await tester.pumpAndSettle();
  }

  Future<void> clearSnack(WidgetTester tester) async {
    ScaffoldMessenger.of(
      tester.element(find.byType(BatchReviewScreen)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the queue shows each record with its position, and skip and back walk it',
    (WidgetTester tester) async {
      sizeWindow(tester, const Size(800, 2400));
      seedThree();
      await harness.pump(tester, ReviewHarness.batch);

      expect(find.text(Copy.reviewPosition(1, 3)), findsOneWidget);
      expect(find.text('Serial'), findsOneWidget, reason: 'the real review');
      expect(find.byType(AppOverflowMenu), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('batch-skip')));
      await tester.pumpAndSettle();
      expect(find.text(Copy.reviewPosition(2, 3)), findsOneWidget);

      await previous(tester);
      expect(find.text(Copy.reviewPosition(1, 3)), findsOneWidget);
    },
  );

  testWidgets(
    'an edit made on a record is still there after skipping it and going back',
    (WidgetTester tester) async {
      sizeWindow(tester, const Size(800, 2400));
      seedThree();
      await harness.pump(tester, ReviewHarness.batch);
      final Finder serialRow = find.byKey(
        const ValueKey<String>('review-field-serial'),
      );

      await tester.tap(
        find.descendant(
          of: serialRow,
          matching: find.byKey(const ValueKey<String>('review-verify')),
        ),
      );
      await tester.pumpAndSettle();
      await harness.records.editValues('record-3', const <RecordValueEdit>[
        (fieldKey: 'note', value: 'Typed on the first pass'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('batch-skip')));
      await tester.pumpAndSettle();
      expect(find.text('Typed on the first pass'), findsNothing);

      await previous(tester);
      expect(find.text(Copy.reviewPosition(1, 3)), findsOneWidget);
      // Typed and verified values are settled, so they sit in the group.
      await tester.tap(find.text(Copy.reviewConfidentGroup(3)));
      await tester.pumpAndSettle();
      expect(find.text('Typed on the first pass'), findsOneWidget);
      expect(
        harness.records.entryOf('record-3')!.valueOf('serial')!.verified,
        isTrue,
      );
    },
  );

  testWidgets(
    'approve and next clears the queue in one pass, then says it is finished',
    (WidgetTester tester) async {
      sizeWindow(tester, const Size(800, 2400));
      seedThree();
      await harness.pump(tester, ReviewHarness.batch);

      for (int left = 3; left > 0; left--) {
        expect(find.text(Copy.reviewPosition(1, left)), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('batch-approve')));
        await tester.pumpAndSettle();
        await clearSnack(tester);
      }

      for (final String id in <String>['record-1', 'record-2', 'record-3']) {
        expect(harness.records.entryOf(id)!.status, RecordStatus.approved);
      }
      expect(find.text(Copy.reviewQueueDone), findsOneWidget);
      await tester.tap(find.text(Copy.reviewBackToRecords));
      await tester.pumpAndSettle();
      expect(find.text('records list'), findsOneWidget);
    },
  );

  testWidgets(
    'skipping past the last record ends the queue, and back returns',
    (WidgetTester tester) async {
      sizeWindow(tester, const Size(800, 2400));
      seedThree();
      await harness.pump(tester, ReviewHarness.batch);

      for (int step = 0; step < 3; step++) {
        await tester.tap(find.byKey(const ValueKey<String>('batch-skip')));
        await tester.pumpAndSettle();
      }
      expect(find.text(Copy.reviewQueueDone), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('batch-approve')), findsNothing);

      await previous(tester);
      expect(find.text(Copy.reviewPosition(3, 3)), findsOneWidget);
    },
  );

  testWidgets('an empty queue says so and offers the way back', (
    WidgetTester tester,
  ) async {
    await harness.pump(tester, ReviewHarness.batch);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.reviewQueueEmpty), findsOneWidget);
    expect(find.text(Copy.reviewBackToRecords), findsOneWidget);
  });

  testWidgets('a queue that cannot be read shows the failure', (
    WidgetTester tester,
  ) async {
    seedThree();
    harness.records.readFailure = _unreadable;
    await harness.pump(tester, ReviewHarness.batch);

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_unreadable.message), findsOneWidget);
  });
}
