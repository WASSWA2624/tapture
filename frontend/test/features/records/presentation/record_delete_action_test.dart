import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_delete_action.dart';
import 'package:tapture/features/records/presentation/record_delete_controller.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../fakes/fake_record_repository.dart';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

void main() {
  late FakeRecordRepository records;

  setUp(() {
    records = FakeRecordRepository();
  });

  tearDown(() {
    records.dispose();
  });

  List<String> seed(int count) {
    return <String>[
      for (int n = 1; n <= count; n++)
        records.seedEntry(
          aRecordEntry(id: 'record-$n', status: RecordStatus.needsReview),
        ),
    ];
  }

  /// The recycle bin as the store lists it. Read outside the fake clock: a
  /// stream's cancel completes on the real event loop.
  Future<List<DeletedRecord>> bin(WidgetTester tester) async {
    final List<DeletedRecord>? listed = await tester.runAsync(
      () => records.watchBin().first,
    );
    return listed ?? const <DeletedRecord>[];
  }

  Future<void> pump(
    WidgetTester tester, {
    required Widget child,
    SettingsStore? settings,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          recordRepositoryProvider.overrideWith((Ref _) => records),
          projectSettingsStoreProvider.overrideWith(
            (Ref _) => settings ?? SettingsStore.fake(),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester) async {
    await tester.tap(find.byType(RecordDeleteAction));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.recordsDeleteConfirm),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the confirm', () {
    testWidgets('names the count and how long the records stay restorable', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester, child: RecordDeleteAction(ids: ids));

      await press(tester);

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text(Copy.recordsDeleteTitle(3)), findsOneWidget);
      expect(
        find.text(
          Copy.recordsDeleteMessage(
            records: 3,
            days: AppConstants.retention.days,
          ),
        ),
        findsOneWidget,
      );
      expect(Copy.recordsDeleteTitle(3), contains('3'));
      expect(records.writes, isEmpty);
    });

    testWidgets('names the operator retention window, not the default', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(1);
      await pump(
        tester,
        child: RecordDeleteAction(ids: ids),
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.retentionDays.name: 7},
        ),
      );

      await press(tester);

      expect(find.text(Copy.recordsDeleteTitle(1)), findsOneWidget);
      expect(
        find.text(Copy.recordsDeleteMessage(records: 1, days: 7)),
        findsOneWidget,
      );
    });

    testWidgets('counts a record ticked twice once', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      await pump(
        tester,
        child: RecordDeleteAction(ids: <String>[...ids, ids.first]),
      );

      await press(tester);

      expect(find.text(Copy.recordsDeleteTitle(2)), findsOneWidget);
    });

    testWidgets('cancel deletes nothing and reports nothing', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      RecordDeleteOutcome? reported;
      await pump(
        tester,
        child: RecordDeleteAction(
          ids: ids,
          onDeleted: (RecordDeleteOutcome outcome) => reported = outcome,
        ),
      );

      await press(tester);
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsNothing);
      expect(records.writes, isEmpty);
      for (final String id in ids) {
        expect(records.entryOf(id)?.status, RecordStatus.needsReview);
      }
      expect(find.byType(SnackBar), findsNothing);
      expect(reported, isNull);
    });
  });

  group('a confirmed delete', () {
    testWidgets('moves every record to the bin and offers undo', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      RecordDeleteOutcome? reported;
      await pump(
        tester,
        child: RecordDeleteAction(
          ids: ids,
          onDeleted: (RecordDeleteOutcome outcome) => reported = outcome,
        ),
      );

      await press(tester);
      await confirm(tester);

      for (final String id in ids) {
        expect(records.entryOf(id)?.status, RecordStatus.deleted);
        expect(records.isTombstoned(id), isTrue);
      }
      expect(find.text(Copy.recordsDeleted(3)), findsOneWidget);
      expect(find.text(Copy.undo), findsOneWidget);
      expect(reported?.succeeded, ids);
      expect(reported?.failed, isEmpty);
    });

    testWidgets('undo restores every record to where it was', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      await pump(tester, child: RecordDeleteAction(ids: ids));
      await press(tester);
      await confirm(tester);

      await tester.tap(find.text(Copy.undo));
      await tester.pumpAndSettle();

      for (final String id in ids) {
        expect(records.entryOf(id)?.status, RecordStatus.needsReview);
        expect(records.isTombstoned(id), isFalse);
      }
      expect(await bin(tester), isEmpty);
      expect(find.text(Copy.recordsRestored(3)), findsOneWidget);
    });

    testWidgets('a partial failure deletes the rest and names both counts', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      records.failuresById[ids[1]] = _locked;
      RecordDeleteOutcome? reported;
      await pump(
        tester,
        child: RecordDeleteAction(
          ids: ids,
          onDeleted: (RecordDeleteOutcome outcome) => reported = outcome,
        ),
      );

      await press(tester);
      await confirm(tester);

      expect(records.entryOf(ids[0])?.status, RecordStatus.deleted);
      expect(records.entryOf(ids[1])?.status, RecordStatus.needsReview);
      expect(records.entryOf(ids[2])?.status, RecordStatus.deleted);
      expect(
        find.text(Copy.recordsDeletedPartly(deleted: 2, failed: 1)),
        findsOneWidget,
      );
      expect(reported?.succeeded, <String>[ids[0], ids[2]]);
      expect(reported?.failed, <String, Failure>{ids[1]: _locked});

      await tester.tap(find.text(Copy.undo));
      await tester.pumpAndSettle();

      for (final String id in ids) {
        expect(records.entryOf(id)?.status, RecordStatus.needsReview);
      }
    });

    testWidgets('one record that cannot be deleted says why, with no undo', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(1);
      records.failuresById[ids.single] = _locked;
      await pump(tester, child: RecordDeleteAction(ids: ids));

      await press(tester);
      await confirm(tester);

      expect(records.entryOf(ids.single)?.status, RecordStatus.needsReview);
      expect(find.text(_locked.message), findsOneWidget);
      expect(find.text(Copy.undo), findsNothing);
    });

    testWidgets('several records that cannot be deleted are counted', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(3);
      records.writeFailure = _locked;
      await pump(tester, child: RecordDeleteAction(ids: ids));

      await press(tester);
      await confirm(tester);

      expect(find.text(Copy.recordsNotDeleted(3)), findsOneWidget);
      expect(find.text(Copy.undo), findsNothing);
    });

    testWidgets('an undo that fails says so and leaves the record in the bin', (
      WidgetTester tester,
    ) async {
      final List<String> ids = seed(2);
      await pump(tester, child: RecordDeleteAction(ids: ids));
      await press(tester);
      await confirm(tester);
      records.failuresById[ids.first] = _locked;

      await tester.tap(find.text(Copy.undo));
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordsNotRestored(1)), findsOneWidget);
      expect(records.entryOf(ids.first)?.status, RecordStatus.deleted);
      expect(records.entryOf(ids.last)?.status, RecordStatus.needsReview);
    });
  });

  testWidgets('the snack and its undo outlive the row that was deleted', (
    WidgetTester tester,
  ) async {
    seed(3);
    final Stream<List<RecordSummary>> listed = records.watchPage(
      'project-1',
      filter: RecordFilter.none,
      sort: RecordSort.newestFirst,
      offset: 0,
      limit: AppConstants.lists.pageSize,
    );
    await pump(
      tester,
      child: StreamBuilder<List<RecordSummary>>(
        stream: listed,
        builder: (BuildContext _, AsyncSnapshot<List<RecordSummary>> snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final RecordSummary row
                  in snapshot.data ?? const <RecordSummary>[])
                RecordDeleteAction(
                  key: ValueKey<String>(row.id),
                  ids: <String>[row.id],
                ),
            ],
          );
        },
      ),
    );
    expect(find.byType(RecordDeleteAction), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey<String>('record-2')));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(find.byKey(const ValueKey<String>('record-2')), findsNothing);
    expect(find.byType(RecordDeleteAction), findsNWidgets(2));
    expect(find.text(Copy.recordsDeleted(1)), findsOneWidget);

    await tester.tap(find.text(Copy.undo));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('record-2')), findsOneWidget);
    expect(records.entryOf('record-2')?.status, RecordStatus.needsReview);
  });

  testWidgets('run serves a menu entry and returns what it did', (
    WidgetTester tester,
  ) async {
    final List<String> ids = seed(2);
    final List<RecordDeleteOutcome?> results = <RecordDeleteOutcome?>[];
    await pump(
      tester,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          return TextButton(
            onPressed: () async {
              results.add(await RecordDeleteAction.run(context, ref, ids: ids));
            },
            child: const Text('Menu entry'),
          );
        },
      ),
    );

    await tester.tap(find.text('Menu entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu entry'));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(results, hasLength(2));
    expect(results.first, isNull);
    expect(results.last?.succeeded, ids);
    final List<DeletedRecord> binned = await bin(tester);
    expect(binned.map((DeletedRecord row) => row.reason).toSet(), <String>{
      RecordDeleteController.operatorReason,
    });
  });

  testWidgets('no records disables the control', (WidgetTester tester) async {
    await pump(tester, child: const RecordDeleteAction(ids: <String>[]));

    final AppIconButton button = tester.widget<AppIconButton>(
      find.byType(AppIconButton),
    );
    expect(button.onPressed, isNull);

    await press(tester);
    expect(find.byType(AppDialog), findsNothing);
  });

  testWidgets('the control is a labelled 48dp target naming the count', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final List<String> ids = seed(3);
    await pump(tester, child: RecordDeleteAction(ids: ids));

    final Finder control = find.byType(RecordDeleteAction);
    expect(control, hasSemanticLabel(Copy.recordsDeleteLabel(3)));
    expect(control, meetsTapTarget());
    expect(find.byTooltip(Copy.recordsDeleteLabel(3)), findsOneWidget);
    semantics.dispose();
  });
}
