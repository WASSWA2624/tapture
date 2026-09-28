import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/pump_app.dart';

const Failure _failed = StorageFailure(
  message: 'The counts could not be read.',
  recoveryAction: 'Try again.',
);

const QualityCounts _clean = (
  invalid: 0,
  duplicates: 0,
  conflicts: 0,
  unreviewed: 0,
);

void main() {
  testWidgets('a clean project is export-ready and lists no count', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const QualitySummaryScreen(counts: _clean));
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.qualityCleanHeadline), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
  });

  group('each non-zero count is shown and opens the screen that clears it', () {
    const List<({String key, String label, QualityCounts counts, int n})>
    cases = <({String key, String label, QualityCounts counts, int n})>[
      (
        key: 'quality-invalid',
        label: Copy.qualityInvalid,
        counts: (invalid: 3, duplicates: 0, conflicts: 0, unreviewed: 0),
        n: 3,
      ),
      (
        key: 'quality-duplicates',
        label: Copy.qualityDuplicates,
        counts: (invalid: 0, duplicates: 5, conflicts: 0, unreviewed: 0),
        n: 5,
      ),
      (
        key: 'quality-conflicts',
        label: Copy.qualityConflicts,
        counts: (invalid: 0, duplicates: 0, conflicts: 7, unreviewed: 0),
        n: 7,
      ),
      (
        key: 'quality-unreviewed',
        label: Copy.qualityUnreviewed,
        counts: (invalid: 0, duplicates: 0, conflicts: 0, unreviewed: 9),
        n: 9,
      ),
    ];
    for (final ({String key, String label, QualityCounts counts, int n}) c
        in cases) {
      testWidgets('${c.key} lands on its screen', (WidgetTester tester) async {
        String? opened;
        await pumpApp(
          tester,
          QualitySummaryScreen(
            counts: c.counts,
            onInvalid: () => opened = 'quality-invalid',
            onDuplicates: () => opened = 'quality-duplicates',
            onConflicts: () => opened = 'quality-conflicts',
            onUnreviewed: () => opened = 'quality-unreviewed',
          ),
        );
        expect(find.byType(AppEmptyState), findsNothing);
        expect(find.byType(AppListTile), findsOneWidget);
        expect(find.text(c.label), findsOneWidget);
        expect(find.text('${c.n}'), findsOneWidget);
        await tester.tap(find.byKey(ValueKey<String>(c.key)));
        await tester.pump();
        expect(opened, c.key);
      });
    }
  });

  testWidgets('a zero count is not listed beside the non-zero ones', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const QualitySummaryScreen(
        counts: (invalid: 0, duplicates: 2, conflicts: 0, unreviewed: 1),
      ),
    );
    expect(find.byKey(const ValueKey<String>('quality-invalid')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('quality-conflicts')),
      findsNothing,
    );
    expect(find.byType(AppListTile), findsNWidgets(2));
    expect(find.text(Copy.qualityDuplicates), findsOneWidget);
    expect(find.text(Copy.qualityUnreviewed), findsOneWidget);
  });

  testWidgets('a failure shows the error state and retry reads again', (
    WidgetTester tester,
  ) async {
    var retried = 0;
    await pumpApp(
      tester,
      QualitySummaryScreen(
        counts: null,
        failure: _failed,
        onRetry: () => retried += 1,
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_failed.message), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
    await tester.tap(find.widgetWithText(AppButton, Copy.tryAgain));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('counts not yet read show nothing to act on', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const QualitySummaryScreen(counts: null));
    expect(find.text(Copy.qualitySummaryTitle), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
    expect(find.byType(AppEmptyState), findsNothing);
    expect(find.byType(AppErrorState), findsNothing);
  });
}
